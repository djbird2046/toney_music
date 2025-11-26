#ifndef FFMPEG_BRIDGE_H
#define FFMPEG_BRIDGE_H

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>

#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
#include <libavutil/samplefmt.h>
#include <libavutil/opt.h>
#include <libavutil/mem.h>
#include <libavutil/error.h>
#include <libavutil/channel_layout.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    FFDEC_SAMPLE_FMT_UNKNOWN = 0,
    FFDEC_SAMPLE_FMT_S16,
    FFDEC_SAMPLE_FMT_S32,
    FFDEC_SAMPLE_FMT_FLOAT,
    FFDEC_SAMPLE_FMT_DOUBLE
} FFDecSampleFormat;

struct FFDecoderHandle {
    AVFormatContext *format;
    AVCodecContext *codec;
    AVStream *stream;
    AVPacket *packet;
    AVFrame *frame;
    uint8_t *interleavedBuffer;
    size_t interleavedSize;
    size_t bufferedBytes;
    size_t bufferedOffset;
    int sampleRate;
    int channels;
    int bitDepth;
    int durationMs;
    size_t bytesPerSample;
    size_t bytesPerFrame;
    enum AVSampleFormat sampleFormat;
    int eofReached;
    char codecName[128];
    char containerName[128];
    int64_t sourceBitRate;
    uint64_t channelLayout;
    char sampleFormatName[64];
    int64_t fileSizeBytes;
    double startTimeSeconds;

    char title[256];
    char artist[256];
    char album[256];
    char albumArtist[256];
    char genre[128];
    char comment[512];
    char date[64];
    char trackNumber[64];
    char discNumber[64];

    double replayGainTrack;
    double replayGainAlbum;
    double replayPeakTrack;
    double replayPeakAlbum;
    double r128TrackGain;
    double r128AlbumGain;
};

typedef struct FFDecoderHandle FFDecoderHandle;

FFDecoderHandle *ffdecoder_open(const char *path);
const char *ffdecoder_last_error(void);
int ffdecoder_get_sample_rate(FFDecoderHandle *h);
int ffdecoder_get_channels(FFDecoderHandle *h);
int ffdecoder_get_bit_depth(FFDecoderHandle *h);
int ffdecoder_get_duration_ms(FFDecoderHandle *h);
int ffdecoder_get_bytes_per_frame(FFDecoderHandle *h);
FFDecSampleFormat ffdecoder_get_sample_format(FFDecoderHandle *h);
const char *ffdecoder_get_codec_name(FFDecoderHandle *h);
const char *ffdecoder_get_container_name(FFDecoderHandle *h);
int64_t ffdecoder_get_bit_rate(FFDecoderHandle *h);
uint64_t ffdecoder_get_channel_layout(FFDecoderHandle *h);
const char *ffdecoder_get_sample_format_name(FFDecoderHandle *h);
int64_t ffdecoder_get_file_size_bytes(FFDecoderHandle *h);
double ffdecoder_get_start_time_seconds(FFDecoderHandle *h);
const char *ffdecoder_get_tag_title(FFDecoderHandle *h);
const char *ffdecoder_get_tag_artist(FFDecoderHandle *h);
const char *ffdecoder_get_tag_album(FFDecoderHandle *h);
const char *ffdecoder_get_tag_album_artist(FFDecoderHandle *h);
const char *ffdecoder_get_tag_genre(FFDecoderHandle *h);
const char *ffdecoder_get_tag_comment(FFDecoderHandle *h);
const char *ffdecoder_get_tag_date(FFDecoderHandle *h);
const char *ffdecoder_get_tag_track(FFDecoderHandle *h);
const char *ffdecoder_get_tag_disc(FFDecoderHandle *h);
double ffdecoder_get_replaygain_track_gain(FFDecoderHandle *h);
double ffdecoder_get_replaygain_album_gain(FFDecoderHandle *h);
double ffdecoder_get_replaygain_track_peak(FFDecoderHandle *h);
double ffdecoder_get_replaygain_album_peak(FFDecoderHandle *h);
double ffdecoder_get_r128_track_gain(FFDecoderHandle *h);
double ffdecoder_get_r128_album_gain(FFDecoderHandle *h);
ssize_t ffdecoder_read(FFDecoderHandle *h, uint8_t *buffer, size_t maxBytes);
int ffdecoder_seek_ms(FFDecoderHandle *h, int64_t);
void ffdecoder_close(FFDecoderHandle *h);

#ifdef __cplusplus
}
#endif

#endif /* FFMPEG_BRIDGE_H */
