/// Automatically takes screenshots for the App Store and Play Store.
import 'dart:io';

import 'package:finale/env.dart';
import 'package:finale/services/generic.dart';
import 'package:finale/services/image_id.dart';
import 'package:finale/services/lastfm/lastfm.dart';
import 'package:finale/services/lastfm/user.dart';
import 'package:finale/util/image_id_cache.dart';
import 'package:finale/util/preferences.dart';
import 'package:finale/util/theme.dart';
import 'package:finale/util/util.dart';
import 'package:finale/views/album_view.dart';
import 'package:finale/views/artist_view.dart';
import 'package:finale/views/main_view.dart';
import 'package:finale/views/scrobble_album_view.dart';
import 'package:finale/views/track_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

const device = String.fromEnvironment('device');
final isIpad = device.contains('iPad');
const directory =
    '/Users/nrubin29/Documents/FlutterProjects/finale/screenshots/$device';

Future<void> main() async {
  await Directory(directory).create();

  setUp(() async {
    SharedPreferences.setMockInitialValues(
        const {'name': testName, 'key': testKey});
    await Preferences().setup();
    await ImageIdCache().setup();
  });

  /// Pumps [widget] inside of a [FinaleTheme]d [MaterialApp] and [Screenshot].
  ///
  /// If [asPage] is true, [widget] will be pushed as a route so that the back
  /// button will be displayed in the top left corner.
  Future<void> pumpWidget(WidgetTester tester, Widget widget,
      {bool asPage = false, Widget? widgetBehindModal}) async {
    await tester.pumpWidget(MaterialApp(
      title: 'Finale',
      theme: FinaleTheme.light,
      darkTheme: FinaleTheme.dark,
      debugShowCheckedModeBanner: false,
      home: asPage || widgetBehindModal != null
          ? _AsPage(widget: widget, widgetBehindModal: widgetBehindModal)
          : widget,
    ));

    if (asPage || widgetBehindModal != null) {
      await tester.settleLong();
    }

    await tester.pumpAndSettle();
  }

  Future<void> saveScreenshot(String name) {
    final element = find.byType(MaterialApp).evaluate().single;

    // BEGIN: Copied from flutter_test/lib/src/_matchers_io.dart:23 because I
    // need to set [pixelRatio].
    assert(element.renderObject != null);
    var renderObject = element.renderObject!;
    while (!renderObject.isRepaintBoundary) {
      renderObject = renderObject.parent! as RenderObject;
    }
    assert(!renderObject.debugNeedsPaint);
    final layer = renderObject.debugLayer! as OffsetLayer;
    final image =
        layer.toImage(renderObject.paintBounds, pixelRatio: isIpad ? 2 : 3);
    // END: Copied code.

    return expectLater(image, matchesGoldenFile('$directory/$name.png'));
  }

  testWidgets('Profile screen', (tester) async {
    await pumpWidget(tester, MainView(username: testName));
    await saveScreenshot('1_profile');
  });

  testWidgets('Scrobble screen', (tester) async {
    await pumpWidget(tester, MainView(username: testName));
    await tester.tap(find.byIcon(scrobbleIcon).at(1));

    final formFields =
        find.byWidgetPredicate((widget) => widget is TextFormField);
    await tester.enterText(formFields.at(0), 'A Lack of Color');
    await tester.enterText(formFields.at(1), 'Death Cab for Cutie');
    await tester.enterText(formFields.at(2), 'Transatlanticism');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await saveScreenshot('2_scrobble');
  });

  testWidgets('Weekly track screen', (tester) async {
    // Cache the images that will be displayed on this screen.
    // TODO: This may or may not be helpful. The real issue is that the weekly
    //  chart entities use [ImageId.scrape].
    final user =
        LUser(testName, null, '', null, 0, LUserRegistered(DateTime.now()));
    final chart = LUserWeeklyChart('1618747200', '1619352000');

    final data = await Future.wait([
      Lastfm.getWeeklyTrackChart(user, chart),
      Lastfm.getWeeklyAlbumChart(user, chart),
      Lastfm.getWeeklyArtistChart(user, chart),
    ]);

    final imageIds = [
      ...await Future.wait(
          (data[0] as LUserWeeklyTrackChart).tracks.map((e) => e.imageId)),
      ...await Future.wait(
          (data[1] as LUserWeeklyAlbumChart).albums.map((e) => e.imageId)),
      ...await Future.wait(
          (data[2] as LUserWeeklyArtistChart).artists.map((e) => e.imageId))
    ];

    await Future.wait(imageIds.map((imageId) => DefaultCacheManager()
        .downloadFile(imageId!.getUrl(ImageQuality.high))));

    await pumpWidget(tester, MainView(username: testName));
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();

    var foundWeek = false;

    do {
      foundWeek = find.text('19 Apr - 25 Apr 2021').evaluate().isNotEmpty;

      if (!foundWeek) {
        await tester.tap(find.byIcon(Icons.chevron_left));
        await tester.pumpAndSettle();
      }
    } while (!foundWeek);

    await tester.settleLong();
    await saveScreenshot('3_weekly_track');
  });

  testWidgets('Track screen', (tester) async {
    final track = await Lastfm.getTrack(BasicConcreteTrack(
        'A Lack of Color', 'Death Cab for Cutie', 'Transatlanticism'));

    // Cache the album image as well.
    final album = await Lastfm.getAlbum(track.album!);
    await DefaultCacheManager()
        .downloadFile(album.imageId!.getUrl(ImageQuality.high));

    // Cache the artist image as well.
    final artist = await Lastfm.getArtist(track.artist!);
    await artist.tryCacheImageId();
    track.artist!.cachedImageId = artist.cachedImageId;
    await DefaultCacheManager()
        .downloadFile(artist.cachedImageId!.getUrl(ImageQuality.high));

    await pumpWidget(tester, TrackView(track: track), asPage: true);
    await saveScreenshot('4_track');
  });

  testWidgets('Artist screen', (tester) async {
    final artist = await Lastfm.getArtist(ConcreteBasicArtist('Mae'));
    await artist.tryCacheImageId();

    await pumpWidget(tester, ArtistView(artist: artist), asPage: true);
    await saveScreenshot('5_artist');
  });

  testWidgets('Album screen', (tester) async {
    final album =
        await Lastfm.getAlbum(FullConcreteAlbum('Deas Vail', 'Deas Vail'));

    // Cache the artist image as well.
    final artist = await Lastfm.getArtist(album.artist);
    await artist.tryCacheImageId();
    album.artist.cachedImageId = artist.cachedImageId;

    await pumpWidget(tester, AlbumView(album: album), asPage: true);
    await saveScreenshot('6_album');
  });

  testWidgets('Album scrobble screen', (tester) async {
    final album =
        await Lastfm.getAlbum(FullConcreteAlbum('Deas Vail', 'Deas Vail'));
    await album.tryCacheImageId();

    await pumpWidget(tester, ScrobbleAlbumView(album: album),
        widgetBehindModal: AlbumView(album: album));
    await saveScreenshot('7_album_scrobble');
  });
}

class _AsPage extends StatefulWidget {
  final Widget widget;
  final Widget? widgetBehindModal;

  const _AsPage({required this.widget, this.widgetBehindModal});

  @override
  State<StatefulWidget> createState() => _AsPageState();
}

class _AsPageState extends State<_AsPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 100), () async {
      if (widget.widgetBehindModal != null) {
        await showBarModalBottomSheet(
            context: context,
            duration: Duration.zero,
            builder: (_) => widget.widget);
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => widget.widget));
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.widgetBehindModal ?? SizedBox();
}

extension on WidgetTester {
  Future<void> settleLong() async {
    await runAsync(() => Future.delayed(const Duration(seconds: 5)));
    try {
      await pumpAndSettle(const Duration(milliseconds: 100),
          EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
    } on FlutterError {
      // [pumpAndSettle] might time out, but that's fine.
    }
  }
}
