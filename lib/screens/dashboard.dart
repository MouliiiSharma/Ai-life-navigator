// dashboard.dart
import 'package:ai_life_navigator/screens/deep_dive.dart';
import 'package:ai_life_navigator/screens/career_prediction_screen.dart';
import 'package:flutter/material.dart';
import 'personal_details.dart';
import 'ai_assistant.dart';
import 'settings.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PersonalDetailsScreen(),
    const AIAssistantScreen(),
    const CareerPredictionScreen(),
    const DeepDiveScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle(_currentIndex)),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          // Quick access to AI Assistant
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIAssistantScreen()),
              );
            },
          )
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Profile'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat), 
            label: 'AI Assistant'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), 
            label: 'Career AI'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics), 
            label: 'Deep Dive'
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings), 
            label: 'Settings'
          ),
        ],
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey,
        
      ),
    );
  }

  String getTitle(int index) {
    switch (index) {
      case 0:
        return "Personal Details";
      case 1:
        return "AI Assistant";
      case 2:
        return "Career Prediction";
      case 3:
        return "Career Deep Dive";
      case 4:
        return "Settings";
      default:
        return "Dashboard";
    }
  }
} // This closing brace was missing!