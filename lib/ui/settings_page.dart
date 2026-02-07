import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme_constants.dart';

class SettingsPage extends StatefulWidget {
  final String currentKey;
  const SettingsPage({Key? key, required this.currentKey}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late String _selectedKey;

  @override
  void initState() {
    super.initState();
    _selectedKey = widget.currentKey;
  }

  Future<void> _saveAndClose(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', key);
    Navigator.of(context).pop(key);
  }

  @override
  Widget build(BuildContext context) {
    final keys = ThemeConstants.themeNames.keys.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        children: [
          for (final k in keys)
            RadioListTile<String>(
              value: k,
              groupValue: _selectedKey,
              title: Text(ThemeConstants.themeNames[k] ?? k),
              onChanged: (v) {
                if (v == null) return;
                setState(() => _selectedKey = v);
                _saveAndClose(v);
              },
            ),
        ],
      ),
    );
  }
}