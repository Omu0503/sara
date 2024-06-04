import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:navapp2/AudioModule/audio.dart';
import 'package:navapp2/AudioModule/try.dart';
import 'package:navapp2/Models/PlaceProviders.dart';
import 'package:navapp2/screens/searchPage.dart';
import 'package:provider/provider.dart';

import 'screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.

  @override
  void initState() {
    // TODO: implement initState
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final placesProvider = Places();

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => LocationProvider(),
            ),
            ChangeNotifierProvider(create: (context) => placesProvider)
          ],
          child: Builder(builder: (context) {
            return 
            
            // STT()
            Home(placesProvider: placesProvider)
            ;
          })),
    );
  }
}
