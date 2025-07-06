import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Data Models
class UserProfileData {
  final int userAge;
  final String userGender;
  final double userCgpa;
  final int userYearOfStudy;
  final String userBranch;
  final Map<String, int> userSkills;
  final Map<String, int> userInterests;
  final Map<String, int> userPersonality;

  UserProfileData({
    required this.userAge,
    required this.userGender,
    required this.userCgpa,
    required this.userYearOfStudy,
    required this.userBranch,
    required this.userSkills,
    required this.userInterests,
    required this.userPersonality,
  });

  Map<String, dynamic> toJson() {
    return {
      'userAge': userAge,
      'userGender': userGender,
      'userCgpa': userCgpa,
      'userYearOfStudy': userYearOfStudy,
      'userBranch': userBranch,
      'userSkills': userSkills,
      'userInterests': userInterests,
      'userPersonality': userPersonality,
    };
  }
}

class CareerPrediction {
  final String career;
  final int confidence;
  final String reasoning;
  final double salaryRange;
  final String industryGrowth;
  final List<String> skillsRequired;
  final List<String> suggestedCourses;

  CareerPrediction({
    required this.career,
    required this.confidence,
    required this.reasoning,
    required this.salaryRange,
    required this.industryGrowth,
    required this.skillsRequired,
    required this.suggestedCourses,
  });

