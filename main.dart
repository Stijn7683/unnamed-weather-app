import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:weer_app/service/weer_service.dart';

import 'service/weather_page_container.dart';
import 'models/pages_model.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

  final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 229, 236, 254),
  ),
);

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color.fromARGB(255, 229, 236, 254),
    brightness: Brightness.dark,
  ),
);

void main() async {


  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  await Hive.openBox('mybox');


  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PagesModel()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => WeatherService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /*
      theme: ThemeData.light().copyWith(
        appBarTheme: const AppBarTheme(shadowColor:Color.fromARGB(153, 158, 158, 158)),
      ),
      */
  theme: lightTheme,
  darkTheme: darkTheme,
    /*
      darkTheme: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(shadowColor: Color.fromARGB(153, 61, 61, 61)),
      ),
      */
      //theme: ThemeData.light(), 
      //darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      title: 'Weather App',
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('nl'),
      ],
      scrollBehavior: MyCustomScrollBehavior(),
      home: const WeatherPageContainer(),
    );
  }
}
