import 'package:flutter/material.dart';

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations Personnelles'),
        backgroundColor: const Color(0xFF66BB6A),
      ),
      body: const Center(child: Text('Page des informations personnelles')),
    );
  }
}
