#include "FFmpegBridge.h"

#include <libavformat/avformat.h>
#include <libavformat/avio.h>
#include <libavcodec/avcodec.h>
#include <libavutil/samplefmt.h>
#include <libavutil/opt.h>
#include <libavutil/mem.h>
#include <libavutil/error.h>
#include <libavutil/channel_layout.h>
#include <math.h>
#include <stdlib.h>
#include <libavutil/channel_layout.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

#ifndef av_err2str
#define av_err2str(errnum) av_make_error_string((char[AV_ERROR_MAX_STRING_SIZE]){0}, AV_ERROR_MAX_STRING_SIZE, errnum)
#endif

//struct FFDecoderHandle {
//    AVFormatContext *format;
//    AVCodecContext *codec;
//    AVStream *stream;
//    AVPacket *packet;
//    AVFrame *frame;
//    uint8_t *interleavedBuffer;
//    size_t interleavedSize;
//    size_t bufferedBytes;
//    size_t bufferedOffset;
//    int sampleRate;
//    int channels;
//    int bitDepth;
//    int durationMs;
//    size_t bytesPerSample;
//    size_t bytesPerFrame;
//    enum AVSampleFormat sampleFormat;
//    int eofReached;
//};

static char gFFDecoderLastError[512] = {0};

static void ffdecoder_copy_metadata_string(FFDecoderHandle *handle,
                                           const char *key,
                                           char *dest,
                                           size_t destSize) {
    if (!dest || destSize == 0 || !handle) { return; }
    dest[0] = '\0';
    AVDictionaryEntry *entry = NULL;
    if (handle->stream) {
        entry = av_dict_get(handle->stream->metadata, key, NULL, AV_DICT_IGNORE_SUFFIX);
    }
    if (!entry && handle->format) {
        entry = av_dict_get(handle->format->metadata, key, NULL, AV_DICT_IGNORE_SUFFIX);
    }
    if (entry && entry->value) {
        snprintf(dest, destSize, "%s", entry->value);
    }
}

static double ffdecoder_metadata_double(FFDecoderHandle *handle, const char *key) {
    if (!handle) { return NAN; }
    AVDictionaryEntry *entry = NULL;
    if (handle->stream) {
        entry = av_dict_get(handle->stream->metadata, key, NULL, AV_DICT_IGNORE_SUFFIX);
    }
    if (!entry && handle->format) {
        entry = av_dict_get(handle->format->metadata, key, NULL, AV_DICT_IGNORE_SUFFIX);
    }
    if (!entry || !entry->value) {
        return NAN;
    }
    char *endptr = NULL;
    double value = strtod(entry->value, &endptr);
    if (endptr == entry->value) {
        return NAN;
    }
    return value;
}

static void ffdecoder_set_error(const char *message) {
    if (!message) {
        gFFDecoderLastError[0] = '\0';
        return;
    }
    snprintf(gFFDecoderLastError, sizeof(gFFDecoderLastError), "%s", message);
}

const char *ffdecoder_last_error(void) {
    return gFFDecoderLastError;
}

static int ffdecoder_is_pcm_codec(enum AVCodecID codecId) {
    switch (codecId) {
        case AV_CODEC_ID_PCM_S16LE:
        case AV_CODEC_ID_PCM_S16BE:
        case AV_CODEC_ID_PCM_S24LE:
        case AV_CODEC_ID_PCM_S24BE:
        case AV_CODEC_ID_PCM_S32LE:
        case AV_CODEC_ID_PCM_S32BE:
        case AV_CODEC_ID_PCM_F32LE:
        case AV_CODEC_ID_PCM_F32BE:
        case AV_CODEC_ID_PCM_F64LE:
        case AV_CODEC_ID_PCM_F64BE:
        case AV_CODEC_ID_PCM_U8:
        case AV_CODEC_ID_PCM_U16LE:
        case AV_CODEC_ID_PCM_U16BE:
        case AV_CODEC_ID_PCM_U24LE:
        case AV_CODEC_ID_PCM_U24BE:
        case AV_CODEC_ID_PCM_U32LE:
        case AV_CODEC_ID_PCM_U32BE:
        case AV_CODEC_ID_PCM_S16LE_PLANAR:
        case AV_CODEC_ID_PCM_S32LE_PLANAR:
        case AV_CODEC_ID_PCM_S24LE_PLANAR:
        case AV_CODEC_ID_PCM_S16BE_PLANAR:
            return 1;
        default:
            return 0;
    }
}

