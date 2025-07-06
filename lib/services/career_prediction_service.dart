import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class CareerPredictionService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Configure Firebase Functions for web
  static void initialize() {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }

  // Enhanced career prediction with comprehensive fallback
  Future<CareerPredictionResult> predictCareer(UserProfileData userProfile) async {
    try {
      // Ensure user is authenticated
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to get predictions');
      }

      print('Starting career prediction for user: ${user.uid}');

      // Try multiple prediction methods in order
      CareerPredictionResult result;

      try {
        // Method 1: Firebase Functions + AutoML
        result = await _predictWithFirebaseFunctions(userProfile);
        print('✅ Firebase Functions prediction successful');
      } catch (e) {
        print('⚠️ Firebase Functions failed: $e');
        try {
          // Method 2: Direct HTTP API call
          result = await _predictWithDirectAPI(userProfile);
          print('✅ Direct API prediction successful');
        } catch (e2) {
          print('⚠️ Direct API failed: $e2');
          // Method 3: Enhanced local prediction
          result = await _predictWithEnhancedLocalEngine(userProfile);
          print('✅ Local prediction engine successful');
        }
      }

      // Save prediction to Firestore
      await _savePredictionToFirestore(result);

      return result;
    } catch (e) {
      print('❌ All prediction methods failed: $e');
      throw Exception('Unable to generate career predictions: $e');
    }
  }

  // Method 1: Firebase Functions
  Future<CareerPredictionResult> _predictWithFirebaseFunctions(UserProfileData userProfile) async {
    try {
      final callable = _functions.httpsCallable(
        'predictCareerWithAutoML',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 45),
        ),
      );

      final response = await callable.call({
        'userInput': userProfile.toMap(),
        'includeAnalysis': true,
        'userId': _auth.currentUser!.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return CareerPredictionResult.fromMap(data);
      } else {
        throw Exception('Functions returned error: ${data['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Firebase Functions error: $e');
      rethrow;
    }
  }

  // Method 2: Direct HTTP API
  // Replace YOUR_ENDPOINT_ID with actual endpoint from Google Console
Future<CareerPredictionResult> _predictWithDirectAPI(UserProfileData userProfile) async {
  const String projectId = 'ai-life-navigator-27187';
  const String location = 'us-central1';
  const String endpointId = '8199257219930259456 '; // Get from Google Console
  
  final apiUrl = 'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/endpoints/$endpointId:predict';
  
  final response = await http.post(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${await _auth.currentUser!.getIdToken()}'
    },
    body: json.encode({
      'instances': [userProfile.toVertexAIFormat()]
    }),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return _parseVertexAIResponse(data);
  }
  throw Exception('API error: ${response.statusCode}');
}
  // Future<CareerPredictionResult> _predictWithDirectAPI(UserProfileData userProfile) async {
  //   try {
  //     // This would be your custom API endpoint
  //     const apiUrl = 'https://your-api-endpoint.com/predict'; // Replace with actual URL
      
  //     final response = await http.post(
  //       Uri.parse(apiUrl),
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Bearer ${await _auth.currentUser!.getIdToken()}'
  //       },
  //       body: json.encode({
  //         'userInput': userProfile.toMap(),
  //         'includeAnalysis': true,
  //       }),
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       return CareerPredictionResult.fromMap(data);
  //     } else {
  //       throw Exception('API returned ${response.statusCode}: ${response.body}');
  //     }
  //   } catch (e) {
  //     print('Direct API error: $e');
  //     rethrow;
  //   }
  // }

  // Parse Vertex AI API response to CareerPredictionResult
  CareerPredictionResult _parseVertexAIResponse(Map<String, dynamic> data) {
    // This assumes Vertex AI returns a structure with 'predictions' as a list of maps
    // and possibly other metadata. Adjust field names as needed.
    final predictions = (data['predictions'] as List? ?? [])
        .map((p) => CareerPrediction(
              career: p['career'] ?? '',
              confidence: (p['confidence'] ?? 0).toDouble(),
              reasoning: p['reasoning'] ?? '',
              skillsRequired: List<String>.from(p['skillsRequired'] ?? []),
              suggestedCourses: List<String>.from(p['suggestedCourses'] ?? []),
              salaryRange: (p['salaryRange'] ?? 0).toDouble(),
              industryGrowth: (p['industryGrowth'] ?? 0).toDouble(),
              matchScore: (p['matchScore'] ?? 0).toDouble(),
              keyStrengths: List<String>.from(p['keyStrengths'] ?? []),
              developmentAreas: List<String>.from(p['developmentAreas'] ?? []),
            ))
        .toList();

    return CareerPredictionResult(
      id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      success: data['success'] ?? true,
      predictions: predictions,
      explanation: data['explanation'] ?? '',
      timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      userInput: data['userInput'] != null
          ? UserProfileData(
              skills: Map<String, double>.from(data['userInput']['skills'] ?? {}),
              interests: Map<String, double>.from(data['userInput']['interests'] ?? {}),
              education: data['userInput']['education'] ?? '',
              experienceLevel: data['userInput']['experienceLevel'] ?? '',
              personalityTraits: Map<String, double>.from(data['userInput']['personalityTraits'] ?? {}),
              careerPreferences: Map<String, double>.from(data['userInput']['careerPreferences'] ?? {}),
            )
          : UserProfileData(
              skills: {},
              interests: {},
              education: '',
              experienceLevel: '',
              personalityTraits: {},
              careerPreferences: {},
            ),
      analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
      insights: List<String>.from(data['insights'] ?? []),
      method: data['method'] ?? 'vertex-ai',
    );
  }

  // Method 3: Enhanced Local Engine with ML-like features
  Future<CareerPredictionResult> _predictWithEnhancedLocalEngine(UserProfileData userProfile) async {
    try {
      print('🔧 Using enhanced local prediction engine');
      
      // Get career database
      final careers = _getEnhancedCareerDatabase();
      final predictions = <CareerPrediction>[];
      
      // Calculate scores for each career
      for (final career in careers) {
        final score = _calculateAdvancedCareerScore(career, userProfile);
        
        if (score > 40) { // Lower threshold for more options
          predictions.add(CareerPrediction(
            career: career['name'],
            confidence: score.toDouble(),
            reasoning: _generateAdvancedReasoning(career, userProfile, score.toDouble()),
            skillsRequired: List<String>.from(career['requiredSkills']),
            suggestedCourses: List<String>.from(career['suggestedCourses']),
            salaryRange: career['salaryRange'].toDouble(),
            industryGrowth: career['industryGrowth'],
            matchScore: score.toDouble(),
            keyStrengths: _identifyKeyStrengths(career, userProfile),
            developmentAreas: _identifyDevelopmentAreas(career, userProfile),
          ));
        }
      }
      
      // Sort by confidence
      predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      
      // Generate analytics
      final analytics = _generateLocalAnalytics(userProfile, predictions);
      final insights = _generateLocalInsights(userProfile, predictions);
      
      return CareerPredictionResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        success: true,
        predictions: predictions.take(12).toList(),
        explanation: _generatePersonalizedExplanation(userProfile, predictions),
        timestamp: DateTime.now(),
        userInput: userProfile,
        analytics: analytics,
        insights: insights,
        method: 'enhanced-local',
      );
    } catch (e) {
      print('Local engine error: $e');
      rethrow;
    }
  }

  // Enhanced career scoring algorithm
  int _calculateAdvancedCareerScore(Map<String, dynamic> career, UserProfileData userProfile) {
    double score = 50.0; // Base score
    
    // 1. Skill matching with weighted importance
    final userSkills = userProfile.skills;
    final careerSkills = List<String>.from(career['matchingSkills'] ?? []);
    final requiredSkills = List<String>.from(career['requiredSkills'] ?? []);
    
    double skillScore = 0;
    int matchedSkills = 0;
    
    for (final skill in careerSkills) {
      if (userSkills.containsKey(skill)) {
        final userRating = userSkills[skill]!;
        final weight = requiredSkills.contains(skill) ? 2.0 : 1.0;
        skillScore += userRating * weight;
        matchedSkills++;
      }
    }
    
    if (matchedSkills > 0) {
      score += (skillScore / matchedSkills) * 3; // Max 30 points
    }
    
    // 2. Interest alignment
    final userInterests = userProfile.interests;
    final careerInterests = List<String>.from(career['matchingInterests'] ?? []);
    
    double interestScore = 0;
    int matchedInterests = 0;
    
    for (final interest in careerInterests) {
      if (userInterests.containsKey(interest)) {
        interestScore += userInterests[interest]!;
        matchedInterests++;
      }
    }
    
    if (matchedInterests > 0) {
      score += (interestScore / matchedInterests) * 2; // Max 20 points
    }
    
    // 3. Education alignment
    final userEducation = userProfile.education;
    final careerEducation = List<String>.from(career['requiredEducation'] ?? []);
    
    for (final education in careerEducation) {
      if (userEducation.toLowerCase().contains(education.toLowerCase())) {
        score += 10; // Education match bonus
        break;
      }
    }
    
    // 4. Experience level matching
    final userExperience = userProfile.experienceLevel;
    final careerExperience = career['experienceLevel'] ?? 'mid';
    
    if (userExperience == careerExperience) {
      score += 8; // Perfect experience match
    } else if (_isExperienceCompatible(userExperience, careerExperience)) {
      score += 4; // Compatible experience
    }
    
    // 5. Personality traits alignment
    final userPersonality = userProfile.personalityTraits;
    final careerPersonality = Map<String, double>.from(career['personalityTraits'] ?? {});
    
    double personalityScore = 0;
    int traitCount = 0;
    
    for (final trait in careerPersonality.keys) {
      if (userPersonality.containsKey(trait)) {
        final difference = (userPersonality[trait]! - careerPersonality[trait]!).abs();
        personalityScore += (5 - difference); // Closer values = higher score
        traitCount++;
      }
    }
    
    if (traitCount > 0) {
      score += (personalityScore / traitCount) * 2; // Max 10 points
    }
    
    // 6. Career preferences
    final userPreferences = userProfile.careerPreferences;
    final careerAttributes = Map<String, dynamic>.from(career['attributes'] ?? {});
    
    // Work-life balance
    if (userPreferences.containsKey('workLifeBalance') && 
        careerAttributes.containsKey('workLifeBalance')) {
      final userPref = userPreferences['workLifeBalance']!;
      final careerRating = careerAttributes['workLifeBalance']! as double;
      score += (5 - (userPref - careerRating).abs()); // Max 5 points
    }
    
    // Travel requirements
    if (userPreferences.containsKey('travelRequirement') && 
        careerAttributes.containsKey('travelRequirement')) {
      final userPref = userPreferences['travelRequirement']!;
      final careerRating = careerAttributes['travelRequirement']! as double;
      score += (5 - (userPref - careerRating).abs()); // Max 5 points
    }
    
    // Remote work possibility
    if (userPreferences.containsKey('remoteWork') && 
        careerAttributes.containsKey('remoteWork')) {
      final userPref = userPreferences['remoteWork']!;
      final careerRating = careerAttributes['remoteWork']! as double;
      score += (5 - (userPref - careerRating).abs()); // Max 5 points
    }
    
    return score.clamp(0, 100).toInt();
  }

  // Check if experience levels are compatible
  bool _isExperienceCompatible(String userLevel, String careerLevel) {
    final levels = ['entry', 'junior', 'mid', 'senior', 'expert'];
    final userIndex = levels.indexOf(userLevel);
    final careerIndex = levels.indexOf(careerLevel);
    
    if (userIndex == -1 || careerIndex == -1) return false;
    
    // Allow one level difference
    return (userIndex - careerIndex).abs() <= 1;
  }

  // Generate advanced reasoning
  String _generateAdvancedReasoning(Map<String, dynamic> career, UserProfileData userProfile, double score) {
    final reasons = <String>[];
    
    // Skill matches
    final userSkills = userProfile.skills;
    final careerSkills = List<String>.from(career['matchingSkills'] ?? []);
    final matchedSkills = careerSkills.where((skill) => userSkills.containsKey(skill)).toList();
    
    if (matchedSkills.isNotEmpty) {
      reasons.add('Strong skill alignment in ${matchedSkills.take(3).join(', ')}');
    }
    
    // Interest matches
    final userInterests = userProfile.interests;
    final careerInterests = List<String>.from(career['matchingInterests'] ?? []);
    final matchedInterests = careerInterests.where((interest) => userInterests.containsKey(interest)).toList();
    
    if (matchedInterests.isNotEmpty) {
      reasons.add('High interest compatibility in ${matchedInterests.take(2).join(', ')}');
    }
    
    // Experience level
    if (userProfile.experienceLevel == career['experienceLevel']) {
      reasons.add('Perfect experience level match');
    }
    
    // Growth potential
    final industryGrowth = career['industryGrowth'];
    if (industryGrowth != null && industryGrowth > 0.05) {
      reasons.add('Strong industry growth potential (${(industryGrowth * 100).toStringAsFixed(1)}%)');
    }
    
    return '${reasons.join('. ')}.';
  }

  // Identify key strengths
  List<String> _identifyKeyStrengths(Map<String, dynamic> career, UserProfileData userProfile) {
    final strengths = <String>[];
    
    final userSkills = userProfile.skills;
    final careerSkills = List<String>.from(career['matchingSkills'] ?? []);
    
    for (final skill in careerSkills) {
      if (userSkills.containsKey(skill) && userSkills[skill]! >= 4) {
        strengths.add(skill);
      }
    }
    
    return strengths.take(5).toList();
  }

  // Identify development areas
  List<String> _identifyDevelopmentAreas(Map<String, dynamic> career, UserProfileData userProfile) {
    final areas = <String>[];
    
    final userSkills = userProfile.skills;
    final requiredSkills = List<String>.from(career['requiredSkills'] ?? []);
    
    for (final skill in requiredSkills) {
      if (!userSkills.containsKey(skill) || userSkills[skill]! < 3) {
        areas.add(skill);
      }
    }
    
    return areas.take(3).toList();
  }

  // Generate local analytics
  Map<String, dynamic> _generateLocalAnalytics(UserProfileData userProfile, List<CareerPrediction> predictions) {
    final analytics = <String, dynamic>{};
    
    // Top skills
    final skillFrequency = <String, int>{};
    for (final prediction in predictions) {
      for (final skill in prediction.skillsRequired) {
        skillFrequency[skill] = (skillFrequency[skill] ?? 0) + 1;
      }
    }
    
    final topSkills = skillFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    analytics['topSkills'] = topSkills.take(10).map((e) => e.key).toList();
    
    // Average salary range
    if (predictions.isNotEmpty) {
      final avgSalary = predictions.map((p) => p.salaryRange).reduce((a, b) => a + b) / predictions.length;
      analytics['averageSalaryRange'] = avgSalary;
    }
    
    // Industry distribution
    final industries = <String, int>{};
    for (final prediction in predictions) {
      // Extract industry from career name (simplified)
      final industry = _extractIndustry(prediction.career);
      industries[industry] = (industries[industry] ?? 0) + 1;
    }
    
    analytics['industryDistribution'] = industries;
    
    return analytics;
  }

  // Generate local insights
  List<String> _generateLocalInsights(UserProfileData userProfile, List<CareerPrediction> predictions) {
    final insights = <String>[];
    
    if (predictions.isEmpty) {
      insights.add('Consider broadening your skill set to unlock more career opportunities.');
      return insights;
    }
    
    // Top career insight
    final topCareer = predictions.first;
    insights.add('Your top career match is ${topCareer.career} with ${topCareer.confidence.toStringAsFixed(1)}% confidence.');
    
    // Skill gap analysis
    final allRequiredSkills = <String>{};
    for (final prediction in predictions.take(5)) {
      allRequiredSkills.addAll(prediction.skillsRequired);
    }
    
    final userSkills = userProfile.skills.keys.toSet();
    final missingSkills = allRequiredSkills.difference(userSkills);
    
    if (missingSkills.isNotEmpty) {
      insights.add('Consider developing skills in ${missingSkills.take(3).join(', ')} to strengthen your career prospects.');
    }
    
    // Salary insight
    if (predictions.isNotEmpty) {
      final avgSalary = predictions.map((p) => p.salaryRange).reduce((a, b) => a + b) / predictions.length;
      insights.add('Your career matches show an average salary potential of \$${avgSalary.toStringAsFixed(0)}k.');
    }
    
    return insights;
  }

  // Extract industry from career name (simplified)
  String _extractIndustry(String careerName) {
    final techKeywords = ['developer', 'engineer', 'programmer', 'architect', 'analyst'];
    final healthKeywords = ['doctor', 'nurse', 'therapist', 'medical', 'health'];
    final businessKeywords = ['manager', 'consultant', 'analyst', 'executive', 'marketing'];
    
    final lowerCareer = careerName.toLowerCase();
    
    if (techKeywords.any((keyword) => lowerCareer.contains(keyword))) {
      return 'Technology';
    } else if (healthKeywords.any((keyword) => lowerCareer.contains(keyword))) {
      return 'Healthcare';
    } else if (businessKeywords.any((keyword) => lowerCareer.contains(keyword))) {
      return 'Business';
    }
    
    return 'Other';
  }

  // Generate personalized explanation
  String _generatePersonalizedExplanation(UserProfileData userProfile, List<CareerPrediction> predictions) {
    if (predictions.isEmpty) {
      return 'Based on your profile, we recommend exploring additional skills and interests to discover suitable career paths.';
    }
    
    final topPrediction = predictions.first;
    return 'Based on your skills in ${userProfile.skills.keys.take(3).join(', ')} and interests in ${userProfile.interests.keys.take(2).join(', ')}, we identified ${predictions.length} potential career matches. Your top recommendation is ${topPrediction.career} due to strong alignment with your profile.';
  }

  // Save prediction to Firestore
  Future<void> _savePredictionToFirestore(CareerPredictionResult result) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('career_predictions')
            .doc(result.id)
            .set(result.toMap());
      }
    } catch (e) {
      print('Error saving prediction to Firestore: $e');
      // Don't throw here, as this is not critical for the user
    }
  }

  // Enhanced career database
  List<Map<String, dynamic>> _getEnhancedCareerDatabase() {
    return [
      {
        'name': 'Software Engineer',
        'matchingSkills': ['programming', 'problem-solving', 'algorithms', 'debugging'],
        'requiredSkills': ['programming', 'problem-solving', 'algorithms'],
        'matchingInterests': ['technology', 'coding', 'innovation'],
        'requiredEducation': ['computer science', 'engineering', 'mathematics'],
        'experienceLevel': 'mid',
        'salaryRange': 95,
        'industryGrowth': 0.13,
        'suggestedCourses': ['Advanced Programming', 'System Design', 'Data Structures'],
        'personalityTraits': {'analytical': 4.5, 'creative': 3.5, 'detail-oriented': 4.0},
        'attributes': {
          'workLifeBalance': 3.5,
          'travelRequirement': 2.0,
          'remoteWork': 4.5,
        }
      },
      {
        'name': 'Data Scientist',
        'matchingSkills': ['statistics', 'programming', 'machine-learning', 'data-analysis'],
        'requiredSkills': ['statistics', 'programming', 'data-analysis'],
        'matchingInterests': ['data', 'research', 'analytics', 'mathematics'],
        'requiredEducation': ['statistics', 'mathematics', 'computer science'],
        'experienceLevel': 'mid',
        'salaryRange': 110,
        'industryGrowth': 0.16,
        'suggestedCourses': ['Machine Learning', 'Statistical Analysis', 'Big Data'],
        'personalityTraits': {'analytical': 5.0, 'creative': 3.0, 'detail-oriented': 4.5},
        'attributes': {
          'workLifeBalance': 3.0,
          'travelRequirement': 2.5,
          'remoteWork': 4.0,
        }
      },
      {
        'name': 'Product Manager',
        'matchingSkills': ['leadership', 'communication', 'strategy', 'project-management'],
        'requiredSkills': ['leadership', 'communication', 'strategy'],
        'matchingInterests': ['business', 'technology', 'innovation', 'leadership'],
        'requiredEducation': ['business', 'marketing', 'engineering'],
        'experienceLevel': 'senior',
        'salaryRange': 130,
        'industryGrowth': 0.09,
        'suggestedCourses': ['Product Strategy', 'Agile Management', 'User Experience'],
        'personalityTraits': {'leadership': 4.5, 'communication': 4.5, 'analytical': 4.0},
        'attributes': {
          'workLifeBalance': 2.5,
          'travelRequirement': 3.0,
          'remoteWork': 3.5,
        }
      },
      {
        'name': 'UX Designer',
        'matchingSkills': ['design', 'user-research', 'prototyping', 'creativity'],
        'requiredSkills': ['design', 'user-research', 'prototyping'],
        'matchingInterests': ['design', 'technology', 'psychology', 'creativity'],
        'requiredEducation': ['design', 'psychology', 'human-computer interaction'],
        'experienceLevel': 'mid',
        'salaryRange': 85,
        'industryGrowth': 0.08,
        'suggestedCourses': ['User Research', 'Design Thinking', 'Prototyping'],
        'personalityTraits': {'creative': 4.5, 'empathetic': 4.0, 'detail-oriented': 4.0},
        'attributes': {
          'workLifeBalance': 4.0,
          'travelRequirement': 2.0,
          'remoteWork': 4.0,
        }
      },
      {
        'name': 'Digital Marketing Manager',
        'matchingSkills': ['marketing', 'analytics', 'communication', 'creativity'],
        'requiredSkills': ['marketing', 'analytics', 'communication'],
        'matchingInterests': ['marketing', 'technology', 'social-media', 'creativity'],
        'requiredEducation': ['marketing', 'business', 'communications'],
        'experienceLevel': 'mid',
        'salaryRange': 75,
        'industryGrowth': 0.06,
        'suggestedCourses': ['Digital Marketing', 'SEO/SEM', 'Social Media Strategy'],
        'personalityTraits': {'creative': 4.0, 'communication': 4.5, 'analytical': 3.5},
        'attributes': {
          'workLifeBalance': 3.5,
          'travelRequirement': 2.5,
          'remoteWork': 4.5,
        }
      },
      // Add more careers as needed
    ];
  }
}

