import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.language),
            title: Text('Lingua'),
            subtitle: Text('Italiano'),
          ),
          ListTile(
            leading: Icon(Icons.update),
            title: Text('Aggiornamento automatico EPG'),
            subtitle: Text('Ogni 24 ore'),
          ),
          ListTile(
            leading: Icon(Icons.high_quality),
            title: Text('Qualità video predefinita'),
            subtitle: Text('Auto'),
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Versione'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}
