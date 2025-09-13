import 'package:flutter/material.dart';
import 'package:whisperui/components/loader.dart';
import 'package:whisperui/services/settings.dart';
import 'package:whisperui/views/main.dart';

class InitView extends StatefulWidget {
  const InitView({super.key});

  @override
  State<InitView> createState() => _InitViewState();
}

class _InitViewState extends State<InitView> {
  String? error;

  @override
  void initState() {
    super.initState();
    SettingsService.instance().init().then(_navigateToHome).catchError((error) {
      setState(() {
        this.error = error.toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildBody());
  }

  void _navigateToHome(void _) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeView()),
    );
  }

  Widget _buildBody() {
    return Center(
      child: error == null
          ? Loader()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.error,
                  size: 48,
                ),
                Text(
                  error ?? 'Empty exception',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
    );
  }
}
