import 'package:opentool_dart/opentool_client.dart';

OpenTool buildAppToolSpecification() => _AppToolSchemaBuilder.build();

class _AppToolSchemaBuilder {
  static OpenTool build() {
    final songSummary = songSummarySchema();
    final trackList = trackListSchema(songSummary);
    final playlistSummary = playlistSummarySchema();
    final functions = <FunctionModel>[
      FunctionModel(
        name: 'getPlayback',
        description:
            'Return current playback status including progress and active track',
        parameters: const [],
        return_: Return(
          name: 'playback',
          description: 'Playback snapshot consumed by the agent',
          schema: playbackInfoSchema(),
        ),
      ),
      FunctionModel(
        name: 'getCurrentPlaylist',
        description:
            'Return the active queue; optional limit trims the number of tracks',
        parameters: [
          Parameter(
            name: 'limit',
            schema: Schema(
              type: SchemaType.INTEGER,
              description: 'Optional maximum number of records to return',
            ),
            required: false,
          ),
        ],
        return_: Return(
          name: 'playlist',
          description: 'Current queue rendered as a playlist detail object',
          schema: playlistDetailSchema(trackList),
        ),
      ),
      FunctionModel(
        name: 'getPlaylistSummaries',
        description: 'List every playlist with its track count',
        parameters: const [],
        return_: Return(
          name: 'playlists',
          description: 'Overview of existing playlists',
          schema: playlistSummaryListSchema(playlistSummary),
        ),
      ),
      FunctionModel(
        name: 'getPlaylistDetail',
        description: 'Return tracks inside a named playlist; limit is optional',
        parameters: [
          Parameter(
            name: 'name',
            schema: Schema(
              type: SchemaType.STRING,
              description: 'Playlist name',
            ),
            required: true,
          ),
          Parameter(
            name: 'limit',
            schema: Schema(
              type: SchemaType.INTEGER,
              description: 'Optional maximum number of records to return',
            ),
            required: false,
          ),
        ],
        return_: Return(
          name: 'playlist',
          description:
              'Playlist detail or a result string when the playlist is missing',
          schema: playlistDetailOrMessageSchema(trackList),
        ),
      ),
      FunctionModel(
        name: 'getLibraryTracks',
        description:
            'Return library tracks; support pagination and a lightweight search filter',
        parameters: [
          Parameter(
            name: 'limit',
            schema: Schema(
              type: SchemaType.INTEGER,
              description: 'Optional maximum number of records to return',
            ),
            required: false,
          ),
          Parameter(
            name: 'offset',
            schema: Schema(
              type: SchemaType.INTEGER,
              description: 'Optional number of records to skip',
            ),
            required: false,
          ),
          Parameter(
            name: 'filter',
            schema: Schema(
              type: SchemaType.STRING,
              description:
                  'Optional case-insensitive substring filter applied to title/artist/album before pagination',
            ),
            required: false,
          ),
        ],
        return_: Return(
          name: 'library',
          description: 'Library slice with total count and song list',
          schema: librarySummarySchema(trackList),
        ),
      ),
      FunctionModel(
        name: 'getFavoriteTracks',
        description:
            'Return favorite songs; optional limit keeps replies short',
        parameters: [
          Parameter(
            name: 'limit',
            schema: Schema(
              type: SchemaType.INTEGER,
              description: 'Optional maximum number of records to return',
            ),
            required: false,
          ),
        ],
        return_: Return(
          name: 'favorites',
          description: 'Favorite songs with total count',
          schema: favoritesSummarySchema(songSummary),
        ),
      ),
      FunctionModel(
        name: 'getSongMetadata',
        description: 'Return metadata for a single track identified by path',
        parameters: [
          Parameter(
            name: 'path',
            schema: Schema(
              type: SchemaType.STRING,
              description: 'Absolute path or unique identifier for the song',
            ),
            required: true,
          ),
        ],
        return_: Return(
          name: 'metadata',
          description: 'Detailed metadata for a song',
          schema: songMetadataInfoSchema(),
        ),
      ),
      FunctionModel(
        name: 'getForYouPlaylist',
        description: 'Return the current "For You" playlist; limit is optional',
        parameters: [
          Parameter(
            name: 'limit',
            schema: Schema(
              type: SchemaType.INTEGER,
              description: 'Optional maximum number of records to return',
            ),
            required: false,
          ),
        ],
        return_: Return(
          name: 'forYou',
          description: 'Current AI recommendation list',
          schema: forYouPlaylistSchema(trackList),
        ),
      ),
      FunctionModel(
        name: 'setForYouPlaylist',
        description:
            'Replace the "For You" playlist with the supplied tracks and note',
        parameters: [
          Parameter(
            name: 'tracks',
            schema: trackList,
            required: true,
          ),
          Parameter(
            name: 'note',
            schema: Schema(
              type: SchemaType.STRING,
              description: 'Optional hint or note for the recommendations',
            ),
            required: false,
          ),
        ],
        return_: Return(
          name: 'result',
          description: 'Result string describing the operation outcome',
          schema: resultStringSchema(),
        ),
      ),
      FunctionModel(
        name: 'setCurrentPlaylist',
        description:
            'Overwrite the current playback queue without auto-playing',
        parameters: [
          Parameter(
            name: 'tracks',
            schema: trackList,
            required: true,
          ),
        ],
        return_: Return(
          name: 'result',
          description: 'Result string describing the operation outcome',
          schema: resultStringSchema(),
        ),
      ),
      FunctionModel(
        name: 'createPlaylist',
        description: 'Create a playlist and persist the provided tracks',
        parameters: [
          Parameter(
            name: 'name',
            schema: Schema(
              type: SchemaType.STRING,
              description: 'Playlist name',
            ),
            required: true,
          ),
          Parameter(
            name: 'tracks',
            schema: trackList,
            required: true,
          ),
        ],
        return_: Return(
          name: 'result',
          description: 'Result string describing the operation outcome',
          schema: resultStringSchema(),
        ),
      ),
      FunctionModel(
        name: 'addSongToCurrentAndPlay',
        description:
            'Append a song to the queue and start playback immediately',
        parameters: [
          Parameter(
            name: 'song',
            schema: songSummary,
            required: true,
          ),
        ],
        return_: Return(
          name: 'result',
          description: 'Result string describing the operation outcome',
          schema: resultStringSchema(),
        ),
      ),
      FunctionModel(
        name: 'getMoodSignals',
        description:
            'Collect host context such as battery, theme, and network hints',
        parameters: const [],
        return_: Return(
          name: 'signals',
          description: 'Snapshot of contextual signals for the agent',
          schema: moodSignalsSchema(),
        ),
      ),
    ];

    return OpenTool(
      opentool: '2.1.0',
      info: Info(
        title: 'ToneyAppTool',
        version: '0.1.0',
        description:
            'Expose playback, playlist, and library methods for the Toney app',
      ),
      functions: functions,
    );
  }

