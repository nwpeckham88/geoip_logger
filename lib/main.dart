import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';
List<Map<String, dynamic>> apis = [];
const Duration pollingInterval = Duration(hours: 12);
String logFilePath = "geoIpLogs.json";
File logFile = File(logFilePath); // Initialize the variable here
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ApiLoader apiLoader = ApiLoader();
  apis = await apiLoader.loadApis();
  runApp(const MainApp());
}

class ApiLoader {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> loadApis() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('apis').get();
      List<Map<String, dynamic>> apis = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      return apis;
    } catch (e) {
      print('Error loading APIs: $e');
      return [];
    }
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('GeoIP Logger')),
        body: TerminalWidget(),
      ),
    );
  }
}

class TerminalWidget extends StatefulWidget {
  const TerminalWidget({super.key});

  @override
  _TerminalWidgetState createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {

  Timer? timer;
  String _logOutput = '';
  bool _isLoading = false;
  int totalSeconds = pollingInterval.inSeconds;
  int totalHours = pollingInterval.inHours;

  @override
  void initState() {
    super.initState();
    startPolling();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void startPolling() {
    for (Map<String, dynamic> api in apis) {
      print('API Name: ${api['name']}');
      print('API Endpoint: ${api['url']}');
      fetchAndLog(api['url']);
    }

    setState(() {
      _isLoading = false;
    
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) async {
      totalSeconds--;
      setState((){}); // This will trigger a rebuild of the widget tree
      if (totalSeconds <= 0) {
        t.cancel();
        startPolling();
        totalSeconds = pollingInterval.inSeconds;
      }
    });
  });
  }

  Future<void> fetchAndLog(String apiUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Write log to file
        logFile.writeAsStringSync(json.encode({
          'api': apiUrl,
          'data': data,
          'timestamp': DateTime.now().toIso8601String(),
        }));

        final CollectionReference geoIpCollection = FirebaseFirestore.instance.collection('geoip');

        // Adjust the data structure according to your GeoIP API response
        await geoIpCollection.add({
          'api': apiUrl,
          'data': data,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _logOutput += '\nData fetched from $apiUrl: ${jsonEncode(data)}';
        });
      } else {
        print('Failed to load data from $apiUrl');
        setState(() {
          _logOutput += '\nFailed to load data from $apiUrl\n';
        });
      }
    } catch (e) {
      print('Error fetching data from $apiUrl: $e');
      setState(() {
        _logOutput += 'Error fetching data from $apiUrl: $e\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void clearLog() {
    setState(() {
      _logOutput = '';
    });
    // Clear the file
    logFile.writeAsStringSync(''); 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('GeoIP Logger', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _logOutput.split('\n').length,
            itemBuilder: (context, index) {
              final line = _logOutput.split('\n')[index];
              return ListTile(title: Text(line));
            },
          ),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: startPolling, child: Text('Start Polling')),
            ElevatedButton(onPressed: clearLog, child: Text('Clear Log')),
          ],
        ),
        SizedBox(height: 16),
        Text('Next polling in $totalHours hours'), // This will show the countdown
        if (_isLoading) Center(child: CircularProgressIndicator()),
      ],
    );
  }
}