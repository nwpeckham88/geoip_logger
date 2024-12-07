import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoip_logger/firestore_api_loader.dart';
import 'package:http/http.dart' as http;

class TerminalWidget extends StatefulWidget {
  @override
  _TerminalWidgetState createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final GeoIPFirebaseFirestore firestore = GeoIPFirebaseFirestore();
  List<Map<String, dynamic>> _apis = [];
  Duration pollingInterval = Duration(hours: 12);
  Timer? timer;
  String _logOutput = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    firestore.loadApis().then((_) => setState(() {}));
      fetchAndLog('https://api.ipgeolocation.io/json/?key=YOUR_API_KEY');
    startPolling();
  }

  Future<void> fetchAndLog(String apiUrl) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        // Convert the JSON response to a Map
        final data = jsonDecode(response.body);
        final CollectionReference geoIpCollection = FirebaseFirestore.instance.collection('geoip');
        await geoIpCollection.add({
          'api': apiUrl,
            'data': data,
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() {
          _logOutput += '\nData fetched from $apiUrl: ${jsonEncode(data)}';
        _isLoading = false;
      });
        } else {
        print('Failed to load data from $apiUrl');
        setState(() {
          _logOutput += '\nFailed to load data from $apiUrl\n';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching data from $apiUrl: $e');
      setState(() {
        _logOutput += 'Error fetching data from $apiUrl: $e\n';
        _isLoading = false;
      });
    }
  }

  void startPolling() {
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(pollingInterval, (timer) async {
      await fetchAndLog('https://api.ipgeolocation.io/json/?key=YOUR_API_KEY');
    });
  }

  void clearLog() {
    setState(() {
      _logOutput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalHours = pollingInterval.inHours;
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoIP Logger'),
            ),
      body: Column(
        children: [
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
              ElevatedButton(onPressed: () => startPolling(), child: Text('Start Polling')),
              ElevatedButton(onPressed: clearLog, child: Text('Clear Log')),
            ],
          ),
          SizedBox(height: 16),
          Text('Next polling in $totalHours hours'),
          if (_isLoading) Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