  factory CareerPrediction.fromJson(Map<String, dynamic> json) {
    return CareerPrediction(
      career: json['career'] ?? '',
      confidence: json['confidence'] ?? 0,
      reasoning: json['reasoning'] ?? '',
      salaryRange: (json['salaryRange'] ?? 0).toDouble(),
      industryGrowth: json['industryGrowth'] ?? '',
      skillsRequired: List<String>.from(json['skillsRequired'] ?? []),
      suggestedCourses: List<String>.from(json['suggestedCourses'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'career': career,
      'confidence': confidence,
      'reasoning': reasoning,
      'salaryRange': salaryRange,
      'industryGrowth': industryGrowth,
      'skillsRequired': skillsRequired,
      'suggestedCourses': suggestedCourses,
    };
  }
}

class CareerPredictionResult {
  final String id;
  final List<CareerPrediction> predictions;
  final String explanation;
  final DateTime timestamp;
  final bool success;

  CareerPredictionResult({
    required this.id,
    required this.predictions,
    required this.explanation,
    required this.timestamp,
    required this.success,
  });

  factory CareerPredictionResult.fromJson(Map<String, dynamic> json) {
    return CareerPredictionResult(
      id: json['id'] ?? '',
      predictions: (json['predictions'] as List<dynamic>?)
          ?.map((p) => CareerPrediction.fromJson(p))
          .toList() ?? [],
      explanation: json['explanation'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      success: json['success'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'predictions': predictions.map((p) => p.toJson()).toList(),
      'explanation': explanation,
      'timestamp': Timestamp.fromDate(timestamp),
      'success': success,
    };
  }
}

class FeedbackData {
  final int rating;
  final String comment;
  final bool wasHelpful;
  final DateTime timestamp;

  FeedbackData({
    required this.rating,
    required this.comment,
    required this.wasHelpful,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'wasHelpful': wasHelpful,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      wasHelpful: json['wasHelpful'] ?? false,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}

// Enhanced Career Prediction Service
class CareerPredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<CareerPredictionResult> predictCareer(UserProfileData userProfile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final predictions = _generatePredictions(userProfile);
      
      final predictionResult = CareerPredictionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        predictions: predictions,
        explanation: _generateExplanation(userProfile, predictions),
        timestamp: DateTime.now(),
        success: true,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('career_predictions')
          .doc(predictionResult.id)
          .set(predictionResult.toJson());

      return predictionResult;
    } catch (e) {
      throw Exception('Failed to predict career: $e');
    }
  }

  List<CareerPrediction> _generatePredictions(UserProfileData profile) {
    List<CareerPrediction> predictions = [];

    Map<String, List<Map<String, dynamic>>> careersByBranch = {
      'Computer Science': [
        {
          'career': 'Software Engineer',
          'base_confidence': 85,
          'skills': ['Programming', 'Web Development'],
          'salary': 8.0,
          'growth': 'High',
          'required_skills': ['Java', 'Python', 'React', 'Node.js'],
          'courses': ['Full Stack Development', 'System Design', 'Cloud Computing']
        },
        {
          'career': 'Data Scientist',
          'base_confidence': 80,
          'skills': ['Data Analysis', 'Machine Learning'],
          'salary': 12.0,
          'growth': 'Very High',
          'required_skills': ['Python', 'R', 'SQL', 'TensorFlow'],
          'courses': ['Machine Learning', 'Statistics', 'Big Data Analytics']
        },
      ],
      'Electronics': [
        {
          'career': 'Electronics Engineer',
          'base_confidence': 80,
          'skills': ['Problem Solving', 'Analytical'],
          'salary': 6.0,
          'growth': 'Moderate',
          'required_skills': ['Circuit Design', 'PCB Design', 'Embedded Systems'],
          'courses': ['VLSI Design', 'Embedded Systems', 'Signal Processing']
        },
      ],
      'Mechanical': [
        {
          'career': 'Mechanical Engineer',
          'base_confidence': 85,
          'skills': ['Problem Solving', 'Analytical'],
          'salary': 5.5,
          'growth': 'Moderate',
          'required_skills': ['CAD', 'SolidWorks', 'AutoCAD', 'Manufacturing'],
          'courses': ['CAD/CAM', 'Robotics', 'Manufacturing Processes']
        },
      ],
    };

    List<Map<String, dynamic>> branchCareers = careersByBranch[profile.userBranch] ?? [];
    
    for (var careerData in branchCareers) {
      int confidence = careerData['base_confidence'];
      
      List<String> careerSkills = careerData['skills'];
      for (String skill in careerSkills) {
        if (profile.userSkills.containsKey(skill)) {
          confidence += (profile.userSkills[skill]! - 5) * 2;
        }
      }
      
      if (profile.userCgpa >= 8.5) {
        confidence += 5;
      } else if (profile.userCgpa >= 7.5) {
        confidence += 2;
      }
      
      confidence = confidence.clamp(0, 100);
      
      predictions.add(CareerPrediction(
        career: careerData['career'],
        confidence: confidence,
        reasoning: _generateReasoning(careerData['career'], profile),
        salaryRange: careerData['salary'],
        industryGrowth: careerData['growth'],
        skillsRequired: List<String>.from(careerData['required_skills']),
        suggestedCourses: List<String>.from(careerData['courses']),
      ));
    }

    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions.take(5).toList();
  }

  String _generateReasoning(String career, UserProfileData profile) {
    List<String> reasons = [];
    
    if (career.contains('Software') && profile.userBranch == 'Computer Science') {
      reasons.add('Strong alignment with your Computer Science background');
    }
    
    if (profile.userSkills['Programming'] != null && profile.userSkills['Programming']! >= 7) {
      reasons.add('High programming skills match the role requirements');
    }
    
    if (profile.userCgpa >= 8.0) {
      reasons.add('Excellent academic performance indicates strong potential');
    }
    
    return reasons.isNotEmpty ? reasons.join('; ') : 'Good match based on your profile';
  }

  String _generateExplanation(UserProfileData profile, List<CareerPrediction> predictions) {
    String explanation = "Based on your profile analysis:\n\n";
    explanation += "• Branch: ${profile.userBranch}\n";
    explanation += "• CGPA: ${profile.userCgpa}\n";
    explanation += "• Year: ${profile.userYearOfStudy}\n\n";
    
    explanation += "Your top skills and interests have been matched with current market demands.";
    
    return explanation;
  }

  Stream<List<CareerPredictionResult>> streamPredictions() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('career_predictions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CareerPredictionResult.fromJson(doc.data()))
          .toList();
    });
  }

  Future<void> provideFeedback(String predictionId, FeedbackData feedback) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('career_predictions')
        .doc(predictionId)
        .collection('feedback')
        .add(feedback.toJson());
  }
}

// Main Screen
class CareerPredictionScreen extends StatefulWidget {
  const CareerPredictionScreen({super.key});

  @override
  _CareerPredictionScreenState createState() => _CareerPredictionScreenState();
}

class _CareerPredictionScreenState extends State<CareerPredictionScreen> {
  final CareerPredictionService _predictionService = CareerPredictionService();
  bool _isLoading = false;
  CareerPredictionResult? _currentPrediction;

  final _formKey = GlobalKey<FormState>();
  int _userAge = 22;
  String _userGender = 'Male';
  double _userCgpa = 7.5;
  int _userYearOfStudy = 3;
  String _userBranch = 'Computer Science';

  final Map<String, int> _userSkills = {
    'Programming': 5,
    'Data Analysis': 5,
    'Machine Learning': 5,
    'Web Development': 5,
    'Communication': 5,
  };

