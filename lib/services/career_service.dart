// import 'dart:convert';
// import 'package:cloud_functions/cloud_functions.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;

// class CareerPredictionService {
//   final FirebaseFunctions _functions = FirebaseFunctions.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;

//   // Configure Firebase Functions for web
//   static void initialize() {
//     FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
//   }

//   // Enhanced career prediction with comprehensive fallback
//   Future<CareerPredictionResult> predictCareer(UserProfileData userProfile) async {
//     try {
//       // Ensure user is authenticated
//       final user = _auth.currentUser;
//       if (user == null) {
//         throw Exception('User must be authenticated to get predictions');
//       }

//       print('Starting career prediction for user: ${user.uid}');

//       // Try multiple prediction methods in order
//       CareerPredictionResult result;

//       try {
//         // Method 1: Firebase Functions + AutoML
//         result = await _predictWithFirebaseFunctions(userProfile);
//         print('✅ Firebase Functions prediction successful');
//       } catch (e) {
//         print('⚠️ Firebase Functions failed: $e');
//         try {
//           // Method 2: Direct HTTP API call
//           result = await _predictWithDirectAPI(userProfile);
//           print('✅ Direct API prediction successful');
//         } catch (e2) {
//           print('⚠️ Direct API failed: $e2');
//           // Method 3: Enhanced local prediction
//           result = await _predictWithEnhancedLocalEngine(userProfile);
//           print('✅ Local prediction engine successful');
//         }
//       }

//       // Save prediction to Firestore
//       await _savePredictionToFirestore(result);

//       return result;
//     } catch (e) {
//       print('❌ All prediction methods failed: $e');
//       throw Exception('Unable to generate career predictions: $e');
//     }
//   }

//   // Method 1: Firebase Functions
//   Future<CareerPredictionResult> _predictWithFirebaseFunctions(UserProfileData userProfile) async {
//     try {
//       final callable = _functions.httpsCallable(
//         'predictCareerWithAutoML',
//         options: HttpsCallableOptions(
//           timeout: const Duration(seconds: 45),
//         ),
//       );

//       final response = await callable.call({
//         'userInput': userProfile.toMap(),
//         'includeAnalysis': true,
//         'userId': _auth.currentUser!.uid,
//         'timestamp': DateTime.now().toIso8601String(),
//       });

//       final data = response.data as Map<String, dynamic>;
      
//       if (data['success'] == true) {
//         return CareerPredictionResult.fromMap(data);
//       } else {
//         throw Exception('Functions returned error: ${data['error'] ?? 'Unknown error'}');
//       }
//     } catch (e) {
//       print('Firebase Functions error: $e');
//       rethrow;
//     }
//   }

//   // Method 2: Direct HTTP API
//   // Replace YOUR_ENDPOINT_ID with actual endpoint from Google Console
// Future<CareerPredictionResult> _predictWithDirectAPI(UserProfileData userProfile) async {
//   const String projectId = 'ai-life-navigator-27187';
//   const String location = 'us-central1';
//   const String endpointId = '8199257219930259456 '; // Get from Google Console
  
//   final apiUrl = 'https://$location-aiplatform.googleapis.com/v1/projects/$projectId/locations/$location/endpoints/$endpointId:predict';
  
//   final response = await http.post(
//     Uri.parse(apiUrl),
//     headers: {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer ${await _auth.currentUser!.getIdToken()}'
//     },
//     body: json.encode({
//       'instances': [userProfile.toVertexAIFormat()]
//     }),
//   );

//   if (response.statusCode == 200) {
//     final data = json.decode(response.body);
//     return _parseVertexAIResponse(data);
//   }
//   throw Exception('API error: ${response.statusCode}');
// }
//   // Future<CareerPredictionResult> _predictWithDirectAPI(UserProfileData userProfile) async {
//   //   try {
//   //     // This would be your custom API endpoint
//   //     const apiUrl = 'https://your-api-endpoint.com/predict'; // Replace with actual URL
      
//   //     final response = await http.post(
//   //       Uri.parse(apiUrl),
//   //       headers: {
//   //         'Content-Type': 'application/json',
//   //         'Authorization': 'Bearer ${await _auth.currentUser!.getIdToken()}'
//   //       },
//   //       body: json.encode({
//   //         'userInput': userProfile.toMap(),
//   //         'includeAnalysis': true,
//   //       }),
//   //     );