static enum AVSampleFormat ffdecoder_pcm_sample_fmt(enum AVCodecID codecId) {
    switch (codecId) {
        case AV_CODEC_ID_PCM_S16LE:
        case AV_CODEC_ID_PCM_S16BE:
        case AV_CODEC_ID_PCM_S16LE_PLANAR:
        case AV_CODEC_ID_PCM_S16BE_PLANAR:
            return AV_SAMPLE_FMT_S16;
        case AV_CODEC_ID_PCM_S24LE:
        case AV_CODEC_ID_PCM_S24BE:
        case AV_CODEC_ID_PCM_S24LE_PLANAR:
        case AV_CODEC_ID_PCM_U24LE:
        case AV_CODEC_ID_PCM_U24BE:
            return AV_SAMPLE_FMT_S32;
        case AV_CODEC_ID_PCM_S32LE:
        case AV_CODEC_ID_PCM_S32BE:
        case AV_CODEC_ID_PCM_S32LE_PLANAR:
        case AV_CODEC_ID_PCM_U32LE:
        case AV_CODEC_ID_PCM_U32BE:
            return AV_SAMPLE_FMT_S32;
        case AV_CODEC_ID_PCM_F32LE:
        case AV_CODEC_ID_PCM_F32BE:
            return AV_SAMPLE_FMT_FLT;
        case AV_CODEC_ID_PCM_F64LE:
        case AV_CODEC_ID_PCM_F64BE:
            return AV_SAMPLE_FMT_DBL;
        case AV_CODEC_ID_PCM_U8:
            return AV_SAMPLE_FMT_U8;
        case AV_CODEC_ID_PCM_U16LE:
        case AV_CODEC_ID_PCM_U16BE:
            return AV_SAMPLE_FMT_S16;
        default:
            return AV_SAMPLE_FMT_NONE;
    }
}

