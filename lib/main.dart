import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geoip_logger/firestore_api_loader.dart';
import 'package:geoip_logger/terminal_widget.dart';

final GeoIPFirebaseFirestore firestore = GeoIPFirebaseFirestore();
const sidebarColor = Color(0xFFF6A00C);

String logFilePath = "geoIpLogs.json";
File logFile = File(logFilePath); // Initialize the variable here


const windowsOptions = FirebaseOptions(
        apiKey: "AIzaSyBH8IRntYetulk_PpJUlTN8_ZzmC-RahfA",
        authDomain: "geoip-logger.firebaseapp.com",
        projectId: "geoip-logger",
        storageBucket: "geoip-logger.firebasestorage.app",
        messagingSenderId: "398153664691",
        appId: "1:398153664691:web:ad6ae36553b4c3363348c6",
        measurementId: "G-VCFC36P079",
      );


//const windowsOptions = DefaultFirebaseOptions.currentPlatform;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  firestore.initializeFirebase(windowsOptions);
  firestore.loadApis();
  await firestore.loadApis();
  runApp(const MyApp());
    final win = appWindow;
    const initialSize = Size(600, 450);
    win.minSize = initialSize;
    win.size = initialSize;
    win.alignment = Alignment.center;
    win.title = "Custom window with Flutter";
    win.show();
}

const borderColor = Color(0xFF805306);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: WindowBorder(
          color: borderColor,
          width: 1,
          child: TerminalWidget(),
          ),
        ),
    );
  }
}

class LeftSide extends StatelessWidget {
  const LeftSide({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 200,
        child: Container(
            color: sidebarColor,
            child: Column(
              children: [
                WindowTitleBarBox(child: MoveWindow()),
                Expanded(child: Container())
              ],
            )));
  }
}

const backgroundStartColor = Color(0xFFFFD500);
const backgroundEndColor = Color(0xFFF6A00C);

class RightSide extends StatelessWidget {
  const RightSide({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [backgroundStartColor, backgroundEndColor],
                  stops: [0.0, 1.0]),
            ),
            child: Column(children: [
              WindowTitleBarBox(
                child: Row(
                  children: [
                    Expanded(child: MoveWindow()),
                    const WindowButtons()
                  ],
                ),
              ),
              Expanded(
                  child: Row(children: [Expanded(child: TerminalWidget())]))
            ])));
  }
}

final buttonColors = WindowButtonColors(
    iconNormal: const Color(0xFF805306),
    mouseOver: const Color(0xFFF6A00C),
    mouseDown: const Color(0xFF805306),
    iconMouseOver: const Color(0xFF805306),
    iconMouseDown: const Color(0xFFFFD500));

final closeButtonColors = WindowButtonColors(
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconNormal: const Color(0xFF805306),
    iconMouseOver: Colors.white);

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}