//   //     if (response.statusCode == 200) {
//   //       final data = json.decode(response.body);
//   //       return CareerPredictionResult.fromMap(data);
//   //     } else {
//   //       throw Exception('API returned ${response.statusCode}: ${response.body}');
//   //     }
//   //   } catch (e) {
//   //     print('Direct API error: $e');
//   //     rethrow;
//   //   }
//   // }

//   // Parse Vertex AI API response to CareerPredictionResult
//   CareerPredictionResult _parseVertexAIResponse(Map<String, dynamic> data) {
//     // This assumes Vertex AI returns a structure with 'predictions' as a list of maps
//     // and possibly other metadata. Adjust field names as needed.
//     final predictions = (data['predictions'] as List? ?? [])
//         .map((p) => CareerPrediction(
//               career: p['career'] ?? '',
//               confidence: (p['confidence'] ?? 0).toDouble(),
//               reasoning: p['reasoning'] ?? '',
//               skillsRequired: List<String>.from(p['skillsRequired'] ?? []),
//               suggestedCourses: List<String>.from(p['suggestedCourses'] ?? []),
//               salaryRange: (p['salaryRange'] ?? 0).toDouble(),
//               industryGrowth: (p['industryGrowth'] ?? 0).toDouble(),
//               matchScore: (p['matchScore'] ?? 0).toDouble(),
//               keyStrengths: List<String>.from(p['keyStrengths'] ?? []),
//               developmentAreas: List<String>.from(p['developmentAreas'] ?? []),
//             ))
//         .toList();

//     return CareerPredictionResult(
//       id: data['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
//       success: data['success'] ?? true,
//       predictions: predictions,
//       explanation: data['explanation'] ?? '',
//       timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
//       userInput: data['userInput'] != null
//           ? UserProfileData(
//               skills: Map<String, double>.from(data['userInput']['skills'] ?? {}),
//               interests: Map<String, double>.from(data['userInput']['interests'] ?? {}),
//               education: data['userInput']['education'] ?? '',
//               experienceLevel: data['userInput']['experienceLevel'] ?? '',
//               personalityTraits: Map<String, double>.from(data['userInput']['personalityTraits'] ?? {}),
//               careerPreferences: Map<String, double>.from(data['userInput']['careerPreferences'] ?? {}),
//             )
//           : UserProfileData(
//               skills: {},
//               interests: {},
//               education: '',
//               experienceLevel: '',
//               personalityTraits: {},
//               careerPreferences: {},
//             ),
//       analytics: Map<String, dynamic>.from(data['analytics'] ?? {}),
//       insights: List<String>.from(data['insights'] ?? []),
//       method: data['method'] ?? 'vertex-ai',
//     );
//   }

//   // Method 3: Enhanced Local Engine with ML-like features
//   Future<CareerPredictionResult> _predictWithEnhancedLocalEngine(UserProfileData userProfile) async {
//     try {
//       print('🔧 Using enhanced local prediction engine');
      
//       // Get career database
//       final careers = _getEnhancedCareerDatabase();
//       final predictions = <CareerPrediction>[];
      
//       // Calculate scores for each career
//       for (final career in careers) {
//         final score = _calculateAdvancedCareerScore(career, userProfile);
        
//         if (score > 40) { // Lower threshold for more options
//           predictions.add(CareerPrediction(
//             career: career['name'],
//             confidence: score.toDouble(),
//             reasoning: _generateAdvancedReasoning(career, userProfile, score.toDouble()),
//             skillsRequired: List<String>.from(career['requiredSkills']),
//             suggestedCourses: List<String>.from(career['suggestedCourses']),
//             salaryRange: career['salaryRange'].toDouble(),
//             industryGrowth: career['industryGrowth'],
//             matchScore: score.toDouble(),
//             keyStrengths: _identifyKeyStrengths(career, userProfile),
//             developmentAreas: _identifyDevelopmentAreas(career, userProfile),
//           ));
//         }
//       }
      
//       // Sort by confidence
//       predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
      
//       // Generate analytics
//       final analytics = _generateLocalAnalytics(userProfile, predictions);
//       final insights = _generateLocalInsights(userProfile, predictions);
      