  static Schema playlistSummarySchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Minimal playlist overview',
      properties: {
        'name': Schema(type: SchemaType.STRING, description: 'Playlist name'),
        'trackCount': Schema(
          type: SchemaType.INTEGER,
          description: 'Number of tracks in the playlist',
        ),
      },
      required: const ['name', 'trackCount'],
    );
  }

  static Schema playlistSummaryListSchema(Schema summarySchema) {
    return Schema(
      type: SchemaType.OBJECT,
      properties: {
        'playlists': Schema(
          type: SchemaType.ARRAY,
          description: 'List of playlist summaries',
          items: summarySchema,
        ),
      },
      required: const ['playlists'],
    );
  }

  static Schema songSummarySchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description:
          'Compact song summary used across playback and playlist APIs',
      properties: {
        'id': Schema(
          type: SchemaType.STRING,
          description: 'Unique identifier or absolute path',
        ),
        'title': Schema(type: SchemaType.STRING, description: 'Song title'),
        'artist': Schema(
          type: SchemaType.STRING,
          description: 'Artist (optional)',
        ),
        'album': Schema(
          type: SchemaType.STRING,
          description: 'Album (optional)',
        ),
        'durationSec': Schema(
          type: SchemaType.INTEGER,
          description: 'Duration in seconds (optional)',
        ),
        'format': Schema(
          type: SchemaType.STRING,
          description: 'Container/codec hint (optional)',
        ),
        'source': Schema(
          type: SchemaType.STRING,
          description: 'Source label (optional)',
        ),
      },
      required: const ['id', 'title'],
    );
  }

  static Schema trackListSchema(Schema summarySchema) {
    return Schema(
      type: SchemaType.ARRAY,
      description:
          'List of songs with minimal metadata for queue or playlist operations',
      items: summarySchema,
    );
  }

  static Schema playlistDetailSchema(Schema trackListSchema) {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Detailed playlist representation',
      properties: {
        'name': Schema(type: SchemaType.STRING, description: 'Playlist name'),
        'tracks': trackListSchema,
      },
      required: const ['name', 'tracks'],
    );
  }

  static Schema playlistDetailOrMessageSchema(Schema trackListSchema) {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Playlist detail or a result message when missing',
      properties: {
        'name': Schema(type: SchemaType.STRING, description: 'Playlist name'),
        'tracks': trackListSchema,
        'result': Schema(
          type: SchemaType.STRING,
          description: 'Optional status string such as playlist_not_found',
        ),
      },
    );
  }

  static Schema librarySummarySchema(Schema trackListSchema) {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Library response with total count and tracks',
      properties: {
        'total': Schema(
          type: SchemaType.INTEGER,
          description: 'Total number of tracks in the library',
        ),
        'tracks': trackListSchema,
      },
      required: const ['total', 'tracks'],
    );
  }

  static Schema favoritesSummarySchema(Schema songSummarySchema) {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Favorite songs payload',
      properties: {
        'total': Schema(
          type: SchemaType.INTEGER,
          description: 'Total favorites count',
        ),
        'favorites': Schema(
          type: SchemaType.ARRAY,
          description: 'Favorite songs',
          items: songSummarySchema,
        ),
      },
      required: const ['total', 'favorites'],
    );
  }

  static Schema songMetadataInfoSchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Detailed metadata for a song',
      properties: {
        'path': Schema(type: SchemaType.STRING, description: 'Song path'),
        'title': Schema(type: SchemaType.STRING, description: 'Song title'),
        'artist': Schema(type: SchemaType.STRING, description: 'Artist'),
        'album': Schema(type: SchemaType.STRING, description: 'Album'),
        'durationSec': Schema(
          type: SchemaType.INTEGER,
          description: 'Duration in seconds (optional)',
        ),
        'extras': Schema(
          type: SchemaType.OBJECT,
          description: 'Additional metadata key/value pairs',
        ),
      },
      required: const ['path', 'title'],
    );
  }

  static Schema forYouPlaylistSchema(Schema trackListSchema) {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'AI recommendation playlist payload',
      properties: {
        'tracks': trackListSchema,
        'note': Schema(
          type: SchemaType.STRING,
          description: 'Optional hint or note for the recommendations',
        ),
      },
      required: const ['tracks'],
    );
  }

  static Schema moodSignalsSchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Contextual device signals collected natively',
      properties: {
        'hour': Schema(
          type: SchemaType.INTEGER,
          description: 'Local hour in 24h format',
        ),
        'weekday': Schema(
          type: SchemaType.INTEGER,
          description: 'Weekday number as provided by the OS calendar',
        ),
        'isHoliday': Schema(
          type: SchemaType.BOOLEAN,
          description: 'Whether the current day is considered a holiday',
        ),
        'appearance': Schema(
          type: SchemaType.STRING,
          description: 'Either light or dark per system preference',
        ),
        'batteryLevel': Schema(
          type: SchemaType.NUMBER,
          description: 'Battery level between 0 and 1',
        ),
        'isCharging': Schema(
          type: SchemaType.BOOLEAN,
          description: 'True when the device is charging',
        ),
        'isNetworkConnected': Schema(
          type: SchemaType.BOOLEAN,
          description: 'True when any network path is available',
        ),
        'networkType': Schema(
          type: SchemaType.STRING,
          description: 'wifi/cellular/ethernet/offline/unknown',
        ),
        'networkQuality': Schema(
          type: SchemaType.STRING,
          description: 'good/average/poor/unknown',
        ),
        'headphonesConnected': Schema(
          type: SchemaType.BOOLEAN,
          description: 'True when wired/bluetooth headphones are connected',
        ),
      },
      required: const [
        'hour',
        'weekday',
        'isHoliday',
        'appearance',
        'batteryLevel',
        'isCharging',
        'isNetworkConnected',
        'networkType',
        'networkQuality',
        'headphonesConnected',
      ],
    );
  }

  static Schema resultStringSchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Encodes a concise operation result string',
      properties: {
        'result': Schema(
          type: SchemaType.STRING,
          description: 'Machine friendly result string',
        ),
      },
      required: const ['result'],
    );
  }

  static Schema queueItemSchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Item inside the playback queue',
      properties: {
        'title': Schema(type: SchemaType.STRING, description: 'Song title'),
        'artist': Schema(type: SchemaType.STRING, description: 'Artist'),
        'url': Schema(type: SchemaType.STRING, description: 'Source path'),
      },
      required: const ['title', 'url'],
    );
  }

  static Schema trackMetadataSchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Engine track metadata snapshot',
      properties: {
        'url': Schema(type: SchemaType.STRING, description: 'Track URL'),
        'title': Schema(type: SchemaType.STRING, description: 'Title'),
        'artist': Schema(type: SchemaType.STRING, description: 'Artist'),
        'album': Schema(type: SchemaType.STRING, description: 'Album'),
        'tags': Schema(
          type: SchemaType.ARRAY,
          description: 'Optional tag list',
          items: Schema(type: SchemaType.STRING),
        ),
        'container': Schema(
          type: SchemaType.STRING,
          description: 'Container format',
        ),
        'codec': Schema(type: SchemaType.STRING, description: 'Codec name'),
        'bitrateKbps': Schema(
          type: SchemaType.INTEGER,
          description: 'Bitrate in kbps',
        ),
        'sampleFormat': Schema(
          type: SchemaType.STRING,
          description: 'Sample format label',
        ),
        'channelLayout': Schema(
          type: SchemaType.STRING,
          description: 'Channel layout label',
        ),
        'duration': Schema(
          type: SchemaType.INTEGER,
          description: 'Duration in milliseconds',
        ),
      },
      required: const ['url', 'container', 'codec', 'duration'],
    );
  }

  static Schema playbackInfoSchema() {
    return Schema(
      type: SchemaType.OBJECT,
      description: 'Playback state snapshot',
      properties: {
        'isPlaying': Schema(
          type: SchemaType.BOOLEAN,
          description: 'Whether playback is active',
        ),
        'isBusy': Schema(
          type: SchemaType.BOOLEAN,
          description: 'Whether the engine is busy',
        ),
        'position': Schema(
          type: SchemaType.INTEGER,
          description: 'Position in milliseconds',
        ),
        'duration': Schema(
          type: SchemaType.INTEGER,
          description: 'Duration in milliseconds',
        ),
        'currentIndex': Schema(
          type: SchemaType.INTEGER,
          description: 'Current queue index',
        ),
        'queue': Schema(
          type: SchemaType.ARRAY,
          description: 'Trimmed queue snapshot',
          items: queueItemSchema(),
        ),
        'currentTrack': trackMetadataSchema(),
        'statusMessage': Schema(
          type: SchemaType.STRING,
          description: 'Latest status or error message',
        ),
      },
      required: const [
        'isPlaying',
        'isBusy',
        'position',
        'duration',
        'currentIndex',
        'queue',
      ],
    );
  }
}