static int ffdecoder_prepare_decoder(FFDecoderHandle *handle, const char *path) {
    int result = avformat_open_input(&handle->format, path, NULL, NULL);
    if (result < 0) {
        ffdecoder_set_error(av_err2str(result));
        return result;
    }
    result = avformat_find_stream_info(handle->format, NULL);
    if (result < 0) {
        ffdecoder_set_error(av_err2str(result));
        return result;
    }
    int streamIndex = av_find_best_stream(handle->format, AVMEDIA_TYPE_AUDIO, -1, -1, NULL, 0);
    if (streamIndex < 0) {
        ffdecoder_set_error("No audio stream");
        return -1;
    }
    handle->stream = handle->format->streams[streamIndex];
    AVCodecParameters *codecpar = handle->stream->codecpar;
    const AVCodec *codec = avcodec_find_decoder(codecpar->codec_id);
    handle->packet = av_packet_alloc();
    if (!handle->packet) {
        ffdecoder_set_error("Failed to allocate packet");
        return AVERROR(ENOMEM);
    }
    handle->isPassthrough = 0;

    if (codec) {
        handle->codec = avcodec_alloc_context3(codec);
        if (!handle->codec) {
            ffdecoder_set_error("Failed to alloc codec context");
            return AVERROR(ENOMEM);
        }
        result = avcodec_parameters_to_context(handle->codec, codecpar);
        if (result < 0) {
            ffdecoder_set_error(av_err2str(result));
            return result;
        }
        result = avcodec_open2(handle->codec, codec, NULL);
        if (result < 0) {
            ffdecoder_set_error(av_err2str(result));
            return result;
        }
        handle->frame = av_frame_alloc();
        if (!handle->frame) {
            ffdecoder_set_error("Failed to allocate frame");
            return AVERROR(ENOMEM);
        }
        handle->sampleFormat = handle->codec->sample_fmt;
        handle->bytesPerSample = av_get_bytes_per_sample(handle->sampleFormat);
        if (handle->bytesPerSample == 0) {
            ffdecoder_set_error("Unsupported sample format");
            return AVERROR(EINVAL);
        }
        handle->channels = handle->codec->channels;
        handle->sampleRate = handle->codec->sample_rate;
        handle->bitDepth = handle->codec->bits_per_raw_sample;
        if (handle->bitDepth <= 0 || handle->bitDepth < (int)(handle->bytesPerSample * 8)) {
            handle->bitDepth = (int)(handle->bytesPerSample * 8);
        }
        handle->bytesPerFrame = handle->bytesPerSample * handle->channels;
    } else if (ffdecoder_is_pcm_codec(codecpar->codec_id)) {
        // Passthrough for builds without PCM decoders: packets already contain PCM data
        handle->isPassthrough = 1;
        handle->codec = NULL;
        handle->frame = NULL;
        handle->sampleFormat = ffdecoder_pcm_sample_fmt(codecpar->codec_id);
        if (handle->sampleFormat == AV_SAMPLE_FMT_NONE) {
            ffdecoder_set_error("Unsupported PCM format");
            return AVERROR(EINVAL);
        }
        handle->bytesPerSample = av_get_bytes_per_sample(handle->sampleFormat);
        if (handle->bytesPerSample == 0) {
            ffdecoder_set_error("Unsupported PCM sample format");
            return AVERROR(EINVAL);
        }
        handle->channels = codecpar->channels;
        handle->sampleRate = codecpar->sample_rate;
        handle->bitDepth = codecpar->bits_per_coded_sample;
        if (handle->bitDepth <= 0 || handle->bitDepth < (int)(handle->bytesPerSample * 8)) {
            handle->bitDepth = (int)(handle->bytesPerSample * 8);
        }
        handle->bytesPerFrame = handle->bytesPerSample * handle->channels;
    } else {
        ffdecoder_set_error("Decoder unavailable");
        return -1;
    }
    handle->durationMs = 0;
    if (handle->stream->duration > 0) {
        double seconds = handle->stream->duration * av_q2d(handle->stream->time_base);
        handle->durationMs = (int)(seconds * 1000.0);
    } else if (handle->format->duration > 0) {
        handle->durationMs = (int)(handle->format->duration / (AV_TIME_BASE / 1000));
    }
    const char *codecLongName = codec && codec->long_name ? codec->long_name : NULL;
    const char *codecShortName = codec && codec->name ? codec->name : NULL;
    const char *codecLabel = codecLongName ? codecLongName : codecShortName;
    if (codecLabel) {
        snprintf(handle->codecName, sizeof(handle->codecName), "%s", codecLabel);
    } else if (handle->isPassthrough) {
        snprintf(handle->codecName, sizeof(handle->codecName), "PCM Passthrough");
    } else {
        handle->codecName[0] = '\0';
    }

    if (handle->format && handle->format->iformat) {
        const char *containerLong = handle->format->iformat->long_name;
        const char *containerShort = handle->format->iformat->name;
        const char *containerLabel = containerLong ? containerLong : containerShort;
        if (containerLabel) {
            snprintf(handle->containerName, sizeof(handle->containerName), "%s", containerLabel);
        }
    }

    if (codecpar->bit_rate > 0) {
        handle->sourceBitRate = codecpar->bit_rate;
    } else if (handle->format && handle->format->bit_rate > 0) {
        handle->sourceBitRate = handle->format->bit_rate;
    } else {
        handle->sourceBitRate = 0;
    }

    if (codecpar->channel_layout != 0) {
        handle->channelLayout = codecpar->channel_layout;
    } else {
        handle->channelLayout = av_get_default_channel_layout(handle->channels);
    }

    const char *sampleFmtName = av_get_sample_fmt_name(handle->sampleFormat);
    if (sampleFmtName) {
        snprintf(handle->sampleFormatName, sizeof(handle->sampleFormatName), "%s", sampleFmtName);
    } else if (handle->isPassthrough) {
        snprintf(handle->sampleFormatName, sizeof(handle->sampleFormatName), "pcm");
    } else {
        handle->sampleFormatName[0] = '\0';
    }

    handle->startTimeSeconds = 0.0;
    if (handle->format && handle->format->start_time != AV_NOPTS_VALUE) {
        handle->startTimeSeconds = (double)handle->format->start_time / AV_TIME_BASE;
    }

    handle->fileSizeBytes = 0;
    if (handle->format && handle->format->pb && (handle->format->pb->seekable & AVIO_SEEKABLE_NORMAL)) {
        int64_t size = avio_size(handle->format->pb);
        if (size > 0) {
            handle->fileSizeBytes = size;
        }
    }
    if (handle->fileSizeBytes == 0 && handle->durationMs > 0 && handle->sourceBitRate > 0) {
        double seconds = handle->durationMs / 1000.0;
        double bytes = (handle->sourceBitRate / 8.0) * seconds;
        if (bytes > 0) {
            handle->fileSizeBytes = (int64_t)bytes;
        }
    }

    ffdecoder_copy_metadata_string(handle, "title", handle->title, sizeof(handle->title));
    ffdecoder_copy_metadata_string(handle, "artist", handle->artist, sizeof(handle->artist));
    ffdecoder_copy_metadata_string(handle, "album", handle->album, sizeof(handle->album));
    ffdecoder_copy_metadata_string(handle, "album_artist", handle->albumArtist, sizeof(handle->albumArtist));
    ffdecoder_copy_metadata_string(handle, "genre", handle->genre, sizeof(handle->genre));
    ffdecoder_copy_metadata_string(handle, "comment", handle->comment, sizeof(handle->comment));
    ffdecoder_copy_metadata_string(handle, "date", handle->date, sizeof(handle->date));
    ffdecoder_copy_metadata_string(handle, "track", handle->trackNumber, sizeof(handle->trackNumber));
    ffdecoder_copy_metadata_string(handle, "disc", handle->discNumber, sizeof(handle->discNumber));

    handle->replayGainTrack = ffdecoder_metadata_double(handle, "REPLAYGAIN_TRACK_GAIN");
    handle->replayGainAlbum = ffdecoder_metadata_double(handle, "REPLAYGAIN_ALBUM_GAIN");
    handle->replayPeakTrack = ffdecoder_metadata_double(handle, "REPLAYGAIN_TRACK_PEAK");
    handle->replayPeakAlbum = ffdecoder_metadata_double(handle, "REPLAYGAIN_ALBUM_PEAK");
    handle->r128TrackGain = ffdecoder_metadata_double(handle, "R128_TRACK_GAIN");
    handle->r128AlbumGain = ffdecoder_metadata_double(handle, "R128_ALBUM_GAIN");

    handle->interleavedSize = handle->bytesPerFrame * 2048;
    handle->interleavedBuffer = (uint8_t *)av_malloc(handle->interleavedSize);
    if (!handle->interleavedBuffer) {
        ffdecoder_set_error("Failed to allocate decode buffer");
        return AVERROR(ENOMEM);
    }
    handle->bufferedBytes = 0;
    handle->bufferedOffset = 0;
    handle->eofReached = 0;
    return 0;
}

