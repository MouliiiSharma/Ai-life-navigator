import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/gemini_service.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.messageType,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'messageType': messageType,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] ?? '',
      isUser: map['isUser'] ?? false,
      timestamp: DateTime.parse(map['timestamp']),
      messageType: map['messageType'],
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EnhancedGeminiService _geminiService = EnhancedGeminiService();

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save complete chat session with user answers
  Future<void> saveChatSession({
    required String userId,
    required List<ChatMessage> messages,
    required Map<String, String> userAnswers,
    required DateTime timestamp,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .add({
        'messages': messages.map((msg) => msg.toMap()).toList(),
        'userAnswers': userAnswers,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionType': 'career_guidance',
      });
    } catch (e) {
      print('Error saving chat session: $e');
      throw e;
    }
  }

  // Get latest chat history
  Future<Map<String, dynamic>?> getChatHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('chat_sessions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return {
          'messages': (data['messages'] as List)
              .map((msg) => ChatMessage.fromMap(msg))
              .toList(),
          'userAnswers': Map<String, String>.from(data['userAnswers'] ?? {}),
        };
      }
      return null;
    } catch (e) {
      print('Error getting chat history: $e');
      return null;
    }
  }

  // Save LinkedIn profile analysis
  Future<void> saveLinkedInAnalysis({
    required String userId,
    required Map<String, dynamic> profileData,
    required String analysisText,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('linkedin_analysis')
          .add({
        'profileData': profileData,
        'analysisText': analysisText,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving LinkedIn analysis: $e');
      throw e;
    }
  }

  // Save internship recommendations
  Future<void> saveInternshipRecommendations({
    required String userId,
    required List<Map<String, dynamic>> internships,
    required String searchQuery,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('internship_recommendations')
          .add({
        'internships': internships,
        'searchQuery': searchQuery,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving internship recommendations: $e');
      throw e;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUserId == null) return null;
      
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> profileData) async {
    try {
      if (currentUserId == null) return;
      
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(profileData, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
      throw e;
    }
  }

  // Get recommendations history
  Future<List<Map<String, dynamic>>> getRecommendationsHistory() async {
    try {
      if (currentUserId == null) return [];
      
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recommendations')
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  // Save career recommendation for deep dive analysis
  Future<void> saveCareerRecommendation({
    required Map<String, String> userAnswers,
    required String recommendation,
    required List<Map<String, dynamic>> internships,
    required List<Map<String, dynamic>> courses,
    required Map<String, dynamic>? linkedInAnalysis,
  }) async {
    try {
      if (currentUserId == null) return;
      
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('recommendations')
          .add({
        'userAnswers': userAnswers,
        'recommendation': recommendation,
        'internships': internships,
        'courses': courses,
        'linkedInAnalysis': linkedInAnalysis,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'career_guidance',
        'is_read': false,
      });
    } catch (e) {
      print('Error saving career recommendation: $e');
      throw e;
    }
  }

  // Generate career prediction based on user profile
  Future<Map<String, dynamic>> generateCareerPrediction({
    required Map<String, dynamic> userProfile,
    required String chatContext,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Create comprehensive prompt for career prediction
      String prompt = """
      You are an expert career counselor and psychologist specializing in B.Tech students. 
      Based on this user's complete profile and chat context, provide a detailed career prediction with clear reasoning.

      User Profile: ${userProfile.toString()}
      Chat Context: $chatContext

      Provide a comprehensive analysis including:
      1. **Most Suitable Career Path**: Primary recommendation with specific role titles
      2. **Detailed Reasoning**: Why this career path is perfect for them (analyze their responses, interests, skills)
      3. **Personality Analysis**: Key personality traits that led to this recommendation
      4. **Skills Development Plan**: Specific skills they should focus on and why
      5. **Timeline & Progression**: 1-year, 3-year, and 5-year career milestones
      6. **Potential Challenges**: What obstacles they might face and how to overcome them
      7. **Alternative Paths**: 2-3 backup career options if primary doesn't work out

      Be specific, actionable, and provide clear reasoning for every recommendation.
      Consider both technical and management career paths for B.Tech students.
      """;

      // Generate prediction using Gemini
      String prediction =  await EnhancedGeminiService.getGeminiResponse(prompt);
      
      // Extract detailed reasoning from the prediction
      String reasoning = _extractDetailedReasoning(prediction, userProfile);

      // Save to Firestore with enhanced data structure
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .add({
        'type': 'career_prediction',
        'recommendation': prediction,
        'reasoning': reasoning,
        'user_profile': userProfile,
        'chat_context': chatContext,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'prediction_confidence': 'high',
        'analysis_version': '2.0',
      });

      return {
        'id': docRef.id,
        'recommendation': prediction,
        'reasoning': reasoning,
        'type': 'career_prediction',
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print('Error generating career prediction: $e');
      throw e;
    }
  }

  // Generate comprehensive analysis
  Future<Map<String, dynamic>> generateComprehensiveAnalysis() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get user's complete data
      final userProfile = await getUserProfile() ?? {};
      final chatHistory = await getChatHistory(userId);
      final linkedInData = await _getLatestLinkedInAnalysis(userId);
      
      String prompt = """
      You are an expert career psychologist and life coach. Provide a comprehensive personality and career analysis.

      User Profile: ${userProfile.toString()}
      Chat History: ${chatHistory?.toString() ?? 'No chat history available'}
      LinkedIn Data: ${linkedInData?.toString() ?? 'No LinkedIn data available'}

      Provide a detailed comprehensive analysis including:
      1. **Personality Assessment**: MBTI-style analysis, strengths, weaknesses
      2. **Career Compatibility Analysis**: How their personality aligns with different careers
      3. **Detailed Career Recommendations**: Top 3 career paths with specific reasoning
      4. **Skill Gap Analysis**: Current skills vs required skills for recommended careers
      5. **Learning Path**: Specific courses, certifications, and experiences needed
      6. **Long-term Career Strategy**: 5-10 year career roadmap
      7. **Personal Development Areas**: Soft skills and areas for improvement
      8. **Industry Insights**: Market trends affecting their recommended careers

      Provide specific, actionable insights with clear reasoning for each recommendation.
      Consider the user's complete digital footprint and conversation history.
      """;

      String analysis =  await EnhancedGeminiService.getGeminiResponse(prompt);
      String reasoning = _extractComprehensiveReasoning(analysis, userProfile, chatHistory);

      // Save comprehensive analysis to Firestore
      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .add({
        'type': 'comprehensive_analysis',
        'recommendation': analysis,
        'reasoning': reasoning,
        'user_profile': userProfile,
        'chat_history': chatHistory,
        'linkedin_data': linkedInData,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'analysis_depth': 'comprehensive',
        'data_sources': ['profile', 'chat', 'linkedin'].where((s) => 
          s == 'profile' || 
          (s == 'chat' && chatHistory != null) || 
          (s == 'linkedin' && linkedInData != null)
        ).toList(),
      });

      return {
        'id': docRef.id,
        'recommendation': analysis,
        'reasoning': reasoning,
        'type': 'comprehensive_analysis',
        'timestamp': DateTime.now(),
      };
    } catch (e) {
      print('Error generating comprehensive analysis: $e');
      throw e;
    }
  }

  // Mark recommendation as read
  Future<void> markRecommendationAsRead(String recommendationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'is_read': true,
        'read_at': FieldValue.serverTimestamp(),
        'last_accessed': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking recommendation as read: $e');
      throw e;
    }
  }

  // Delete recommendation
  Future<void> deleteRecommendation(String recommendationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Add to deleted_recommendations for potential recovery
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .doc(recommendationId)
          .get();

      if (docSnapshot.exists) {
        // Archive before deleting
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('deleted_recommendations')
            .add({
          ...docSnapshot.data()!,
          'deleted_at': FieldValue.serverTimestamp(),
          'original_id': recommendationId,
        });

        // Now delete the original
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('recommendations')
            .doc(recommendationId)
            .delete();
      }
    } catch (e) {
      print('Error deleting recommendation: $e');
      throw e;
    }
  }

  // Helper method to get latest LinkedIn analysis
  Future<Map<String, dynamic>?> _getLatestLinkedInAnalysis(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('linkedin_analysis')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('Error getting LinkedIn analysis: $e');
      return null;
    }
  }

  // Helper method to extract detailed reasoning from career prediction
  String _extractDetailedReasoning(String prediction, Map<String, dynamic> userProfile) {
    // Look for reasoning patterns in the prediction
    List<String> reasoningKeywords = [
      'because', 'since', 'due to', 'given that', 'considering',
      'based on', 'this is recommended because', 'the reason is',
      'this will help', 'given your', 'taking into account',
      'your responses indicate', 'analysis shows', 'this suggests'
    ];

    List<String> sentences = prediction.split(RegExp(r'[.!?]+'));
    List<String> reasoningSentences = [];

    for (String sentence in sentences) {
      String lowerSentence = sentence.toLowerCase().trim();
      if (lowerSentence.isNotEmpty &&
          reasoningKeywords.any((keyword) => lowerSentence.contains(keyword))) {
        reasoningSentences.add(sentence.trim());
      }
    }

    if (reasoningSentences.isNotEmpty) {
      return reasoningSentences.take(5).join('. ').trim() + '.';
    }

    // Enhanced fallback reasoning based on user profile
    String branch = userProfile['branch'] ?? 'Engineering';
    String interests = userProfile['interests_hobbies'] ?? 'various interests';
    String careerClarity = userProfile['career_clarity'] ?? 'moderate';
    
    return """
    This career prediction is based on comprehensive analysis of your profile:
    
    **Academic Background**: Your $branch background provides a strong foundation for technical and analytical roles.
    
    **Interest Analysis**: Your interests in $interests align well with careers that combine technical skills with creative problem-solving.
    
    **Career Clarity**: With a clarity level of $careerClarity, the AI identified paths that match your current understanding while providing growth opportunities.
    
    **Personality Fit**: Your responses indicate a personality type that thrives in environments requiring both logical thinking and innovative solutions.
    
    The AI analyzed your complete conversation history, academic background, and personal interests to provide this tailored career guidance.
    """;
  }

  // Helper method to extract comprehensive reasoning
  String _extractComprehensiveReasoning(
    String analysis, 
    Map<String, dynamic> userProfile, 
    Map<String, dynamic>? chatHistory
  ) {
    // Look for analysis and reasoning sections
    if (analysis.toLowerCase().contains('reasoning') || 
        analysis.toLowerCase().contains('because') ||
        analysis.toLowerCase().contains('analysis shows') ||
        analysis.toLowerCase().contains('based on your')) {
      
      List<String> sentences = analysis.split(RegExp(r'[.!?]+'));
      List<String> reasoningSentences = [];

      for (String sentence in sentences) {
        String lowerSentence = sentence.toLowerCase().trim();
        if (lowerSentence.contains('reasoning') || 
            lowerSentence.contains('analysis') ||
            lowerSentence.contains('because') ||
            lowerSentence.contains('indicates') ||
            lowerSentence.contains('suggests') ||
            lowerSentence.contains('based on') ||
            lowerSentence.contains('your profile shows')) {
          reasoningSentences.add(sentence.trim());
        }
      }

      if (reasoningSentences.isNotEmpty) {
        return reasoningSentences.take(6).join('. ').trim() + '.';
      }
    }

    // Enhanced fallback comprehensive reasoning
    bool hasLinkedIn = userProfile.containsKey('linkedin_url');
    bool hasChatHistory = chatHistory != null && chatHistory.isNotEmpty;
    
    return """
    This comprehensive analysis combines multiple data sources to provide personalized career guidance:
    
    **Profile Analysis**: Your academic background, interests, and career goals were thoroughly analyzed to understand your strengths and preferences.
    
    **Conversation Insights**: ${hasChatHistory ? 'Your detailed responses during our conversation revealed key personality traits and career inclinations.' : 'The analysis focused on your profile data and preferences.'}
    
    **Professional Background**: ${hasLinkedIn ? 'Your LinkedIn profile data enhanced the analysis with real-world professional context.' : 'The analysis used your academic and personal information to build career recommendations.'}
    
    **Personality Assessment**: The AI performed a holistic assessment of your thinking style, work preferences, and career clarity to match you with suitable opportunities.
    
    **Market Alignment**: Current industry trends and job market conditions were considered to ensure the recommendations are practical and future-ready.
    
    This multi-dimensional analysis ensures that the career guidance is tailored specifically to your unique profile and circumstances.
    """;
  }

  // Additional helper method to get recommendation details for deep dive
  Future<Map<String, dynamic>?> getRecommendationDetails(String recommendationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .doc(recommendationId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting recommendation details: $e');
      return null;
    }
  }

  // Update recommendation with user feedback
  Future<void> updateRecommendationFeedback({
    required String recommendationId,
    required Map<String, dynamic> feedback,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('recommendations')
          .doc(recommendationId)
          .update({
        'user_feedback': feedback,
        'feedback_timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating recommendation feedback: $e');
      throw e;
    }
  }
}