//       return CareerPredictionResult(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         success: true,
//         predictions: predictions.take(12).toList(),
//         explanation: _generatePersonalizedExplanation(userProfile, predictions),
//         timestamp: DateTime.now(),
//         userInput: userProfile,
//         analytics: analytics,
//         insights: insights,
//         method: 'enhanced-local',
//       );
//     } catch (e) {
//       print('Local engine error: $e');
//       rethrow;
//     }
//   }

//   // Enhanced career scoring algorithm
//   int _calculateAdvancedCareerScore(Map<String, dynamic> career, UserProfileData userProfile) {
//     double score = 50.0; // Base score
    
//     // 1. Skill matching with weighted importance
//     final userSkills = userProfile.skills;
//     final careerSkills = List<String>.from(career['matchingSkills'] ?? []);
//     final requiredSkills = List<String>.from(career['requiredSkills'] ?? []);
    
//     double skillScore = 0;
//     int matchedSkills = 0;
    
//     for (final skill in careerSkills) {
//       if (userSkills.containsKey(skill)) {
//         final userRating = userSkills[skill]!;
//         final weight = requiredSkills.contains(skill) ? 2.0 : 1.0;
//         skillScore += userRating * weight;
//         matchedSkills++;
//       }
//     }
    
//     if (matchedSkills > 0) {
//       score += (skillScore / matchedSkills) * 3; // Max 30 points
//     }
    
//     // 2. Interest alignment
//     final userInterests = userProfile.interests;
//     final careerInterests = List<String>.from(career['matchingInterests'] ?? []);
    
//     double interestScore = 0;
//     int matchedInterests = 0;
    
//     for (final interest in careerInterests) {
//       if (userInterests.containsKey(interest)) {
//         interestScore += userInterests[interest]!;
//         matchedInterests++;
//       }
//     }
    
//     if (matchedInterests > 0) {
//       score += (interestScore / matchedInterests) * 2; // Max 20 points
//     }
    
//     // 3. Education alignment
//     final userEducation = userProfile.education;
//     final careerEducation = List<String>.from(career['requiredEducation'] ?? []);
    
//     for (final education in careerEducation) {
//       if (userEducation.toLowerCase().contains(education.toLowerCase())) {
//         score += 10; // Education match bonus
//         break;
//       }
//     }
    
//     // 4. Experience level matching
//     final userExperience = userProfile.experienceLevel;
//     final careerExperience = career['experienceLevel'] ?? 'mid';
    
//     if (userExperience == careerExperience) {
//       score += 8; // Perfect experience match
//     } else if (_isExperienceCompatible(userExperience, careerExperience)) {
//       score += 4; // Compatible experience
//     }
    
//     // 5. Personality traits alignment
//     final userPersonality = userProfile.personalityTraits;
//     final careerPersonality = Map<String, double>.from(career['personalityTraits'] ?? {});
    
//     double personalityScore = 0;
//     int traitCount = 0;
    
//     for (final trait in careerPersonality.keys) {
//       if (userPersonality.containsKey(trait)) {
//         final difference = (userPersonality[trait]! - careerPersonality[trait]!).abs();
//         personalityScore += (5 - difference); // Closer values = higher score
//         traitCount++;
//       }
//     }
    
//     if (traitCount > 0) {
//       score += (personalityScore / traitCount) * 2; // Max 10 points
//     }
    
//     // 6. Career preferences
//     final userPreferences = userProfile.careerPreferences;
//     final careerAttributes = Map<String, dynamic>.from(career['attributes'] ?? {});
    
//     // Work-life balance
//     if (userPreferences.containsKey('workLifeBalance') && 
//         careerAttributes.containsKey('workLifeBalance')) {
//       final userPref = userPreferences['workLifeBalance']!;
//       final careerRating = careerAttributes['workLifeBalance']! as double;
//       score += (5 - (userPref - careerRating).abs()); // Max 5 points
//     }
    
//     // Travel requirements
//     if (userPreferences.containsKey('travelRequirement') && 
//         careerAttributes.containsKey('travelRequirement')) {
//       final userPref = userPreferences['travelRequirement']!;
//       final careerRating = careerAttributes['travelRequirement']! as double;
//       score += (5 - (userPref - careerRating).abs()); // Max 5 points
//     }
    
//     // Remote work possibility
//     if (userPreferences.containsKey('remoteWork') && 
//         careerAttributes.containsKey('remoteWork')) {
//       final userPref = userPreferences['remoteWork']!;
//       final careerRating = careerAttributes['remoteWork']! as double;
//       score += (5 - (userPref - careerRating).abs()); // Max 5 points
//     }
    