FFDecoderHandle *ffdecoder_open(const char *path) {
    if (!path) {
        ffdecoder_set_error("Path is null");
        return NULL;
    }
    av_log_set_level(AV_LOG_ERROR);
    struct FFDecoderHandle *handle = av_mallocz(sizeof(struct FFDecoderHandle));
    if (!handle) {
        ffdecoder_set_error("Allocation failure");
        return NULL;
    }
    if (ffdecoder_prepare_decoder(handle, path) < 0) {
        ffdecoder_close(handle);
        return NULL;
    }
    ffdecoder_set_error(NULL);
    return handle;
}

void ffdecoder_close(FFDecoderHandle *handle) {
    if (!handle) return;
    if (handle->packet) {
        av_packet_free(&handle->packet);
    }
    if (handle->frame) {
        av_frame_free(&handle->frame);
    }
    if (handle->codec) {
        avcodec_free_context(&handle->codec);
    }
    if (handle->format) {
        avformat_close_input(&handle->format);
    }
    if (handle->interleavedBuffer) {
        av_free(handle->interleavedBuffer);
    }
    av_free(handle);
}

int ffdecoder_get_sample_rate(FFDecoderHandle *handle) {
    return handle ? handle->sampleRate : 0;
}

int ffdecoder_get_channels(FFDecoderHandle *handle) {
    return handle ? handle->channels : 0;
}

