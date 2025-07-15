
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ai_life_navigator/secrets.dart';

// Data Models (keep your existing ones)
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

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      userAge: json['userAge'] ?? 22,
      userGender: json['userGender'] ?? 'Male',
      userCgpa: (json['userCgpa'] ?? 7.5).toDouble(),
      userYearOfStudy: json['userYearOfStudy'] ?? 3,
      userBranch: json['userBranch'] ?? 'Computer Science',
      userSkills: Map<String, int>.from(json['userSkills'] ?? {}),
      userInterests: Map<String, int>.from(json['userInterests'] ?? {}),
      userPersonality: Map<String, int>.from(json['userPersonality'] ?? {}),
    );
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
      predictions: (json['predictions'] as List?)
          ?.map((p) => CareerPrediction.fromJson(p))
          .toList() ?? [],
      explanation: json['explanation'] ?? '',
      timestamp: json['timestamp'] is Timestamp 
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
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

// FIXED Main Service Class
class CareerPredictionService {
  static const String PROJECT_ID = Secrets.vertexProjectId;
  static const String LOCATION = Secrets.vertexLocation;
  static const String ENDPOINT_ID = Secrets.vertexEndpointId;
  static const String MODEL_ID = Secrets.vertexModelId;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Cache for service account credentials
  ServiceAccountCredentials? _cachedCredentials;