//     return score.clamp(0, 100).toInt();
//   }

//   // Check if experience levels are compatible
//   bool _isExperienceCompatible(String userLevel, String careerLevel) {
//     final levels = ['entry', 'junior', 'mid', 'senior', 'expert'];
//     final userIndex = levels.indexOf(userLevel);
//     final careerIndex = levels.indexOf(careerLevel);
    
//     if (userIndex == -1 || careerIndex == -1) return false;
    
//     // Allow one level difference
//     return (userIndex - careerIndex).abs() <= 1;
//   }

//   // Generate advanced reasoning
//   String _generateAdvancedReasoning(Map<String, dynamic> career, UserProfileData userProfile, double score) {
//     final reasons = <String>[];
    
//     // Skill matches
//     final userSkills = userProfile.skills;
//     final careerSkills = List<String>.from(career['matchingSkills'] ?? []);
//     final matchedSkills = careerSkills.where((skill) => userSkills.containsKey(skill)).toList();
    
//     if (matchedSkills.isNotEmpty) {
//       reasons.add('Strong skill alignment in ${matchedSkills.take(3).join(', ')}');
//     }
    
//     // Interest matches
//     final userInterests = userProfile.interests;
//     final careerInterests = List<String>.from(career['matchingInterests'] ?? []);
//     final matchedInterests = careerInterests.where((interest) => userInterests.containsKey(interest)).toList();
    
//     if (matchedInterests.isNotEmpty) {
//       reasons.add('High interest compatibility in ${matchedInterests.take(2).join(', ')}');
//     }
    
//     // Experience level
//     if (userProfile.experienceLevel == career['experienceLevel']) {
//       reasons.add('Perfect experience level match');
//     }
    
//     // Growth potential
//     final industryGrowth = career['industryGrowth'];
//     if (industryGrowth != null && industryGrowth > 0.05) {
//       reasons.add('Strong industry growth potential (${(industryGrowth * 100).toStringAsFixed(1)}%)');
//     }
    
//     return '${reasons.join('. ')}.';
//   }

//   // Identify key strengths
//   List<String> _identifyKeyStrengths(Map<String, dynamic> career, UserProfileData userProfile) {
//     final strengths = <String>[];
    
//     final userSkills = userProfile.skills;
//     final careerSkills = List<String>.from(career['matchingSkills'] ?? []);
    
//     for (final skill in careerSkills) {
//       if (userSkills.containsKey(skill) && userSkills[skill]! >= 4) {
//         strengths.add(skill);
//       }
//     }
    
//     return strengths.take(5).toList();
//   }

//   // Identify development areas
//   List<String> _identifyDevelopmentAreas(Map<String, dynamic> career, UserProfileData userProfile) {
//     final areas = <String>[];
    
//     final userSkills = userProfile.skills;
//     final requiredSkills = List<String>.from(career['requiredSkills'] ?? []);
    
//     for (final skill in requiredSkills) {
//       if (!userSkills.containsKey(skill) || userSkills[skill]! < 3) {
//         areas.add(skill);
//       }
//     }
    
//     return areas.take(3).toList();
//   }

//   // Generate local analytics
//   Map<String, dynamic> _generateLocalAnalytics(UserProfileData userProfile, List<CareerPrediction> predictions) {
//     final analytics = <String, dynamic>{};
    
//     // Top skills
//     final skillFrequency = <String, int>{};
//     for (final prediction in predictions) {
//       for (final skill in prediction.skillsRequired) {
//         skillFrequency[skill] = (skillFrequency[skill] ?? 0) + 1;
//       }
//     }
    
//     final topSkills = skillFrequency.entries.toList()
//       ..sort((a, b) => b.value.compareTo(a.value));
    
//     analytics['topSkills'] = topSkills.take(10).map((e) => e.key).toList();
    
//     // Average salary range
//     if (predictions.isNotEmpty) {
//       final avgSalary = predictions.map((p) => p.salaryRange).reduce((a, b) => a + b) / predictions.length;
//       analytics['averageSalaryRange'] = avgSalary;
//     }
    
//     // Industry distribution
//     final industries = <String, int>{};
//     for (final prediction in predictions) {
//       // Extract industry from career name (simplified)
//       final industry = _extractIndustry(prediction.career);
//       industries[industry] = (industries[industry] ?? 0) + 1;
//     }
    
