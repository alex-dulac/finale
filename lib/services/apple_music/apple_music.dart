import 'package:finale/services/apple_music/played_song.dart';
import 'package:finale/services/apple_music/playlist.dart';
import 'package:finale/services/generic.dart';
import 'package:finale/services/lastfm/lastfm.dart';
import 'package:finale/util/preferences.dart';
import 'package:flutter_mpmediaplayer/flutter_mpmediaplayer.dart';

export 'package:flutter_mpmediaplayer/flutter_mpmediaplayer.dart'
    show AuthorizationStatus;

class AMSearchPlaylistsRequest extends PagedRequest<AMPlaylist> {
  final String query;

  const AMSearchPlaylistsRequest(this.query);

  @override
  Future<List<AMPlaylist>> doRequest(int limit, int page) async =>
      (await FlutterMPMediaPlayer.searchPlaylists(query))
          .map(AMPlaylist.new)
          .toList(growable: false);
}

class AppleMusic {
  const AppleMusic._();

  static Future<AuthorizationStatus> authorize() =>
      FlutterMPMediaPlayer.authorize();

  static Future<AuthorizationStatus> get authorizationStatus =>
      FlutterMPMediaPlayer.authorizationStatus;

  static Future<List<AMPlayedSong>> getRecentTracks() async {
    var after = DateTime.now().subtract(const Duration(days: 14));
    final last = Preferences().lastAppleMusicScrobble;
    if (last != null && last.isAfter(after)) {
      after = last;
    }

    return (await FlutterMPMediaPlayer.getRecentTracks(after: after))
        .map(AMPlayedSong.new)
        .toList(growable: false);
  }

  static Future<bool> scrobble(List<AMPlayedSong> songs) async {
    final now = DateTime.now();
    final response = await Lastfm.scrobble(
        songs, songs.map((track) => track.date).toList(growable: false));
    final success = response.ignored == 0;

    if (success) {
      Preferences().lastAppleMusicScrobble = now;
    }

    return success;
  }
}
