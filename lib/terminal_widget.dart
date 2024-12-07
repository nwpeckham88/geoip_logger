import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TerminalWidget extends StatefulWidget {

  const TerminalWidget({super.key, required this.options});

  @override
  State<StatefulWidget> createState() => _TerminalWidgetState();

}

class _TerminalWidgetState extends State<TerminalWidget> {
  Duration pollingInterval = Duration(hours: 12);
  Timer? timer;
  String _logOutput = '';
  bool _isLoading = false;

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
    for (Map<String, dynamic> api in widget._apis) {
      print('API Name: ${api['name']}');
      print('API Endpoint: ${api['url']}');
      fetchAndLog(api['url']);
    }
    // Log just the IP address, in case that is all we can get
    fetchAndLog("https://api.ipify.org?format=json");

    setState(() {
      _isLoading = false;
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
        // logFile.writeAsStringSync(json.encode({
        //   'api': apiUrl,
        //   'data': data,
        //   'timestamp': DateTime.now().toIso8601String(),
        // }));

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
    // logFile.writeAsStringSync(''); 
  }

  @override
  Widget build(BuildContext context) {
    int totalHours = pollingInterval.inHours;
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