//     analytics['industryDistribution'] = industries;
    
//     return analytics;
//   }

//   // Generate local insights
//   List<String> _generateLocalInsights(UserProfileData userProfile, List<CareerPrediction> predictions) {
//     final insights = <String>[];
    
//     if (predictions.isEmpty) {
//       insights.add('Consider broadening your skill set to unlock more career opportunities.');
//       return insights;
//     }
    
//     // Top career insight
//     final topCareer = predictions.first;
//     insights.add('Your top career match is ${topCareer.career} with ${topCareer.confidence.toStringAsFixed(1)}% confidence.');
    
//     // Skill gap analysis
//     final allRequiredSkills = <String>{};
//     for (final prediction in predictions.take(5)) {
//       allRequiredSkills.addAll(prediction.skillsRequired);
//     }
    
//     final userSkills = userProfile.skills.keys.toSet();
//     final missingSkills = allRequiredSkills.difference(userSkills);
    
//     if (missingSkills.isNotEmpty) {
//       insights.add('Consider developing skills in ${missingSkills.take(3).join(', ')} to strengthen your career prospects.');
//     }
    
//     // Salary insight
//     if (predictions.isNotEmpty) {
//       final avgSalary = predictions.map((p) => p.salaryRange).reduce((a, b) => a + b) / predictions.length;
//       insights.add('Your career matches show an average salary potential of \$${avgSalary.toStringAsFixed(0)}k.');
//     }
    
//     return insights;
//   }

//   // Extract industry from career name (simplified)
//   String _extractIndustry(String careerName) {
//     final techKeywords = ['developer', 'engineer', 'programmer', 'architect', 'analyst'];
//     final healthKeywords = ['doctor', 'nurse', 'therapist', 'medical', 'health'];
//     final businessKeywords = ['manager', 'consultant', 'analyst', 'executive', 'marketing'];
    
//     final lowerCareer = careerName.toLowerCase();
    
//     if (techKeywords.any((keyword) => lowerCareer.contains(keyword))) {
//       return 'Technology';
//     } else if (healthKeywords.any((keyword) => lowerCareer.contains(keyword))) {
//       return 'Healthcare';
//     } else if (businessKeywords.any((keyword) => lowerCareer.contains(keyword))) {
//       return 'Business';
//     }
    
//     return 'Other';
//   }

//   // Generate personalized explanation
//   String _generatePersonalizedExplanation(UserProfileData userProfile, List<CareerPrediction> predictions) {
//     if (predictions.isEmpty) {
//       return 'Based on your profile, we recommend exploring additional skills and interests to discover suitable career paths.';
//     }
    
//     final topPrediction = predictions.first;
//     return 'Based on your skills in ${userProfile.skills.keys.take(3).join(', ')} and interests in ${userProfile.interests.keys.take(2).join(', ')}, we identified ${predictions.length} potential career matches. Your top recommendation is ${topPrediction.career} due to strong alignment with your profile.';
//   }

//   // Save prediction to Firestore
//   Future<void> _savePredictionToFirestore(CareerPredictionResult result) async {
//     try {
//       final user = _auth.currentUser;
//       if (user != null) {
//         await _firestore
//             .collection('users')
//             .doc(user.uid)
//             .collection('career_predictions')
//             .doc(result.id)
//             .set(result.toMap());
//       }
//     } catch (e) {
//       print('Error saving prediction to Firestore: $e');
//       // Don't throw here, as this is not critical for the user
//     }
//   }

