import 'package:finale/services/auth.dart';
import 'package:finale/services/lastfm/period.dart';
import 'package:finale/util/preference.dart';
import 'package:finale/util/profile_tab.dart';
import 'package:finale/util/theme.dart';

enum SearchEngine { lastfm, spotify, appleMusic }

class Preferences {
  const Preferences._();

  static final period = Preference<Period, String>(
    'periodValue',
    defaultValue: Period.sevenDays,
    serialize: (value) => value.serializedValue,
    deserialize: Period.deserialized,
  );

  static final name = Preference<String?, String>('name');

  static final key = Preference<String?, String>('key');

  static final spotifyAccessToken =
      Preference<String?, String>('spotifyAccessToken');

  static final spotifyRefreshToken =
      Preference<String?, String>('spotifyRefreshToken');

  static final spotifyExpiration = Preference.dateTime('spotifyExpiration');

  static final spotifyEnabled =
      Preference<bool, bool>('spotifyEnabled', defaultValue: true);

  /// Returns true if Spotify auth data is saved.
  static bool get hasSpotifyAuthData =>
      spotifyAccessToken.hasValue &&
      spotifyRefreshToken.hasValue &&
      spotifyExpiration.hasValue;

  static void clearSpotify() {
    spotifyAccessToken.clear();
    spotifyRefreshToken.clear();
    spotifyExpiration.clear();
  }

  static final stravaAccessToken =
      Preference<String?, String>('stravaAccessToken');

  static final stravaRefreshToken =
      Preference<String?, String>('stravaRefreshToken');

  static final stravaExpiresAt = Preference.dateTime('stravaExpiresAt');

  static bool get hasStravaAuthData =>
      stravaAccessToken.hasValue &&
      stravaRefreshToken.hasValue &&
      stravaExpiresAt.hasValue;

  static TokenResponse? get stravaAuthData => hasStravaAuthData
      ? TokenResponse(stravaAccessToken.value!, stravaExpiresAt.value!,
          stravaRefreshToken.value!)
      : null;

  static set stravaAuthData(TokenResponse? tokenResponse) {
    assert(tokenResponse != null);
    stravaAccessToken.value = tokenResponse!.accessToken;
    stravaExpiresAt.value = tokenResponse.expiresAt;
    stravaRefreshToken.value = tokenResponse.refreshToken;
  }

  static void clearStravaAuthData() {
    stravaAccessToken.clear();
    stravaExpiresAt.clear();
    stravaRefreshToken.clear();
  }

  static final libreKey = Preference<String?, String>('libreKey');

  static final libreEnabled =
      Preference<bool, bool>('libreEnabled', defaultValue: false);

  static void clearLibre() {
    libreEnabled.value = false;
    libreKey.value = null;
  }

  static final searchEngine = Preference.forEnum<SearchEngine>(
    'searchEngine',
    SearchEngine.values,
    defaultValue: SearchEngine.lastfm,
  );

  static final stripTags =
      Preference<bool, bool>('stripTags', defaultValue: false);

  static final listenMoreFrequently =
      Preference<bool, bool>('listenMoreFrequently', defaultValue: false);

  static final themeColor = Preference.forEnum<ThemeColor>(
    'themeColorIndex',
    ThemeColor.values,
    defaultValue: ThemeColor.red,
  );

  static final appleMusicEnabled =
      Preference<bool, bool>('isAppleMusicEnabled', defaultValue: true);

  static final appleMusicBackgroundScrobblingEnabled = Preference<bool, bool>(
      'isAppleMusicBackgroundScrobblingEnabled',
      defaultValue: true);

  static final lastAppleMusicScrobble =
      Preference.dateTime('lastAppleMusicScrobble');

  static final showAlbumArtistField =
      Preference<bool, bool>('showAlbumArtistField', defaultValue: true);

  static final inputDateTimeAsText =
      Preference<bool, bool>('inputDateTimeAsText', defaultValue: false);

  static final profileTabsOrder = Preference<List<ProfileTab>, List<String>>(
    'profileTabsOrder',
    defaultValue: ProfileTab.values,
    serialize: (value) =>
        value.map((e) => e.index.toString()).toList(growable: false),
    deserialize: (serialized) => serialized
        .map((item) => ProfileTab.values[int.parse(item)])
        .toList(growable: false),
  );
}