int ffdecoder_get_bit_depth(FFDecoderHandle *handle) {
    return handle ? handle->bitDepth : 0;
}

int ffdecoder_get_duration_ms(FFDecoderHandle *handle) {
    return handle ? handle->durationMs : 0;
}

int ffdecoder_get_bytes_per_frame(FFDecoderHandle *handle) {
    return handle ? handle->bytesPerFrame : 0;
}

FFDecSampleFormat ffdecoder_get_sample_format(FFDecoderHandle *handle) {
    if (!handle) return FFDEC_SAMPLE_FMT_UNKNOWN;
    switch (handle->sampleFormat) {
        case AV_SAMPLE_FMT_S16:
        case AV_SAMPLE_FMT_S16P:
            return FFDEC_SAMPLE_FMT_S16;
        case AV_SAMPLE_FMT_S32:
        case AV_SAMPLE_FMT_S32P:
            return FFDEC_SAMPLE_FMT_S32;
        case AV_SAMPLE_FMT_FLT:
        case AV_SAMPLE_FMT_FLTP:
            return FFDEC_SAMPLE_FMT_FLOAT;
        case AV_SAMPLE_FMT_DBL:
        case AV_SAMPLE_FMT_DBLP:
            return FFDEC_SAMPLE_FMT_DOUBLE;
        default:
            return FFDEC_SAMPLE_FMT_UNKNOWN;
    }
}

const char *ffdecoder_get_codec_name(FFDecoderHandle *handle) {
    return handle ? handle->codecName : NULL;
}

const char *ffdecoder_get_container_name(FFDecoderHandle *handle) {
    return handle ? handle->containerName : NULL;
}

int64_t ffdecoder_get_bit_rate(FFDecoderHandle *handle) {
    return handle ? handle->sourceBitRate : 0;
}

uint64_t ffdecoder_get_channel_layout(FFDecoderHandle *handle) {
    return handle ? handle->channelLayout : 0;
}

const char *ffdecoder_get_sample_format_name(FFDecoderHandle *handle) {
    if (!handle || handle->sampleFormatName[0] == '\0') { return NULL; }
    return handle->sampleFormatName;
}

int64_t ffdecoder_get_file_size_bytes(FFDecoderHandle *handle) {
    return handle ? handle->fileSizeBytes : 0;
}

double ffdecoder_get_start_time_seconds(FFDecoderHandle *handle) {
    return handle ? handle->startTimeSeconds : 0.0;
}

const char *ffdecoder_get_tag_title(FFDecoderHandle *handle) {
    if (!handle || handle->title[0] == '\0') { return NULL; }
    return handle->title;
}