// Data models
class UserProfileData {
  final Map<String, double> skills;
  final Map<String, double> interests;
  final String education;
  final String experienceLevel;
  final Map<String, double> personalityTraits;
  final Map<String, double> careerPreferences;

  UserProfileData({
    required this.skills,
    required this.interests,
    required this.education,
    required this.experienceLevel,
    required this.personalityTraits,
    required this.careerPreferences,
  });

  Map<String, dynamic> toMap() {
    return {
      'skills': skills,
      'interests': interests,
      'education': education,
      'experienceLevel': experienceLevel,
      'personalityTraits': personalityTraits,
      'careerPreferences': careerPreferences,
    };
  }

  // Add this method for Vertex AI format
  Map<String, dynamic> toVertexAIFormat() {
    return {
      'skills': skills,
      'interests': interests,
      'education': education,
      'experienceLevel': experienceLevel,
      'personalityTraits': personalityTraits,
      'careerPreferences': careerPreferences,
    };
  }
}

class CareerPrediction {
  final String career;
  final double confidence;
  final String reasoning;
  final List<String> skillsRequired;
  final List<String> suggestedCourses;
  final double salaryRange;
  final double industryGrowth;
  final double matchScore;
  final List<String> keyStrengths;
  final List<String> developmentAreas;

  CareerPrediction({
    required this.career,
    required this.confidence,
    required this.reasoning,
    required this.skillsRequired,
    required this.suggestedCourses,
    required this.salaryRange,
    required this.industryGrowth,
    required this.matchScore,
    required this.keyStrengths,
    required this.developmentAreas,
  });

