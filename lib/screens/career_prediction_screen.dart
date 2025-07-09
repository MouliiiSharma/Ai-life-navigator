import 'package:flutter/material.dart';
import '../services/career_service.dart';

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

  // User profile data with enhanced management skills
  int _userAge = 22;
  String _userGender = 'Male';
  double _userCgpa = 7.5;
  int _userYearOfStudy = 3;
  String _userBranch = 'Computer Science';

  // Enhanced skills including management capabilities
  final Map<String, int> _userSkills = {
    'Programming': 5,
    'Mathematics': 5,
    'Data Analysis': 5,
    'Machine Learning': 5,
    'Communication': 5,
    'Leadership': 5,
    'Management': 5,
    'Problem Solving': 5,
    'Analytical': 5,
    'Creative': 5,
    'Team Work': 5,
  };

  final Map<String, int> _userInterests = {
    'Technology': 5,
    'Research': 5,
    'Innovation': 5,
    'Business': 5,
    'Management': 5,
    'Data Analysis': 5,
    'Leadership': 5,
    'Strategy': 5,
  };

  final Map<String, int> _userPersonality = {
    'Extroversion': 5,
    'Openness': 5,
    'Conscientiousness': 5,
    'Leadership': 5,
    'Agreeableness': 5,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Career Prediction'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            tooltip: 'AI-Powered Predictions',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Using Google Vertex AI AutoML for predictions'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingScreen()
          : _currentPrediction == null
              ? _buildPredictionForm()
              : _buildPredictionResults(),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          const Text(
            '🤖 AI is analyzing your profile...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Using Google Vertex AI AutoML',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI-Powered Career Prediction',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const Text(
                                'Powered by Google Vertex AI AutoML',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Get personalized career recommendations including management opportunities using our trained AI model.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Basic Information Section
            _buildSectionCard('📋 Basic Information', [
              _buildNumberField('Age', _userAge.toDouble(), (value) => setState(() => _userAge = value.toInt())),
              _buildDropdownField('Gender', _userGender, ['Male', 'Female', 'Other'], (value) => setState(() => _userGender = value)),
              _buildNumberField('CGPA', _userCgpa, (value) => setState(() => _userCgpa = value), isDouble: true, max: 10.0),
              _buildNumberField('Year of Study', _userYearOfStudy.toDouble(), (value) => setState(() => _userYearOfStudy = value.toInt()), max: 4.0),
              _buildDropdownField('Branch', _userBranch, ['Computer Science', 'Electronics', 'Mechanical', 'Civil'], (value) => setState(() => _userBranch = value)),
            ]),
            
            const SizedBox(height: 20),
            
            // Skills Section
            _buildSectionCard('🛠️ Technical & Management Skills', [
              const Text(
                'Rate your skills from 1-10:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ..._userSkills.keys.map((skill) => _buildSkillSlider(skill, _userSkills[skill]!, (value) {
                setState(() => _userSkills[skill] = value);
              })),
            ]),
            
            const SizedBox(height: 20),
            
            // Interests Section
            _buildSectionCard('🎯 Interests & Preferences', [
              const Text(
                'Rate your interests from 1-10:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ..._userInterests.keys.map((interest) => _buildSkillSlider(interest, _userInterests[interest]!, (value) {
                setState(() => _userInterests[interest] = value);
              })),
            ]),
            
            const SizedBox(height: 30),
            
            // Prediction Button
            Center(
              child: ElevatedButton(
                onPressed: _startVertexAIPrediction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.psychology),
                    const SizedBox(width: 8),
                    const Text(
                      'Get AI Career Prediction',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This prediction uses a trained machine learning model that analyzes patterns from thousands of successful career transitions.',
                        style: TextStyle(color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, double value, Function(double) onChanged, {bool isDouble = false, double? max}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value.toString(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: max != null ? Text('Max: ${max.toInt()}') : null,
        ),
        keyboardType: TextInputType.number,
        validator: (val) {
          final parsed = double.tryParse(val ?? '');
          if (parsed == null) return 'Please enter a valid number';
          if (max != null && parsed > max) return 'Value cannot exceed $max';
          return null;
        },
        onChanged: (val) {
          final parsed = double.tryParse(val);
          if (parsed != null) onChanged(parsed);
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: options.map((option) => DropdownMenuItem(
          value: option,
          child: Text(option),
        )).toList(),
        onChanged: (val) => onChanged(val!),
      ),
    );
  }

  Widget _buildSkillSlider(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$value/10',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            activeColor: Colors.blue.shade700,
            onChanged: (val) => onChanged(val.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionResults() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 3,
            color: _currentPrediction!.success ? Colors.green.shade50 : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _currentPrediction!.success ? Icons.psychology : Icons.warning,
                        color: _currentPrediction!.success ? Colors.green.shade700 : Colors.orange.shade700,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPrediction!.success ? 'AI Career Predictions' : 'Fallback Predictions',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _currentPrediction!.success ? Colors.green.shade700 : Colors.orange.shade700,
                              ),
                            ),
                            Text(
                              _currentPrediction!.success ? 'Powered by Vertex AI AutoML' : 'AI temporarily unavailable',
                              style: TextStyle(
                                fontSize: 12,
                                color: _currentPrediction!.success ? Colors.green.shade600 : Colors.orange.shade600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_currentPrediction!.explanation),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Career Predictions
          const Text(
            'Your Career Matches',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          
          ...(_currentPrediction!.predictions.asMap().entries.map((entry) {
            int index = entry.key;
            CareerPrediction prediction = entry.value;
            return _buildCareerCard(prediction, index);
          })),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _newPrediction,
                icon: const Icon(Icons.refresh),
                label: const Text('New Prediction'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _provideFeedback,
                icon: const Icon(Icons.feedback),
                label: const Text('Feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareerCard(CareerPrediction prediction, int index) {
    Color confidenceColor = prediction.confidence >= 80 
        ? Colors.green 
        : prediction.confidence >= 60 
            ? Colors.orange 
            : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: index == 0 ? 4 : 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: index == 0 ? Border.all(color: Colors.blue.shade300, width: 2) : null,
        ),
        child: ExpansionTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: confidenceColor,
                radius: 25,
                child: Text(
                  '${prediction.confidence}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          title: Text(
            prediction.career,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: index == 0 ? 18 : 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prediction.reasoning,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (index == 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Top Match',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('💰 Salary Range:', '₹${prediction.salaryRange.toStringAsFixed(0)}L+ per annum'),
                  _buildInfoRow('📈 Industry Growth:', prediction.industryGrowth),
                  const SizedBox(height: 12),
                  const Text('Required Skills:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: prediction.skillsRequired.map((skill) => Chip(
                      label: Text(skill, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.blue.shade50,
                      side: BorderSide(color: Colors.blue.shade200),
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('Suggested Courses:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...prediction.suggestedCourses.map((course) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline, size: 16, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Expanded(child: Text(course)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _startVertexAIPrediction() async {
    if (!_formKey.currentState!.validate()) return;
    
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
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success 
              ? '🤖 AI prediction completed successfully!' 
              : '⚠️ Using fallback predictions - AI temporarily unavailable'
          ),
          backgroundColor: result.success ? Colors.green : Colors.orange,
        ),
      );
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _provideFeedback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Provide Feedback'),
        content: const Text('Rate the prediction quality and help us improve our AI model.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: const Text('Submit'),
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