  final Map<String, int> _userInterests = {
    'Technology': 5,
    'Research': 5,
    'Innovation': 5,
    'Problem Solving': 5,
    'Business': 5,
  };

  final Map<String, int> _userPersonality = {
    'Analytical': 5,
    'Creative': 5,
    'Leadership': 5,
    'Team Work': 5,
    'Adaptability': 5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Career Prediction'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            tooltip: 'Prediction History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PredictionHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _currentPrediction == null
              ? _buildPredictionForm()
              : _buildPredictionResults(),
    );
  }

  Widget _buildPredictionForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI-Powered Career Prediction', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Fill in your details to get personalized career recommendations.'),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            _buildSectionCard('Basic Information', [
              _buildNumberField('Age', _userAge, (value) => setState(() => _userAge = value as int)),
              _buildDropdownField('Gender', _userGender, ['Male', 'Female', 'Other'], (value) => setState(() => _userGender = value)),
              _buildNumberField('CGPA', _userCgpa, (value) => setState(() => _userCgpa = value as double), isDouble: true),
              _buildNumberField('Year of Study', _userYearOfStudy, (value) => setState(() => _userYearOfStudy = value as int)),
              _buildDropdownField('Branch', _userBranch, ['Computer Science', 'Electronics', 'Mechanical', 'Civil'], (value) => setState(() => _userBranch = value)),
            ]),
            
            SizedBox(height: 20),
            
            _buildSectionCard('Skills', [
              Text('Rate your skills from 1-10:'),
              ..._userSkills.keys.map((skill) => _buildSlider(skill, _userSkills[skill]!, (value) {
                setState(() => _userSkills[skill] = value);
              })),
            ]),
            
            SizedBox(height: 30),
            
            Center(
              child: ElevatedButton(
                onPressed: _startPrediction,
                child: Text('Get Career Prediction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, num value, Function(num) onChanged, {bool isDouble = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        onChanged: (val) {
          final parsed = isDouble ? double.tryParse(val) : int.tryParse(val);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: (val) => onChanged(val!),
      ),
    );
  }

  Widget _buildSlider(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: $value'),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (val) => onChanged(val.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResults() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Career Predictions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(_currentPrediction!.explanation),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 20),
          
          Text('Top Career Matches', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          
          ...(_currentPrediction!.predictions.map((prediction) => _buildCareerCard(prediction))),
          
          SizedBox(height: 20),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _provideFeedback,
                icon: Icon(Icons.feedback),
                label: Text('Feedback'),
              ),
              ElevatedButton.icon(
                onPressed: _newPrediction,
                icon: Icon(Icons.refresh),
                label: Text('New Prediction'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard(CareerPrediction prediction) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text('${prediction.confidence}%', style: TextStyle(color: Colors.white, fontSize: 12)),
        ),
        title: Text(prediction.career, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prediction.reasoning),
            SizedBox(height: 4),
            Text('Salary: ₹${prediction.salaryRange.toStringAsFixed(0)}L+'),
            Text('Growth: ${prediction.industryGrowth}'),
          ],
        ),
      ),
    );
  }

  Future<void> _startPrediction() async {
    setState(() => _isLoading = true);
    
    try {
      final userProfile = UserProfileData(
        userAge: _userAge,
        userGender: _userGender,
        userCgpa: _userCgpa,
        userYearOfStudy: _userYearOfStudy,
        userBranch: _userBranch,
        userSkills: _userSkills,
        userInterests: _userInterests,
        userPersonality: _userPersonality,
      );
      
      final result = await _predictionService.predictCareer(userProfile);
      
      setState(() {
        _currentPrediction = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _provideFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Provide Feedback'),
        content: Text('Rate the prediction quality'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _newPrediction() {
    setState(() {
      _currentPrediction = null;
    });
  }
}

// History Screen
class PredictionHistoryScreen extends StatelessWidget {
  final CareerPredictionService _predictionService = CareerPredictionService();

  PredictionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction History'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CareerPredictionResult>>(
        stream: _predictionService.streamPredictions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('No predictions yet. Create your first prediction!'),
            );
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final prediction = snapshot.data![index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text('Prediction ${index + 1}'),
                  subtitle: Text(prediction.timestamp.toString().substring(0, 16)),
                  trailing: Text('${prediction.predictions.length} careers'),
                  onTap: () {
                    // Navigate to detailed view
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}