const char *ffdecoder_get_tag_artist(FFDecoderHandle *handle) {
    if (!handle || handle->artist[0] == '\0') { return NULL; }
    return handle->artist;
}

const char *ffdecoder_get_tag_album(FFDecoderHandle *handle) {
    if (!handle || handle->album[0] == '\0') { return NULL; }
    return handle->album;
}

const char *ffdecoder_get_tag_album_artist(FFDecoderHandle *handle) {
    if (!handle || handle->albumArtist[0] == '\0') { return NULL; }
    return handle->albumArtist;
}

const char *ffdecoder_get_tag_genre(FFDecoderHandle *handle) {
    if (!handle || handle->genre[0] == '\0') { return NULL; }
    return handle->genre;
}

const char *ffdecoder_get_tag_comment(FFDecoderHandle *handle) {
    if (!handle || handle->comment[0] == '\0') { return NULL; }
    return handle->comment;
}

const char *ffdecoder_get_tag_date(FFDecoderHandle *handle) {
    if (!handle || handle->date[0] == '\0') { return NULL; }
    return handle->date;
}

const char *ffdecoder_get_tag_track(FFDecoderHandle *handle) {
    if (!handle || handle->trackNumber[0] == '\0') { return NULL; }
    return handle->trackNumber;
}

const char *ffdecoder_get_tag_disc(FFDecoderHandle *handle) {
    if (!handle || handle->discNumber[0] == '\0') { return NULL; }
    return handle->discNumber;
}

static double ffdecoder_return_double(double value) {
    return value;
}

double ffdecoder_get_replaygain_track_gain(FFDecoderHandle *handle) {
    return handle ? ffdecoder_return_double(handle->replayGainTrack) : NAN;
}

double ffdecoder_get_replaygain_album_gain(FFDecoderHandle *handle) {
    return handle ? ffdecoder_return_double(handle->replayGainAlbum) : NAN;
}

double ffdecoder_get_replaygain_track_peak(FFDecoderHandle *handle) {
    return handle ? ffdecoder_return_double(handle->replayPeakTrack) : NAN;
}

double ffdecoder_get_replaygain_album_peak(FFDecoderHandle *handle) {
    return handle ? ffdecoder_return_double(handle->replayPeakAlbum) : NAN;
}

double ffdecoder_get_r128_track_gain(FFDecoderHandle *handle) {
    return handle ? ffdecoder_return_double(handle->r128TrackGain) : NAN;
}

double ffdecoder_get_r128_album_gain(FFDecoderHandle *handle) {
    return handle ? ffdecoder_return_double(handle->r128AlbumGain) : NAN;
}