//   // Enhanced career database
//   List<Map<String, dynamic>> _getEnhancedCareerDatabase() {
//     return [
//       {
//         'name': 'Software Engineer',
//         'matchingSkills': ['programming', 'problem-solving', 'algorithms', 'debugging'],
//         'requiredSkills': ['programming', 'problem-solving', 'algorithms'],
//         'matchingInterests': ['technology', 'coding', 'innovation'],
//         'requiredEducation': ['computer science', 'engineering', 'mathematics'],
//         'experienceLevel': 'mid',
//         'salaryRange': 95,
//         'industryGrowth': 0.13,
//         'suggestedCourses': ['Advanced Programming', 'System Design', 'Data Structures'],
//         'personalityTraits': {'analytical': 4.5, 'creative': 3.5, 'detail-oriented': 4.0},
//         'attributes': {
//           'workLifeBalance': 3.5,
//           'travelRequirement': 2.0,
//           'remoteWork': 4.5,
//         }
//       },
//       {
//         'name': 'Data Scientist',
//         'matchingSkills': ['statistics', 'programming', 'machine-learning', 'data-analysis'],
//         'requiredSkills': ['statistics', 'programming', 'data-analysis'],
//         'matchingInterests': ['data', 'research', 'analytics', 'mathematics'],
//         'requiredEducation': ['statistics', 'mathematics', 'computer science'],
//         'experienceLevel': 'mid',
//         'salaryRange': 110,
//         'industryGrowth': 0.16,
//         'suggestedCourses': ['Machine Learning', 'Statistical Analysis', 'Big Data'],
//         'personalityTraits': {'analytical': 5.0, 'creative': 3.0, 'detail-oriented': 4.5},
//         'attributes': {
//           'workLifeBalance': 3.0,
//           'travelRequirement': 2.5,
//           'remoteWork': 4.0,
//         }
//       },
//       {
//         'name': 'Product Manager',
//         'matchingSkills': ['leadership', 'communication', 'strategy', 'project-management'],
//         'requiredSkills': ['leadership', 'communication', 'strategy'],
//         'matchingInterests': ['business', 'technology', 'innovation', 'leadership'],
//         'requiredEducation': ['business', 'marketing', 'engineering'],
//         'experienceLevel': 'senior',
//         'salaryRange': 130,
//         'industryGrowth': 0.09,
//         'suggestedCourses': ['Product Strategy', 'Agile Management', 'User Experience'],
//         'personalityTraits': {'leadership': 4.5, 'communication': 4.5, 'analytical': 4.0},
//         'attributes': {
//           'workLifeBalance': 2.5,
//           'travelRequirement': 3.0,
//           'remoteWork': 3.5,
//         }
//       },
//       {
//         'name': 'UX Designer',
//         'matchingSkills': ['design', 'user-research', 'prototyping', 'creativity'],
//         'requiredSkills': ['design', 'user-research', 'prototyping'],
//         'matchingInterests': ['design', 'technology', 'psychology', 'creativity'],
//         'requiredEducation': ['design', 'psychology', 'human-computer interaction'],
//         'experienceLevel': 'mid',
//         'salaryRange': 85,
//         'industryGrowth': 0.08,
//         'suggestedCourses': ['User Research', 'Design Thinking', 'Prototyping'],
//         'personalityTraits': {'creative': 4.5, 'empathetic': 4.0, 'detail-oriented': 4.0},
//         'attributes': {
//           'workLifeBalance': 4.0,
//           'travelRequirement': 2.0,
//           'remoteWork': 4.0,
//         }
//       },
//       {
//         'name': 'Digital Marketing Manager',
//         'matchingSkills': ['marketing', 'analytics', 'communication', 'creativity'],
//         'requiredSkills': ['marketing', 'analytics', 'communication'],
//         'matchingInterests': ['marketing', 'technology', 'social-media', 'creativity'],
//         'requiredEducation': ['marketing', 'business', 'communications'],
//         'experienceLevel': 'mid',
//         'salaryRange': 75,
//         'industryGrowth': 0.06,
//         'suggestedCourses': ['Digital Marketing', 'SEO/SEM', 'Social Media Strategy'],
//         'personalityTraits': {'creative': 4.0, 'communication': 4.5, 'analytical': 3.5},
//         'attributes': {
//           'workLifeBalance': 3.5,
//           'travelRequirement': 2.5,
//           'remoteWork': 4.5,
//         }
//       },
//       // Add more careers as needed
//     ];
//   }
// }

// // Data models
// class UserProfileData {
//   final Map<String, double> skills;
//   final Map<String, double> interests;
//   final String education;
//   final String experienceLevel;
//   final Map<String, double> personalityTraits;
//   final Map<String, double> careerPreferences;

//   UserProfileData({
//     required this.skills,
//     required this.interests,
//     required this.education,
//     required this.experienceLevel,
//     required this.personalityTraits,
//     required this.careerPreferences,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'skills': skills,
//       'interests': interests,
//       'education': education,
//       'experienceLevel': experienceLevel,
//       'personalityTraits': personalityTraits,
//       'careerPreferences': careerPreferences,
//     };
//   }