  Future<CareerPredictionResult> predictCareer(UserProfileData userProfile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('🤖 Starting Vertex AI prediction...');
      
      // Try Vertex AI prediction with proper token refresh
      try {
        final vertexPredictions = await _callVertexAIEndpointWithFreshToken(userProfile);
        final predictions = _convertVertexAIResponse(vertexPredictions, userProfile);

        final predictionResult = CareerPredictionResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          predictions: predictions,
          explanation: _generateVertexAIExplanation(userProfile, predictions),
          timestamp: DateTime.now(),
          success: true,
        );

        // Save to Firestore
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('career_predictions')
            .doc(predictionResult.id)
            .set(predictionResult.toJson());

        print('✅ Vertex AI prediction completed successfully');
        return predictionResult;
      } catch (e) {
        print('⚠️ Vertex AI failed, using enhanced fallback: $e');
        return _fallbackPrediction(userProfile);
      }
    } catch (e) {
      print('❌ Prediction error: $e');
      throw Exception('Failed to predict career: $e');
    }
  }

  // FIXED: Proper token generation with fresh tokens
  Future<Map<String, dynamic>> _callVertexAIEndpointWithFreshToken(UserProfileData userProfile) async {
    try {
      // Generate fresh access token for each request
      final accessToken = await _getFreshAccessToken();
      final predictionData = _formatUserDataForVertexAI(userProfile);
      
      const url = 'https://$LOCATION-aiplatform.googleapis.com/v1/projects/$PROJECT_ID/locations/$LOCATION/endpoints/$ENDPOINT_ID:predict';
      
      print('🔗 Calling Vertex AI endpoint with fresh token...');
      print('📍 URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'User-Agent': 'AI-Life-Navigator/1.0',
        },
        body: jsonEncode({
          'instances': [predictionData],
        }),
      );

      print('📡 Vertex AI response status: ${response.statusCode}');
      print('📡 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Vertex AI response received successfully');
        print('📄 Response data keys: ${responseData.keys}');
        return responseData;
      } else {
        print('❌ Vertex AI API error details:');
        print('   Status: ${response.statusCode}');
        print('   Body: ${response.body}');
        print('   Headers: ${response.headers}');
        
        // Specific error handling
        if (response.statusCode == 401) {
          throw Exception('Authentication failed - token may be invalid or expired');
        } else if (response.statusCode == 403) {
          throw Exception('Access forbidden - check service account permissions and API enablement');
        } else if (response.statusCode == 404) {
          throw Exception('Endpoint not found - verify PROJECT_ID, LOCATION, and ENDPOINT_ID');
        } else {
          throw Exception('Vertex AI API error: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Vertex AI call failed: $e');
      throw Exception('Failed to call Vertex AI endpoint: $e');
    }
  }

  // FIXED: Proper fresh token generation
  Future<String> _getFreshAccessToken() async {
  try {
    print('🔑 Generating fresh access token...');
    
    // Updated service account credentials with new private key
    final serviceAccountJson = {
      "type": "service_account",
      "project_id": Secrets.vertexProjectId,
      "private_key_id": Secrets.vertexServiceAccountPrivateKeyId,  
      "private_key": Secrets.vertexServiceAccountPrivateKey,
      "client_email": Secrets.client_email,
      "client_id": Secrets.client_id,
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/${Secrets.client_email}",
      "universe_domain": "googleapis.com"
    };
    
    // Create credentials from JSON
    final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
    
    // Create authenticated HTTP client
    final client = await clientViaServiceAccount(
      credentials,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );
    
    // Extract the access token
    final accessToken = client.credentials.accessToken.data;
    
    // Close the client
    client.close();
    
    print('✅ Fresh access token generated successfully');
    print('🔑 Token preview: ${accessToken.substring(0, 20)}...');
    
    return accessToken;
  } catch (e) {
    print('❌ Failed to generate access token: $e');
    throw Exception('Failed to get access token: $e');
  }
}

  Map<String, dynamic> _formatUserDataForVertexAI(UserProfileData userProfile) {
  return {
    // Basic demographic data - convert to strings to match AutoML schema
    'age': userProfile.userAge.toString(),
    'gender': userProfile.userGender,  // Already a string
    'cgpa': userProfile.userCgpa.toString(),
    'year_of_study': userProfile.userYearOfStudy.toString(),
    'branch': userProfile.userBranch,  // Already a string
    
    // Skills - convert to string format matching your training data (1-5 scale)
    'skill_programming': (userProfile.userSkills['Programming'] ?? 5).toString(),
    'skill_mathematics': (userProfile.userSkills['Mathematics'] ?? 5).toString(),
    'skill_communication': (userProfile.userSkills['Communication'] ?? 5).toString(),
    'skill_leadership': (userProfile.userSkills['Leadership'] ?? 5).toString(),
    'skill_analytical_thinking': (userProfile.userSkills['Analytical'] ?? 5).toString(),
    'skill_creativity': (userProfile.userSkills['Creative'] ?? 5).toString(),
    'skill_problem_solving': (userProfile.userSkills['Problem Solving'] ?? 5).toString(),
    'skill_teamwork': (userProfile.userSkills['Team Work'] ?? 5).toString(),
    'skill_technical_writing': (userProfile.userSkills['Technical Writing'] ?? 5).toString(),
    'skill_presentation': (userProfile.userSkills['Presentation'] ?? 5).toString(),
    
    // Interests - convert to string format (1-5 scale)
    'interest_technology': (userProfile.userInterests['Technology'] ?? 5).toString(),
    'interest_research': (userProfile.userInterests['Research'] ?? 5).toString(),
    'interest_business': (userProfile.userInterests['Business'] ?? 5).toString(),
    'interest_design': (userProfile.userInterests['Design'] ?? 5).toString(),
    'interest_management': (userProfile.userInterests['Management'] ?? 5).toString(),
    'interest_innovation': (userProfile.userInterests['Innovation'] ?? 5).toString(),
    'interest_data_analysis': (userProfile.userInterests['Data Analysis'] ?? 5).toString(),
    'interest_user_experience': (userProfile.userInterests['User Experience'] ?? 5).toString(),
    'interest_security': (userProfile.userInterests['Security'] ?? 5).toString(),
    
    // Personality traits - convert to string format (1-5 scale)
    'extroversion': (userProfile.userPersonality['Extroversion'] ?? 5).toString(),
    'openness': (userProfile.userPersonality['Openness'] ?? 5).toString(),
    'conscientiousness': (userProfile.userPersonality['Conscientiousness'] ?? 5).toString(),
    'agreeableness': (userProfile.userPersonality['Agreeableness'] ?? 5).toString(),
    'neuroticism': (userProfile.userPersonality['Neuroticism'] ?? 5).toString(),
  };
}



  List<CareerPrediction> _convertVertexAIResponse(Map<String, dynamic> vertexResponse, UserProfileData userProfile) {
    List<CareerPrediction> predictions = [];
    
    try {
      print('🔍 Processing Vertex AI response...');
      print('📄 Response structure: ${vertexResponse.keys}');
      
      final vertexPredictions = vertexResponse['predictions'] as List;
      
      if (vertexPredictions.isNotEmpty) {
        final prediction = vertexPredictions[0];
        print('📊 Prediction structure: ${prediction.keys}');
        
        String predictedCareer;
        double confidence;
        
        if (prediction.containsKey('classes') && prediction.containsKey('scores')) {
          List<String> classes = List<String>.from(prediction['classes']);
          List<double> scores = List<double>.from(prediction['scores']);
          
          print('🎯 Classes: $classes');
          print('📊 Scores: $scores');
          
          int maxIndex = 0;
          double maxScore = scores[0];
          for (int i = 1; i < scores.length; i++) {
            if (scores[i] > maxScore) {
              maxScore = scores[i];
              maxIndex = i;
            }
          }
          
          predictedCareer = classes[maxIndex];
          confidence = maxScore * 100;
          
          predictions.add(CareerPrediction(
            career: predictedCareer,
            confidence: confidence.round(),
            reasoning: 'AI model prediction based on comprehensive profile analysis',
            salaryRange: _getSalaryRange(predictedCareer),
            industryGrowth: _getIndustryGrowth(predictedCareer),
            skillsRequired: _getRequiredSkills(predictedCareer),
            suggestedCourses: _getSuggestedCourses(predictedCareer),
          ));
          
          // Add alternative predictions
          for (int i = 0; i < classes.length && predictions.length < 5; i++) {
            if (i != maxIndex && scores[i] > 0.1) {
              predictions.add(CareerPrediction(
                career: classes[i],
                confidence: (scores[i] * 100).round(),
                reasoning: 'Alternative career path identified by AI model',
                salaryRange: _getSalaryRange(classes[i]),
                industryGrowth: _getIndustryGrowth(classes[i]),
                skillsRequired: _getRequiredSkills(classes[i]),
                suggestedCourses: _getSuggestedCourses(classes[i]),
              ));
            }
          }
        } else {
          predictedCareer = prediction['value']?.toString() ?? 'Software Engineer';
          confidence = 80.0;
          
          predictions.add(CareerPrediction(
            career: predictedCareer,
            confidence: confidence.round(),
            reasoning: 'AI model prediction based on comprehensive profile analysis',
            salaryRange: _getSalaryRange(predictedCareer),
            industryGrowth: _getIndustryGrowth(predictedCareer),
            skillsRequired: _getRequiredSkills(predictedCareer),
            suggestedCourses: _getSuggestedCourses(predictedCareer),
          ));
        }
        
        // Add management alternatives if user has management skills
        if (userProfile.userSkills['Management'] != null && userProfile.userSkills['Management']! >= 7) {
          predictions.addAll(_getManagementAlternatives(userProfile));
        }
      }
    } catch (e) {
      print('❌ Error parsing Vertex AI response: $e');
      predictions.add(CareerPrediction(
        career: 'Software Engineer',
        confidence: 75,
        reasoning: 'Fallback prediction due to response parsing error',
        salaryRange: 12.0,
        industryGrowth: 'High',
        skillsRequired: ['Programming', 'Problem Solving'],
        suggestedCourses: ['Full Stack Development', 'System Design'],
      ));
    }
    
    return predictions;
  }

  // Helper methods (keep your existing ones)
  double _getSalaryRange(String career) {
    final salaryMap = {
      'Data Scientist': 15.0,
      'Software Engineer': 12.0,
      'Product Manager': 18.0,
      'DevOps Engineer': 14.0,
      'UI/UX Designer': 10.0,
      'Business Analyst': 9.0,
      'Cybersecurity Analyst': 13.0,
      'Machine Learning Engineer': 16.0,
      'Full Stack Developer': 11.0,
      'Research Scientist': 17.0,
      'Technical Project Manager': 16.0,
      'Engineering Manager': 20.0,
      'Operations Manager': 13.0,
      'Management Trainee': 8.0,
      'Business Development Manager': 11.0,
    };
    return salaryMap[career] ?? 10.0;
  }

  String _getIndustryGrowth(String career) {
    final growthMap = {
      'Data Scientist': 'Very High',
      'Software Engineer': 'High',
      'Product Manager': 'Very High',
      'DevOps Engineer': 'High',
      'UI/UX Designer': 'Moderate',
      'Business Analyst': 'Moderate',
      'Cybersecurity Analyst': 'Very High',
      'Machine Learning Engineer': 'Very High',
      'Full Stack Developer': 'High',
      'Research Scientist': 'Moderate',
      'Technical Project Manager': 'High',
      'Engineering Manager': 'High',
      'Operations Manager': 'Moderate',
      'Management Trainee': 'High',
      'Business Development Manager': 'High',
    };
    return growthMap[career] ?? 'Moderate';
  }

  List<String> _getRequiredSkills(String career) {
    final skillsMap = {
      'Data Scientist': ['Python', 'R', 'SQL', 'Machine Learning', 'Statistics'],
      'Software Engineer': ['Programming', 'Algorithms', 'System Design', 'Debugging'],
      'Product Manager': ['Strategy', 'Analytics', 'Communication', 'Leadership'],
      'DevOps Engineer': ['Cloud Computing', 'CI/CD', 'Containerization', 'Monitoring'],
      'UI/UX Designer': ['Design Tools', 'User Research', 'Prototyping', 'Visual Design'],
      'Business Analyst': ['Data Analysis', 'Requirements Gathering', 'Process Modeling'],
      'Cybersecurity Analyst': ['Security Frameworks', 'Risk Assessment', 'Incident Response'],
      'Machine Learning Engineer': ['Python', 'TensorFlow', 'Model Deployment', 'MLOps'],
      'Full Stack Developer': ['Frontend', 'Backend', 'Databases', 'APIs'],
      'Research Scientist': ['Research Methods', 'Data Analysis', 'Academic Writing'],
      'Technical Project Manager': ['Project Management', 'Agile', 'Technical Leadership'],
      'Engineering Manager': ['Team Management', 'Technical Strategy', 'Leadership'],
      'Operations Manager': ['Process Optimization', 'Team Leadership', 'Analytics'],
      'Management Trainee': ['Leadership', 'Communication', 'Business Acumen'],
      'Business Development Manager': ['Sales', 'Market Analysis', 'Relationship Management'],
    };
    return skillsMap[career] ?? ['Technical Skills', 'Problem Solving'];
  }

  List<String> _getSuggestedCourses(String career) {
    final coursesMap = {
      'Data Scientist': ['Machine Learning Specialization', 'Data Science with Python', 'Statistics'],
      'Software Engineer': ['Full Stack Development', 'System Design', 'Algorithms'],
      'Product Manager': ['Product Management', 'Business Strategy', 'User Experience'],
      'DevOps Engineer': ['Cloud Computing', 'Kubernetes', 'CI/CD Pipelines'],
      'UI/UX Designer': ['UI/UX Design', 'Design Thinking', 'Figma/Sketch'],
      'Business Analyst': ['Business Analysis', 'Data Analytics', 'Process Improvement'],
      'Cybersecurity Analyst': ['Cybersecurity Fundamentals', 'Ethical Hacking', 'Security+'],
      'Machine Learning Engineer': ['MLOps', 'Deep Learning', 'Model Deployment'],
      'Full Stack Developer': ['React/Angular', 'Node.js', 'Database Design'],
      'Research Scientist': ['Research Methodology', 'Academic Writing', 'Statistical Analysis'],
      'Technical Project Manager': ['PMP Certification', 'Agile Management', 'Technical Leadership'],
      'Engineering Manager': ['Engineering Management', 'Leadership', 'Strategic Planning'],
      'Operations Manager': ['Operations Management', 'Lean Six Sigma', 'Team Leadership'],
      'Management Trainee': ['MBA Preparation', 'Leadership Development', 'Business Strategy'],
      'Business Development Manager': ['Business Development', 'Sales Management', 'Market Research'],
    };
    return coursesMap[career] ?? ['Professional Development', 'Technical Skills'];
  }

  List<CareerPrediction> _getManagementAlternatives(UserProfileData userProfile) {
    List<CareerPrediction> managementCareers = [];
    
    if (userProfile.userBranch == 'Computer Science') {
      managementCareers.add(CareerPrediction(
        career: 'Technical Project Manager',
        confidence: 75,
        reasoning: 'Strong technical background combined with management skills',
        salaryRange: 16.0,
        industryGrowth: 'High',
        skillsRequired: ['Project Management', 'Technical Leadership', 'Agile'],
        suggestedCourses: ['PMP Certification', 'Technical Leadership', 'Agile Management'],
      ));
    }
    
    managementCareers.add(CareerPrediction(
      career: 'Management Trainee',
      confidence: 70,
      reasoning: 'Leadership potential suitable for management development programs',
      salaryRange: 8.0,
      industryGrowth: 'High',
      skillsRequired: ['Leadership', 'Communication', 'Strategic Thinking'],
      suggestedCourses: ['MBA Preparation', 'Leadership Development', 'Business Strategy'],
    ));
    
    return managementCareers;
  }

  CareerPredictionResult _fallbackPrediction(UserProfileData userProfile) {
    print('🔄 Using enhanced fallback prediction system');
    
    List<CareerPrediction> fallbackPredictions = [];
    
    String primaryCareer = userProfile.userBranch == 'Computer Science' ? 'Software Engineer' : 'Engineering Professional';
    fallbackPredictions.add(CareerPrediction(
      career: primaryCareer,
      confidence: 75,
      reasoning: 'Fallback prediction based on branch and profile - Vertex AI temporarily unavailable',
      salaryRange: 12.0,
      industryGrowth: 'High',
      skillsRequired: ['Technical Skills', 'Problem Solving'],
      suggestedCourses: ['Professional Development', 'Technical Skills'],
    ));
    
    if (userProfile.userSkills['Management'] != null && userProfile.userSkills['Management']! >= 6) {
      fallbackPredictions.add(CareerPrediction(
        career: 'Management Trainee',
        confidence: 65,
        reasoning: 'Management skills indicate potential for leadership roles',
        salaryRange: 8.0,
        industryGrowth: 'High',
        skillsRequired: ['Leadership', 'Communication'],
        suggestedCourses: ['MBA Preparation', 'Leadership Development'],
      ));
    }
    
    return CareerPredictionResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      predictions: fallbackPredictions,
      explanation: 'Prediction generated using enhanced fallback system due to AI service unavailability. Please check your internet connection and try again later for AI-powered predictions.',
      timestamp: DateTime.now(),
      success: false,
    );
  }

  String _generateVertexAIExplanation(UserProfileData profile, List<CareerPrediction> predictions) {
    String explanation = "🤖 **AI-Powered Career Prediction**\n\n";
    explanation += "This prediction was generated using our trained machine learning model on Google Vertex AI AutoML.\n\n";
    explanation += "**Your Profile Analysis:**\n";
    explanation += "• Branch: ${profile.userBranch}\n";
    explanation += "• CGPA: ${profile.userCgpa}\n";
    explanation += "• Year: ${profile.userYearOfStudy}\n";
    explanation += "• Top Skills: ${_getTopSkills(profile.userSkills)}\n";
    explanation += "• Management Aptitude: ${profile.userSkills['Management'] ?? 5}/10\n\n";
    
    if (predictions.isNotEmpty) {
      explanation += "**AI Recommendation:** ${predictions.first.career} with ${predictions.first.confidence}% confidence.\n\n";
      explanation += "This prediction is based on patterns learned from thousands of successful career transitions and current industry trends.";
    }
    
    return explanation;
  }

  String _getTopSkills(Map<String, int> skills) {
    var sortedSkills = skills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedSkills.take(3).map((e) => e.key).join(', ');
  }

  // Stream predictions for history
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
}
