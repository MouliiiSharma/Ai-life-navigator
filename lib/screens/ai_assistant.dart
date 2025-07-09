import 'package:flutter/material.dart';
import 'chat_screen.dart'; // import this at the top

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Life Assistant")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatScreen()),
            );
          },
          child: const Text("Talk to AI Assistant"),
        ),
      ),
    );
  }
}