static int ffdecoder_fill_buffer(struct FFDecoderHandle *handle) {
    handle->bufferedBytes = 0;
    handle->bufferedOffset = 0;
    int ret;
    while (1) {
        if (handle->isPassthrough) {
            while (1) {
                ret = av_read_frame(handle->format, handle->packet);
                if (ret == AVERROR_EOF) {
                    handle->eofReached = 1;
                    return 0;
                }
                if (ret < 0) {
                    ffdecoder_set_error(av_err2str(ret));
                    return ret;
                }
                if (handle->packet->stream_index != handle->stream->index) {
                    av_packet_unref(handle->packet);
                    continue;
                }
                size_t required = (size_t)handle->packet->size;
                if (required > handle->interleavedSize) {
                    uint8_t *newBuffer = av_realloc(handle->interleavedBuffer, required);
                    if (!newBuffer) {
                        ffdecoder_set_error("Failed to grow buffer");
                        av_packet_unref(handle->packet);
                        return AVERROR(ENOMEM);
                    }
                    handle->interleavedBuffer = newBuffer;
                    handle->interleavedSize = required;
                }
                memcpy(handle->interleavedBuffer, handle->packet->data, required);
                av_packet_unref(handle->packet);
                handle->bufferedBytes = required;
                return (int)required;
            }
        }
        ret = avcodec_receive_frame(handle->codec, handle->frame);
        if (ret == 0) {
            int planar = av_sample_fmt_is_planar(handle->sampleFormat);
            int samples = handle->frame->nb_samples;
            size_t required = (size_t)samples * handle->bytesPerFrame;
            if (required > handle->interleavedSize) {
                uint8_t *newBuffer = av_realloc(handle->interleavedBuffer, required);
                if (!newBuffer) {
                    ffdecoder_set_error("Failed to grow buffer");
                    return AVERROR(ENOMEM);
                }
                handle->interleavedBuffer = newBuffer;
                handle->interleavedSize = required;
            }
            if (!planar) {
                memcpy(handle->interleavedBuffer, handle->frame->data[0], required);
            } else {
                for (int sample = 0; sample < samples; ++sample) {
                    for (int ch = 0; ch < handle->channels; ++ch) {
                        uint8_t *dst = handle->interleavedBuffer + (sample * handle->channels + ch) * handle->bytesPerSample;
                        uint8_t *src = handle->frame->data[ch] + sample * handle->bytesPerSample;
                        memcpy(dst, src, handle->bytesPerSample);
                    }
                }
            }
            handle->bufferedBytes = required;
            av_frame_unref(handle->frame);
            return (int)required;
        } else if (ret == AVERROR(EAGAIN)) {
            while (1) {
                ret = av_read_frame(handle->format, handle->packet);
                if (ret == AVERROR_EOF) {
                    handle->eofReached = 1;
                    avcodec_send_packet(handle->codec, NULL);
                    break;
                }
                if (ret < 0) {
                    ffdecoder_set_error(av_err2str(ret));
                    return ret;
                }
                if (handle->packet->stream_index == handle->stream->index) {
                    int sendResult = avcodec_send_packet(handle->codec, handle->packet);
                    av_packet_unref(handle->packet);
                    if (sendResult < 0) {
                        ffdecoder_set_error(av_err2str(sendResult));
                        return sendResult;
                    }
                    break;
                } else {
                    av_packet_unref(handle->packet);
                }
            }
            continue;
        } else if (ret == AVERROR_EOF) {
            return 0;
        } else {
            ffdecoder_set_error(av_err2str(ret));
            return ret;
        }
    }
}

ssize_t ffdecoder_read(FFDecoderHandle *handle, uint8_t *buffer, size_t maxBytes) {
    if (!handle || !buffer || maxBytes == 0) {
        return 0;
    }
    size_t written = 0;
    while (written < maxBytes) {
        if (handle->bufferedOffset < handle->bufferedBytes) {
            size_t available = handle->bufferedBytes - handle->bufferedOffset;
            size_t toCopy = (available < (maxBytes - written)) ? available : (maxBytes - written);
            memcpy(buffer + written, handle->interleavedBuffer + handle->bufferedOffset, toCopy);
            handle->bufferedOffset += toCopy;
            written += toCopy;
        } else {
            int filled = ffdecoder_fill_buffer(handle);
            if (filled <= 0) {
                break;
            }
        }
    }
    return (ssize_t)written;
}

int ffdecoder_seek_ms(FFDecoderHandle *handle, int64_t positionMs) {
    if (!handle || positionMs < 0) {
        return AVERROR(EINVAL);
    }
    int64_t target = (int64_t)((positionMs / 1000.0) / av_q2d(handle->stream->time_base));
    int flags = AVSEEK_FLAG_BACKWARD;
    int result = av_seek_frame(handle->format, handle->stream->index, target, flags);
    if (result < 0) {
        ffdecoder_set_error(av_err2str(result));
        return result;
    }
    if (handle->codec) {
        avcodec_flush_buffers(handle->codec);
    }
    handle->bufferedBytes = 0;
    handle->bufferedOffset = 0;
    handle->eofReached = 0;
    return 0;
}