  Map<String, dynamic> toMap() {
    return {
      'career': career,
      'confidence': confidence,
      'reasoning': reasoning,
      'skillsRequired': skillsRequired,
      'suggestedCourses': suggestedCourses,
      'salaryRange': salaryRange,
      'industryGrowth': industryGrowth,
      'matchScore': matchScore,
      'keyStrengths': keyStrengths,
      'developmentAreas': developmentAreas,
    };
  }
}

class CareerPredictionResult {
  final String id;
  final bool success;
  final List<CareerPrediction> predictions;
  final String explanation;
  final DateTime timestamp;
  final UserProfileData userInput;
  final Map<String, dynamic> analytics;
  final List<String> insights;
  final String method;

  CareerPredictionResult({
    required this.id,
    required this.success,
    required this.predictions,
    required this.explanation,
    required this.timestamp,
    required this.userInput,
    required this.analytics,
    required this.insights,
    required this.method,
  });

  factory CareerPredictionResult.fromMap(Map<String, dynamic> map) {
    return CareerPredictionResult(
      id: map['id'] ?? '',
      success: map['success'] ?? false,
      predictions: (map['predictions'] as List?)
          ?.map((p) => CareerPrediction(
                career: p['career'] ?? '',
                confidence: (p['confidence'] ?? 0).toDouble(),
                reasoning: p['reasoning'] ?? '',
                skillsRequired: List<String>.from(p['skillsRequired'] ?? []),
                suggestedCourses: List<String>.from(p['suggestedCourses'] ?? []),
                salaryRange: (p['salaryRange'] ?? 0).toDouble(),
                industryGrowth: (p['industryGrowth'] ?? 0).toDouble(),
                matchScore: (p['matchScore'] ?? 0).toDouble(),
                keyStrengths: List<String>.from(p['keyStrengths'] ?? []),
                developmentAreas: List<String>.from(p['developmentAreas'] ?? []),
              ))
          .toList() ?? [],
      explanation: map['explanation'] ?? '',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      userInput: UserProfileData(
        skills: Map<String, double>.from(map['userInput']['skills'] ?? {}),
        interests: Map<String, double>.from(map['userInput']['interests'] ?? {}),
        education: map['userInput']['education'] ?? '',
        experienceLevel: map['userInput']['experienceLevel'] ?? '',
        personalityTraits: Map<String, double>.from(map['userInput']['personalityTraits'] ?? {}),
        careerPreferences: Map<String, double>.from(map['userInput']['careerPreferences'] ?? {}),
      ),
      analytics: Map<String, dynamic>.from(map['analytics'] ?? {}),
      insights: List<String>.from(map['insights'] ?? []),
      method: map['method'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'success': success,
      'predictions': predictions.map((p) => p.toMap()).toList(),
      'explanation': explanation,
      'timestamp': timestamp.toIso8601String(),
      'userInput': userInput.toMap(),
      'analytics': analytics,
      'insights': insights,
      'method': method,
    };
  }
}