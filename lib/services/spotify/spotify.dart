import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:finale/env.dart';
import 'package:finale/services/generic.dart';
import 'package:finale/services/spotify/auth.dart';
import 'package:finale/services/spotify/common.dart';
import 'package:finale/services/spotify/track.dart';
import 'package:shared_preferences/shared_preferences.dart';

Uri _buildUri(String method, Map<String, dynamic> data) => Uri.https(
    'api.spotify.com',
    'v1/$method',
    data.map((key, value) => MapEntry(key, value.toString())));

Future<Map<String, dynamic>> _doRequest(
    String method, Map<String, dynamic> data) async {
  final sharedPreferences = await SharedPreferences.getInstance();

  if (!(await Spotify.isLoggedIn)) {
    final refreshToken = sharedPreferences.getString('spotifyRefreshToken');
    await Spotify.refreshAccessToken(refreshToken);
  }

  final accessToken = sharedPreferences.getString('spotifyAccessToken');

  final uri = _buildUri(method, data);

  final response = await httpClient
      .get(uri, headers: {'Authorization': 'Bearer $accessToken'});

  if (response.statusCode == 200) {
    return json.decode(utf8.decode(response.bodyBytes));
  } else if (response.statusCode == 400) {
    final error = SError.fromJson(json.decode(utf8.decode(response.bodyBytes)));
    throw SException(error.message, error.status);
  } else {
    throw Exception('Could not do request $method');
  }
}

class SSearchTracksRequest extends PagedRequest<STrack> {
  String query;

  SSearchTracksRequest(this.query);

  @override
  Future<List<STrack>> doRequest(int limit, int page) async {
    final rawResponse = await _doRequest('search', {
      'q': query,
      'type': 'track',
      'limit': limit,
      'offset': (page - 1) * limit
    });
    return SPage<STrack>.fromJson(rawResponse['tracks']).items;
  }
}

class PkcePair {
  static const _alphabet =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';

  final String _codeVerifier;
  final String _codeChallenge;

  const PkcePair._(this._codeVerifier, this._codeChallenge);

  factory PkcePair.generate() {
    final random = Random.secure();
    final verifier = List.generate(
        128, (index) => _alphabet[random.nextInt(_alphabet.length)]).join();
    var challenge =
        base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes);

    while (challenge.endsWith('=')) {
      challenge = challenge.substring(0, challenge.length - 1);
    }

    return PkcePair._(verifier, challenge);
  }

  String get codeVerifier => _codeVerifier;
  String get codeChallenge => _codeChallenge;
}

class Spotify {
  static const _redirectUri = 'finale://spotify';

  static Uri createAuthorizationUri(PkcePair pkcePair) =>
      Uri.https('accounts.spotify.com', 'authorize', {
        'client_id': spotifyClientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': pkcePair.codeChallenge,
      });

  static Future<void> _callTokenEndpoint(Map<String, dynamic> body) async {
    final rawResponse = await httpClient.post(
      Uri.https('accounts.spotify.com', 'api/token'),
      body: body,
    );
    final response =
        SpotifyTokenResponse.fromJson(json.decode(rawResponse.body));
    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString('spotifyAccessToken', response.accessToken);
    sharedPreferences.setString('spotifyRefreshToken', response.refreshToken);
    sharedPreferences.setInt(
        'spotifyExpiration',
        DateTime.now()
            .add(Duration(seconds: response.expiresIn))
            .millisecondsSinceEpoch);
  }

  static Future<void> getAccessToken(String code, PkcePair pkcePair) =>
      _callTokenEndpoint({
        'client_id': spotifyClientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': pkcePair.codeVerifier,
      });

  static Future<void> refreshAccessToken(String refreshToken) =>
      _callTokenEndpoint({
        'client_id': spotifyClientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      });

  static Future<bool> get isLoggedIn async {
    final sharedPreferences = await SharedPreferences.getInstance();

    if (!sharedPreferences.containsKey('spotifyAccessToken') ||
        !sharedPreferences.containsKey('spotifyRefreshToken') ||
        !sharedPreferences.containsKey('spotifyExpiration')) {
      return false;
    }

    final expiration = DateTime.fromMillisecondsSinceEpoch(
        sharedPreferences.getInt('spotifyExpiration'));
    return DateTime.now().isBefore(expiration);
  }
}

class SException implements Exception {
  final String message;
  final int status;

  const SException(this.message, this.status);
}
