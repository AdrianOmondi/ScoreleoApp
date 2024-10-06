import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scoreleo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const ScoreleoHomePage(),
    );
  }
}

class ScoreleoHomePage extends StatefulWidget {
  const ScoreleoHomePage({super.key});

  @override
  _ScoreleoHomePageState createState() => _ScoreleoHomePageState();
}

class _ScoreleoHomePageState extends State<ScoreleoHomePage> {
  List<dynamic> matches = [];
  bool isLoading = true;
  bool hasError = false;

  Future<void> fetchMatches() async {
    var url = Uri.parse('https://v3.football.api-sports.io/fixtures?date=${DateTime.now().toIso8601String().split("T")[0]}');
    try {
      var response = await http.get(
        url,
        headers: {
          "x-rapidapi-host": "v3.football.api-sports.io",
          "x-rapidapi-key": "7c8b6208c94aaaaf7861641703244162",
        },
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        setState(() {
          matches = data['response'];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchMatches();
    // Refresh matches every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (Timer t) => fetchMatches());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoreleo Livescores Today'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading data. Please try again later.'))
              : matches.isEmpty
                  ? const Center(child: Text('No matches available'))
                  : ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        var match = matches[index];
                        return MatchTile(match: match);
                      },
                    ),
    );
  }
}

class Timer {
  static void periodic(Duration duration, Future<void> Function(Timer t) param1) {}
}

class MatchTile extends StatelessWidget {
  final dynamic match;

  const MatchTile({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    var fixtureDate = DateTime.parse(match['fixture']['date']);
    var dateFormatted = fixtureDate.toLocal().toIso8601String().split("T")[0];
    var timeFormatted = "${fixtureDate.toLocal().hour}:${fixtureDate.toLocal().minute.toString().padLeft(2, '0')}";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match['league']['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${match['teams']['home']['name']}'),
                      const SizedBox(height: 5),
                      Image.network(match['teams']['home']['logo'], height: 30),
                    ],
                  ),
                ),
                Text(
                  '${match['goals']['home'] ?? '?'} - ${match['goals']['away'] ?? '?'}',
                  style: const TextStyle(fontSize: 20),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${match['teams']['away']['name']}'),
                      const SizedBox(height: 5),
                      Image.network(match['teams']['away']['logo'], height: 30),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Date: $dateFormatted'),
            Text('Time: $timeFormatted'),
            Text('Status: ${match['fixture']['status']['short']}'),
          ],
        ),
      ),
    );
  }
}