//   // Add this method for Vertex AI format
//   Map<String, dynamic> toVertexAIFormat() {
//     return {
//       'skills': skills,
//       'interests': interests,
//       'education': education,
//       'experienceLevel': experienceLevel,
//       'personalityTraits': personalityTraits,
//       'careerPreferences': careerPreferences,
//     };
//   }
// }

// class CareerPrediction {
//   final String career;
//   final double confidence;
//   final String reasoning;
//   final List<String> skillsRequired;
//   final List<String> suggestedCourses;
//   final double salaryRange;
//   final double industryGrowth;
//   final double matchScore;
//   final List<String> keyStrengths;
//   final List<String> developmentAreas;

//   CareerPrediction({
//     required this.career,
//     required this.confidence,
//     required this.reasoning,
//     required this.skillsRequired,
//     required this.suggestedCourses,
//     required this.salaryRange,
//     required this.industryGrowth,
//     required this.matchScore,
//     required this.keyStrengths,
//     required this.developmentAreas,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'career': career,
//       'confidence': confidence,
//       'reasoning': reasoning,
//       'skillsRequired': skillsRequired,
//       'suggestedCourses': suggestedCourses,
//       'salaryRange': salaryRange,
//       'industryGrowth': industryGrowth,
//       'matchScore': matchScore,
//       'keyStrengths': keyStrengths,
//       'developmentAreas': developmentAreas,
//     };
//   }
// }

// class CareerPredictionResult {
//   final String id;
//   final bool success;
//   final List<CareerPrediction> predictions;
//   final String explanation;
//   final DateTime timestamp;
//   final UserProfileData userInput;
//   final Map<String, dynamic> analytics;
//   final List<String> insights;
//   final String method;

//   CareerPredictionResult({
//     required this.id,
//     required this.success,
//     required this.predictions,
//     required this.explanation,
//     required this.timestamp,
//     required this.userInput,
//     required this.analytics,
//     required this.insights,
//     required this.method,
//   });

