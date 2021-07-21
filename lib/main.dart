import 'package:finale/util/image_id_cache.dart';
import 'package:finale/util/preferences.dart';
import 'package:finale/util/quick_actions_manager.dart';
import 'package:finale/util/theme.dart';
import 'package:finale/views/login_view.dart';
import 'package:finale/views/main_view.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await QuickActionsManager.setup();
  await Preferences().setup();
  await ImageIdCache().setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    final name = Preferences().name;

    return MaterialApp(
      title: 'Finale',
      theme: FinaleTheme.light,
      darkTheme: FinaleTheme.dark,
      home: name == null ? LoginView() : MainView(username: name),
    );
  }
}
