import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:production/Screens/Route/RouteScreen.dart';
import 'package:production/variables.dart';

class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  Future<void> lookupbyvpoidmovies() async {
    final response = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
            'YVOVs1CRLPdlaq6Zo1blAiKueJV10caebY3quZjYdQPFORqBN7BZFcGo5gXFmjinLp2E6mAEqY7tDnVzJg88k+3tT28LnLxNWzJ4IaU1JXgUR2plf9R6RQrTsl3V9FPARaSuHRx+A26sMhRxFp7Ve2F4XlDRldJEkcel/gM8WSwcZDIrcnXakVk2ZIBM9YnWbuOHTUHfUol6oDGK53bTC+Lnpn/Ld85e7IERcAg/tSQNK/yG09FyQYVo+jpS4XzvTwX6BzFpMyeOYZmjoUjTc7rhihM8upkR0ThKnLTvoGeiACi44GdQ/KQl8mM4eWVuQxivyCi3WBbLWl1FeotEKg==',
        'VSID': loginresponsebody?['vsid']?.toString() ?? "",
      },
      body: jsonEncode(<String, dynamic>{"vpoid": loginresult!['vpoid']}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        movieProjects = data['responseData'];
      });
    } else {
      print("Error: ${response.body}");
    }
  }

  @override
  void initState() {
    super.initState();
    lookupbyvpoidmovies();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Movies',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: movieProjects.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
            itemCount: movieProjects.length,
            itemBuilder: (context, index) {
              final project = movieProjects[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.movie, color: Colors.deepPurple),
                    title: Text(
                      project['projectTitle'],
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        selectedProjectId = project['projectId'].toString();
                        selectedProjectTitle =
                            project['projectTitle'].toString();
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Routescreen()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

}
