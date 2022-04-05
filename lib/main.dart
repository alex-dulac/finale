import 'package:finale/util/apple_music_scrobble_background_task.dart';
import 'package:finale/util/constants.dart';
import 'package:finale/util/image_id_cache.dart';
import 'package:finale/util/preference.dart';
import 'package:finale/util/preferences.dart';
import 'package:finale/util/quick_actions_manager.dart';
import 'package:finale/util/theme.dart';
import 'package:finale/widgets/entity/lastfm/profile_stack.dart';
import 'package:finale/widgets/main/login_view.dart';
import 'package:finale/widgets/main/main_view.dart';
import 'package:flutter/material.dart';
import 'package:universal_io/io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preference.setup();

  if (isMobile) {
    await QuickActionsManager().setup();
  }

  if (!isWeb) {
    await ImageIdCache().setup();
  }

  if (Platform.isIOS) {
    await AppleMusicScrobbleBackgroundTask.setup();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp();

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeColor _themeColor;

  @override
  void initState() {
    super.initState();

    Preferences.themeColor.changes.listen((value) {
      setState(() {
        _themeColor = value;
      });
    });

    _themeColor = Preferences.themeColor.value;
  }

  @override
  Widget build(BuildContext context) {
    final name = Preferences.name.value;
    return ProfileStack(
      child: MaterialApp(
        title: 'Finale',
        theme: FinaleTheme.lightFor(_themeColor),
        darkTheme: FinaleTheme.darkFor(_themeColor),
        home: name == null ? LoginView() : MainView(username: name),
      ),
    );
  }
}
