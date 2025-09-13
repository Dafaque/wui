import 'package:flutter/material.dart';
import 'package:whisperui/views/settings.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transcribe'),
        actions: [
          IconButton(
            onPressed: _navigateToSettings,
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Center(child: Text('Transcribe')),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsView()),
    );
  }
}