//   factory CareerPredictionResult.fromMap(Map<String, dynamic> map) {
//     return CareerPredictionResult(
//       id: map['id'] ?? '',
//       success: map['success'] ?? false,
//       predictions: (map['predictions'] as List?)
//           ?.map((p) => CareerPrediction(
//                 career: p['career'] ?? '',
//                 confidence: (p['confidence'] ?? 0).toDouble(),
//                 reasoning: p['reasoning'] ?? '',
//                 skillsRequired: List<String>.from(p['skillsRequired'] ?? []),
//                 suggestedCourses: List<String>.from(p['suggestedCourses'] ?? []),
//                 salaryRange: (p['salaryRange'] ?? 0).toDouble(),
//                 industryGrowth: (p['industryGrowth'] ?? 0).toDouble(),
//                 matchScore: (p['matchScore'] ?? 0).toDouble(),
//                 keyStrengths: List<String>.from(p['keyStrengths'] ?? []),
//                 developmentAreas: List<String>.from(p['developmentAreas'] ?? []),
//               ))
//           .toList() ?? [],
//       explanation: map['explanation'] ?? '',
//       timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
//       userInput: UserProfileData(
//         skills: Map<String, double>.from(map['userInput']['skills'] ?? {}),
//         interests: Map<String, double>.from(map['userInput']['interests'] ?? {}),
//         education: map['userInput']['education'] ?? '',
//         experienceLevel: map['userInput']['experienceLevel'] ?? '',
//         personalityTraits: Map<String, double>.from(map['userInput']['personalityTraits'] ?? {}),
//         careerPreferences: Map<String, double>.from(map['userInput']['careerPreferences'] ?? {}),
//       ),
//       analytics: Map<String, dynamic>.from(map['analytics'] ?? {}),
//       insights: List<String>.from(map['insights'] ?? []),
//       method: map['method'] ?? 'unknown',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'success': success,
//       'predictions': predictions.map((p) => p.toMap()).toList(),
//       'explanation': explanation,
//       'timestamp': timestamp.toIso8601String(),
//       'userInput': userInput.toMap(),
//       'analytics': analytics,
//       'insights': insights,
//       'method': method,
//     };
//   }
// }
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  static const String PROJECT_ID = "ai-life-navigator-27187";
  static const String LOCATION = "us-central1";
  static const String ENDPOINT_ID = "8199257219930259456";
  static const String MODEL_ID = "1074270139337146368";
  
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
      "project_id": "ai-life-navigator-27187",
      "private_key_id": "9448015ce6f4863caa3a222891bc0671a0b25a01",  // ✅ Updated
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDJ2g4GYml9VdXB\nDcsgMaUs2Y6TddNTYTQAfAjYP2Kr7ImBQaKg9/7D/q6qrogRb7EAxgrmTCb+KDcr\n2D+3PB2yTXwN4ht5zEbX7P58WXOIN8wZHcxj4zZv1mvrI3T0VBSguLzPeo7H1NSy\nTw3XgEtVWxDL6Trmf1FFnoVbrOWs4+wG/gpGhf36hY+W0RGg0h3cJdtW3c3kMwT3\n7DmwS9GKxGkjWsQHO1XWSwXsWQ80ww41eLOB4bcXV1tnL/2S5OrR9jaXWnqvMBWE\nyDiP8kMszSbOD3zVbrpOvOoD8h8w3THik+0+TJNJtM0rHtvybQAjpvaZFHt6Q4/m\n22Da/me/AgMBAAECggEAAxBtSZhzHSwFa2UbTU08hN+JRBTeuIQkz1XjSB1AJBQa\nbsnd0jL1tgVWRAK04rZuXMrGB1NKIyIzaWRBiNalxD2nzoBLcNC5shGfekBmfH1G\nRs0u1bHeNY4675JJy6W3el+Ql9KHOOct/8ZHtKRHEROgEHui9EgHk096yoTeJ8X7\n3DO8B4cnBRtGcQR/t0A8i8FFv232MfZJr03FTV14YO5ean0jhSW2H9QGXD0Z4Usb\nevwuv9lzN5xMHgpn3+DaWXULjaXruGoaG1mMpSgocd5H2zcpJAEXRqZdF+553DtH\nqfkC4wHkCfUxZmUQCFhgv3GJZRjh7V+caPvBd7uK6QKBgQD6m9WvuZ6XSi7ESLsi\nIsXVy7qfzeNdKraMhnHtGjBkAKtw4OiiyMw2PZweqyPDK/FKhsVopQGHn48eCv/5\nzxmhxL5/wBQAdalzNZTKaZxNsokaPs9x2fyCQ99Xr7hhkxmMTQLrinamVGB9k1lI\npE9XsUTHI421dSlCe1/tuew3OQKBgQDOMbQJtodWRKCKxpuXX0vUcaMjEjC2WC5G\nLividZdE/UGKsTLNkxvn5AexMU6i5I4Id8hVE2yDMhZuHcRo+wCNzg70c+KOiI8v\n0u11qLWfVdqtCaTx0B0rVWx9A74lskkA6SQLQut+x1Bx3/Wrh/4z8O0QvKHz3doD\nijtv8bxetwKBgCI7Vx0Bxd/0ih7VsHohNdTWV0+s1/nJ89WOJ9GzWhjO3pw0nJJf\ny0U9dS3bQq9OOU9syVpZ77OO4AXCiuScnWuzbDIXEqRdbiAGmaRseKVEVeX33m42\n0H8atk9L+WuapEq92kBCUaK2s9dzYSbDCvN3i2WIPbsjndcu8xON6e5BAoGBAIU+\nHSeBqicXJd9HxFenHytjW5ZYNN5AUXbMc1NdxaixN19WbovlmkzZUBcy06vzoczb\nCrvfV2nYPiJeXgOw34TDOWrCUA7nNBAlb4luwh76rdrPtqUEZTUReI+4kXFuqjpK\nbh5Q2jkMt3E+1lRIBv6tm6QLIWSjYjSTaSFHxwA1AoGBAO6HAA9vtzS894DNA5w6\nQue8fa1gxV5ZMX0HQHJmK9aiJ9DHgCv4UHFgcHJBmlXOHH08FF+QsWhcr3OAQilW\n5+yH8dIeQ2g0ilyp9U9GMRoHuWnlR6qcEzn8AQZTFVS7EwQQwQxyeskIocbntD77\nBubomWHDUKSSYAbgyyo3XB6G\n-----END PRIVATE KEY-----\n",  // ✅ Updated
      "client_email": "ai-life-navigator-27187@appspot.gserviceaccount.com",
      "client_id": "111278927099144047711",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/ai-life-navigator-27187%40appspot.gserviceaccount.com",
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
