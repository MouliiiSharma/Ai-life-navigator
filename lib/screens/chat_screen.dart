import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/firestore_service.dart';
import '../services/gemini_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? messageType;
  final Map<String, dynamic>? metadata;
  
  ChatMessage({
    required this.text, 
    required this.isUser, 
    DateTime? timestamp,
    this.messageType,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();
}

class YouTubeVideo {
  final String title;
  final String videoId;
  final String thumbnail;
  final String channelTitle;
  final String description;

  YouTubeVideo({
    required this.title,
    required this.videoId,
    required this.thumbnail,
    required this.channelTitle,
    required this.description,
  });

  factory YouTubeVideo.fromJson(Map<String, dynamic> json) {
    return YouTubeVideo(
      title: json['snippet']['title'] ?? '',
      videoId: json['id']['videoId'] ?? '',
      thumbnail: json['snippet']['thumbnails']['medium']['url'] ?? '',
      channelTitle: json['snippet']['channelTitle'] ?? '',
      description: json['snippet']['description'] ?? '',
    );
  }
}

class InternshipOpportunity {
  final String title;
  final String company;
  final String location;
  final String description;
  final String url;

  InternshipOpportunity({
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    required this.url,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();

  // API Keys
  static const String _youtubeApiKey = 'AIzaSyCJ8MC7K87Kt-uvUrzRQ1mnWs1iQ7_QawM';
  static const String _rapidApiKey = '47026e8cd8mshe608e5ef002f184p15c68fjsne74e4980964d';

  bool _isTyping = false;
  bool _onboardingComplete = false;
  int _currentQuestionIndex = 0;

  final List<Map<String, String>> _questions = [
    {
      "question": "Let's start with the basics - What's your name and what date were you born? (DD/MM/YYYY)",
      "type": "personal_basic"
    },
    {
      "question": "Why did you choose B.Tech? Was it your own decision, family influence, or societal expectations?",
      "type": "motivation"
    },
    {
      "question": "Which engineering branch are you in, and are you genuinely passionate about it or just going with the flow?",
      "type": "academic_passion"
    },
    {
      "question": "What subjects make you lose track of time when studying? What topics excite you the most?",
      "type": "interest_deep"
    },
    {
      "question": "Outside academics, what are your top 3 hobbies? What do you do when you want to relax or feel energized?",
      "type": "personality_hobbies"
    },
    {
      "question": "When faced with a problem, do you prefer: A) Analyzing data and logic, B) Brainstorming creative solutions, C) Asking others for advice, or D) Taking immediate action?",
      "type": "problem_solving_style"
    },
    {
      "question": "Do you see yourself as more of an introvert (energized by alone time) or extrovert (energized by social interaction)? Give an example.",
      "type": "personality_type"
    },
    {
      "question": "What's your biggest strength and your biggest weakness? Be honest - this helps me understand you better.",
      "type": "self_awareness"
    },
    {
      "question": "Where do you see yourself in 5 years? Job, business, higher studies, or still figuring it out?",
      "type": "future_vision"
    },
    {
      "question": "On a scale of 1-10, how confident are you about your career path? What's your biggest fear about the future?",
      "type": "confidence_fears"
    },
    {
      "question": "What kind of work environment energizes you? Fast-paced startup, structured corporate, research lab, or working independently?",
      "type": "work_preference"
    },
    {
      "question": "Do you prefer to be a leader, a team player, or work solo? Give me an example from your experience.",
      "type": "leadership_style"
    }
  ];

  final Map<String, String> _answers = {};
  String _userName = "";
  String _birthDate = "";
  String _userField = "";
  List<String> _userInterests = [];

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  // YouTube API Integration
  Future<List<YouTubeVideo>> _searchYouTubeVideos(String query) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&maxResults=5&key=$_youtubeApiKey'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        return items.map((item) => YouTubeVideo.fromJson(item)).toList();
      } else {
        print('YouTube API Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('YouTube API Exception: $e');
      return [];
    }
  }

  // Enhanced Internship Search (mock implementation - you can integrate with your LinkedIn API)
  Future<List<InternshipOpportunity>> _searchInternships(String field) async {
    try {
      // Mock data for demonstration - replace with your LinkedIn API integration
      await Future.delayed(Duration(milliseconds: 500)); // Simulate API call
      
      // You can integrate your LinkedIn API here
      // final response = await http.get(
      //   Uri.parse('https://fresh-linkedin-scraper-api.p.rapidapi.com/api/v1/company/affiliated-pages?company_id=1441'),
      //   headers: {
      //     'x-rapidapi-host': 'fresh-linkedin-scraper-api.p.rapidapi.com',
      //     'x-rapidapi-key': _rapidApiKey,
      //   },
      // );
      
      return [
        InternshipOpportunity(
          title: 'Software Engineering Intern',
          company: 'Tech Corp',
          location: 'Bangalore',
          description: 'Work on cutting-edge projects in $field',
          url: 'https://example.com/internship1',
        ),
        InternshipOpportunity(
          title: 'Data Science Intern',
          company: 'Analytics Inc',
          location: 'Mumbai',
          description: 'Analyze data and build ML models',
          url: 'https://example.com/internship2',
        ),
        InternshipOpportunity(
          title: 'Product Management Intern',
          company: 'Startup Hub',
          location: 'Delhi',
          description: 'Learn product strategy and development',
          url: 'https://example.com/internship3',
        ),
      ];
    } catch (e) {
      print('Internship API Exception: $e');
      return [];
    }
  }

  void _startConversation() {
    Future.delayed(Duration.zero, () {
      _addMessage(
        "Hi! I'm your AI Life Navigator 🌟 I'm here to understand you deeply - like a friend who really gets you - and help guide your career journey. Think of this as a chat with someone who genuinely cares about your future!",
        isUser: false
      );
      
      Future.delayed(Duration(milliseconds: 1500), () {
        _addMessage(_questions[_currentQuestionIndex]["question"]!, isUser: false);
      });
    });
  }

  void _addMessage(String text, {required bool isUser, String? messageType, Map<String, dynamic>? metadata}) {
    setState(() {
      _messages.add(ChatMessage(
        text: text, 
        isUser: isUser, 
        messageType: messageType,
        metadata: metadata,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserMessage(String prompt) async {
    _addMessage(prompt, isUser: true);

    if (!_onboardingComplete) {
      await _handleOnboardingMessage(prompt);
    } else {
      await _processFreeChat(prompt);
    }
  }

  Future<void> _handleOnboardingMessage(String prompt) async {
    String questionKey = _questions[_currentQuestionIndex]["question"]!;
    String questionType = _questions[_currentQuestionIndex]["type"]!;
    
    _answers[questionKey] = prompt;
    
    // Extract information from specific questions
    if (questionType == "personal_basic") {
      _extractPersonalInfo(prompt);
    } else if (questionType == "academic_passion") {
      _extractFieldInfo(prompt);
    } else if (questionType == "interest_deep") {
      _extractInterests(prompt);
    }

    _currentQuestionIndex++;
    if (_currentQuestionIndex < _questions.length) {
      Future.delayed(Duration(milliseconds: 800), () {
        String acknowledgment = _getAcknowledgment(questionType, prompt);
        _addMessage(acknowledgment, isUser: false);
        
        Future.delayed(Duration(milliseconds: 1200), () {
          _addMessage(_questions[_currentQuestionIndex]["question"]!, isUser: false);
        });
      });
    } else {
      _onboardingComplete = true;
      await _handleOnboardingComplete();
    }
  }

  void _extractPersonalInfo(String response) {
    List<String> parts = response.split(' ');
    if (parts.isNotEmpty) {
      _userName = parts[0];
    }
    
    RegExp dateRegex = RegExp(r'\d{1,2}[\/\-]\d{1,2}[\/\-]\d{4}');
    RegExpMatch? match = dateRegex.firstMatch(response);
    if (match != null) {
      _birthDate = match.group(0)!;
    }
  }

  void _extractFieldInfo(String response) {
    _userField = response.toLowerCase();
  }

  void _extractInterests(String response) {
    _userInterests = response.split(',').map((e) => e.trim()).toList();
  }

  String _getAcknowledgment(String questionType, String answer) {
    switch (questionType) {
      case "personal_basic":
        return "Nice to meet you${_userName.isNotEmpty ? ', $_userName' : ''}! 😊";
      case "motivation":
        return "That's really insightful - understanding your 'why' is so important!";
      case "academic_passion":
        return "Got it! It's totally normal to question your path - that's actually a sign of self-awareness.";
      case "interest_deep":
        return "Interesting! Those subjects that make time fly are often clues to your natural strengths.";
      case "personality_hobbies":
        return "Love it! Your hobbies reveal a lot about what energizes you.";
      case "problem_solving_style":
        return "Perfect! This tells me a lot about how your mind works.";
      case "personality_type":
        return "Thanks! Understanding your energy patterns helps me recommend the right environments for you.";
      case "self_awareness":
        return "I appreciate your honesty! Self-awareness is actually a superpower.";
      case "future_vision":
        return "That gives me a great sense of your aspirations!";
      case "confidence_fears":
        return "Thank you for being vulnerable - everyone has fears, and acknowledging them is brave.";
      case "work_preference":
        return "Excellent! Environment fit is crucial for long-term happiness.";
      case "leadership_style":
        return "Great example! Understanding your collaboration style is key.";
      default:
        return "Thanks for sharing that!";
    }
  }

  Future<void> _handleOnboardingComplete() async {
    _addMessage(
      "Wow! Thank you for sharing so openly with me${_userName.isNotEmpty ? ', $_userName' : ''}! 🙏 Let me now analyze everything you've told me and create a personalized roadmap for you...",
      isUser: false
    );
    
    setState(() => _isTyping = true);

    try {
      final profileSummary = _buildComprehensiveProfile();
      
      final prompt = """
You are an expert career counselor and life coach. Based on this detailed student profile, provide comprehensive analysis with clear reasoning.

Student Profile:
$profileSummary

Please provide:

1. **PERSONALITY ANALYSIS & REASONING**
   - Analyze their personality type based on their responses
   - Explain what their answers reveal about their working style
   - Reasoning: Why you conclude this about their personality

2. **CAREER RECOMMENDATIONS WITH DETAILED REASONING**
   - Suggest 3-4 specific career paths
   - For EACH career suggestion, explain:
     * Why this career fits their personality
     * How it aligns with their interests and skills
     * What specific responses led to this recommendation
     * Examples of roles/companies in this field

3. **SKILL DEVELOPMENT PLAN WITH REASONING**
   - Specific skills to develop in next 6-12 months
   - Reasoning: Why these skills based on their career goals and current gaps
   - How these skills connect to their chosen field

4. **INTERNSHIP/OPPORTUNITY RECOMMENDATIONS WITH REASONING**
   - Specific types of companies/roles to target
   - Reasoning: Why these opportunities match their profile
   - What aspects of their background make them suitable

5. **PERSONAL GROWTH AREAS WITH REASONING**
   - Areas for development based on their self-assessment
   - Reasoning: Why these areas need attention based on their responses
   - How improvement will help their career journey

6. **NEXT STEPS WITH REASONING**
   - Concrete 30-day action plan
   - Reasoning: Why these specific steps given their current situation
   - Priority order and timeline explanation

Make your reasoning specific to their actual responses. Reference their specific answers when explaining recommendations.
""";

      final aiResponse = await GeminiService.getGeminiResponse(prompt);

      _addMessage("Here's your personalized analysis and roadmap! 🎯", isUser: false);
      _addMessage(aiResponse, isUser: false);
      
      // Add YouTube learning resources
      await _addYouTubeRecommendations();
      
      // Add internship opportunities
      await _addInternshipRecommendations();
      
      setState(() => _isTyping = false);

      String detailedReasoning = _extractReasoningFromResponse(aiResponse, profileSummary);

      await _firestoreService.saveChatMessage("Onboarding Complete", aiResponse);
      await _firestoreService.saveRecommendation(
        recommendation: aiResponse,
        reasoning: detailedReasoning,
        userProfile: profileSummary,
        recommendationType: "comprehensive_analysis"
      );

      Future.delayed(Duration(milliseconds: 2000), () {
        _addMessage(
          "Feel free to ask me anything about your roadmap, dive deeper into any area, or ask for more resources! I can help you find learning materials, internships, or career guidance. 💪",
          isUser: false
        );
      });

    } catch (e) {
      _addMessage("I encountered an error during analysis: ${e.toString()}. Let me try again!", isUser: false);
      setState(() => _isTyping = false);
    }
  }

  Future<void> _addYouTubeRecommendations() async {
    _addMessage("🎥 Let me find some relevant learning resources for you on YouTube!", isUser: false);
    
    setState(() => _isTyping = true);
    
    try {
      String searchQuery = _userField.isNotEmpty ? '$_userField career guide' : 'engineering career guide';
      if (_userInterests.isNotEmpty) {
        searchQuery += ' ${_userInterests.first}';
      }
      
      final videos = await _searchYouTubeVideos(searchQuery);
      
      if (videos.isNotEmpty) {
        _addMessage(
          "Here are some great YouTube videos to help you on your journey:",
          isUser: false,
          messageType: "youtube_recommendations",
          metadata: {"videos": videos.map((v) => {
            "title": v.title,
            "videoId": v.videoId,
            "thumbnail": v.thumbnail,
            "channelTitle": v.channelTitle,
            "description": v.description,
          }).toList()}
        );
      } else {
        _addMessage("I had trouble finding videos right now, but I'll keep helping you with other resources!", isUser: false);
      }
    } catch (e) {
      _addMessage("I couldn't fetch YouTube recommendations right now, but that's okay! Let's continue with other guidance.", isUser: false);
    }
    
    setState(() => _isTyping = false);
  }

  Future<void> _addInternshipRecommendations() async {
    _addMessage("💼 Now let me find some internship opportunities that match your profile!", isUser: false);
    
    setState(() => _isTyping = true);
    
    try {
      final internships = await _searchInternships(_userField);
      
      if (internships.isNotEmpty) {
        _addMessage(
          "Here are some internship opportunities that might interest you:",
          isUser: false,
          messageType: "internship_recommendations",
          metadata: {"internships": internships.map((i) => {
            "title": i.title,
            "company": i.company,
            "location": i.location,
            "description": i.description,
            "url": i.url,
          }).toList()}
        );
      } else {
        _addMessage("I'll keep looking for internship opportunities for you! In the meantime, I can help you prepare for applications.", isUser: false);
      }
    } catch (e) {
      _addMessage("I couldn't fetch internship recommendations right now, but I can still help you prepare for your career journey!", isUser: false);
    }
    
    setState(() => _isTyping = false);
  }

  String _extractReasoningFromResponse(String aiResponse, String userProfile) {
    StringBuffer reasoning = StringBuffer();
    
    List<String> reasoningKeywords = [
      'reasoning:', 'because', 'based on', 'given that', 'since you mentioned',
      'your responses indicate', 'this suggests', 'analysis shows'
    ];
    
    List<String> lines = aiResponse.split('\n');
    List<String> reasoningLines = [];
    
    for (String line in lines) {
      String lowerLine = line.toLowerCase();
      if (reasoningKeywords.any((keyword) => lowerLine.contains(keyword))) {
        reasoningLines.add(line.trim());
      }
      if (lowerLine.contains('why') || lowerLine.contains('this is') || lowerLine.contains('you are')) {
        reasoningLines.add(line.trim());
      }
    }
    
    if (reasoningLines.isNotEmpty) {
      reasoning.writeln("🔍 **Detailed Analysis Reasoning:**\n");
      reasoning.writeln(reasoningLines.join('\n\n'));
      reasoning.writeln("\n${"="*50}\n");
    }
    
    reasoning.writeln("📊 **Profile-Based Reasoning:**");
    reasoning.writeln("This comprehensive recommendation was generated by analyzing:");
    reasoning.writeln("• Your academic background and chosen field");
    reasoning.writeln("• Career motivation and decision-making factors");  
    reasoning.writeln("• Personal interests and passion areas");
    reasoning.writeln("• Problem-solving and work style preferences");
    reasoning.writeln("• Personality traits (introvert/extrovert tendencies)");
    reasoning.writeln("• Self-assessed strengths and improvement areas");
    reasoning.writeln("• Future vision and career confidence level");
    reasoning.writeln("• Preferred work environment and leadership style");
    
    return reasoning.toString();
  }

  Future<void> _processFreeChat(String prompt) async {
    setState(() => _isTyping = true);
    
    // Check if user is asking for specific resources
    String lowerPrompt = prompt.toLowerCase();
    
    if (lowerPrompt.contains('youtube') || lowerPrompt.contains('video') || lowerPrompt.contains('learn')) {
      await _handleYouTubeRequest(prompt);
    } else if (lowerPrompt.contains('internship') || lowerPrompt.contains('job') || lowerPrompt.contains('opportunity')) {
      await _handleInternshipRequest(prompt);
    } else {
      await _handleGeneralChat(prompt);
    }
  }

  Future<void> _handleYouTubeRequest(String prompt) async {
    try {
      _addMessage("Let me find some relevant videos for you! 🎥", isUser: false);
      
      // Extract search terms from the prompt
      String searchQuery = prompt;
      if (_userField.isNotEmpty) {
        searchQuery += ' $_userField';
      }
      
      final videos = await _searchYouTubeVideos(searchQuery);
      
      if (videos.isNotEmpty) {
        _addMessage(
          "Here are some videos I found for you:",
          isUser: false,
          messageType: "youtube_recommendations",
          metadata: {"videos": videos.map((v) => {
            "title": v.title,
            "videoId": v.videoId,
            "thumbnail": v.thumbnail,
            "channelTitle": v.channelTitle,
            "description": v.description,
          }).toList()}
        );
      } else {
        _addMessage("I couldn't find specific videos for that topic right now, but I can still help you with guidance!", isUser: false);
      }
    } catch (e) {
      _addMessage("I'm having trouble finding videos right now. Let me help you in other ways!", isUser: false);
    }
    
    setState(() => _isTyping = false);
  }

  Future<void> _handleInternshipRequest(String prompt) async {
    try {
      _addMessage("Let me look for internship opportunities for you! 💼", isUser: false);
      
      final internships = await _searchInternships(_userField);
      
      if (internships.isNotEmpty) {
        _addMessage(
          "Here are some internship opportunities:",
          isUser: false,
          messageType: "internship_recommendations",
          metadata: {"internships": internships.map((i) => {
            "title": i.title,
            "company": i.company,
            "location": i.location,
            "description": i.description,
            "url": i.url,
          }).toList()}
        );
      } else {
        _addMessage("I'm working on finding more internship opportunities. In the meantime, I can help you prepare your resume and interview skills!", isUser: false);
      }
    } catch (e) {
      _addMessage("I'm having trouble finding internships right now, but I can help you prepare for applications!", isUser: false);
    }
    
    setState(() => _isTyping = false);
  }

  Future<void> _handleGeneralChat(String prompt) async {
    try {
      final enhancedPrompt = """
Context: You are chatting with ${_userName.isNotEmpty ? _userName : 'a student'} who has completed onboarding. 
Previous context: User is a B.Tech student seeking career guidance.
User's field: $_userField
User's interests: ${_userInterests.join(', ')}

User Question/Message: $prompt

Please provide a helpful, encouraging, and specific response. If giving advice or recommendations, always explain your reasoning.

Format your response like this:
1. Direct answer to their question
2. If giving recommendations, explain WHY you recommend this based on their profile/background
3. Be actionable and supportive

If the user asks for learning resources, internships, or videos, mention that you can help them find those specifically.
""";

      final aiResponse = await GeminiService.getGeminiResponse(enhancedPrompt);
      _addMessage(aiResponse, isUser: false);
      
      await _firestoreService.saveChatMessage(prompt, aiResponse);

      if (_containsRecommendation(aiResponse)) {
        String chatReasoning = _extractChatReasoning(prompt, aiResponse);
        await _firestoreService.saveRecommendation(
          recommendation: aiResponse,
          reasoning: chatReasoning,
          userProfile: "Chat context: User asked - '$prompt'",
          recommendationType: "chat_recommendation"
        );
      }
    } catch (e) {
      _addMessage("I'm having trouble processing that right now. Please try again! 😅", isUser: false);
    }
    
    setState(() => _isTyping = false);
  }

  String _extractChatReasoning(String userQuestion, String aiResponse) {
    StringBuffer reasoning = StringBuffer();
    
    reasoning.writeln("💬 **Chat-Based Recommendation Reasoning:**\n");
    reasoning.writeln("**Your Question:** $userQuestion\n");
    reasoning.writeln("**Why This Recommendation:**");
    
    List<String> sentences = aiResponse.split(RegExp(r'[.!?]+'));
    List<String> reasoningSentences = [];
    
    for (String sentence in sentences) {
      String lower = sentence.toLowerCase().trim();
      if (lower.contains('because') || lower.contains('since') || 
          lower.contains('this will help') || lower.contains('given') ||
          lower.contains('based on') || lower.contains('reason')) {
        reasoningSentences.add(sentence.trim());
      }
    }
    
    if (reasoningSentences.isNotEmpty) {
      reasoning.writeln('${reasoningSentences.join('. ')}.\n');
    }
    
    reasoning.writeln("**Context:** This recommendation was generated in response to your specific question during our conversation, taking into account your individual situation and career goals.\n");
    reasoning.writeln("**Relevance:** The advice is tailored to address your immediate concern while considering your overall career development path.");
    
    return reasoning.toString();
  }

  String _buildComprehensiveProfile() {
    StringBuffer profile = StringBuffer();
    
    profile.writeln("=== STUDENT PROFILE ===");
    profile.writeln("Name: $_userName");
    profile.writeln("Birth Date: $_birthDate");
    profile.writeln("Field: $_userField");
    profile.writeln("Interests: ${_userInterests.join(', ')}");
    profile.writeln();
    
    _answers.forEach((question, answer) {
      profile.writeln("Q: $question");
      profile.writeln("A: $answer");
      profile.writeln();
    });
    
    return profile.toString();
  }

  bool _containsRecommendation(String response) {
    List<String> recommendationKeywords = [
      'recommend', 'suggest', 'should', 'try', 'consider', 
      'focus on', 'pursue', 'apply for', 'learn', 'develop'
    ];
    
    String lowerResponse = response.toLowerCase();
    return recommendationKeywords.any((keyword) => lowerResponse.contains(keyword));
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _handleUserMessage(text);
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link')),
      );
    }
  }

  Widget _buildMessageWidget(ChatMessage message) {
    if (message.messageType == "youtube_recommendations") {
      return _buildYouTubeRecommendationWidget(message);
    } else if (message.messageType == "internship_recommendations") {
      return _buildInternshipRecommendationWidget(message);
    } else {
      return _buildRegularMessageWidget(message);
    }
  }

  Widget _buildYouTubeRecommendationWidget(ChatMessage message) {
    final videos = message.metadata?['videos'] as List<dynamic>? ?? [];
    
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegularMessageWidget(message),
          SizedBox(height: 8),
          Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return Container(
                  width: 280,
                  margin: EdgeInsets.only(right: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => _launchUrl('https://www.youtube.com/watch?v=${video['videoId']}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            width: double.infinity,
                            child: Image.network(
                              video['thumbnail'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                Container(
                                  color: Colors.grey.shade300, 
                                  child: Icon(Icons.play_circle_outline, size: 40, color: Colors.grey),
                                ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video['title'],
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                 Text(
                                  video['channelTitle'],
                                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  video['description'],
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternshipRecommendationWidget(ChatMessage message) {
    final internships = message.metadata?['internships'] as List<dynamic>? ?? [];

    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRegularMessageWidget(message),
          SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: internships.length,
            itemBuilder: (context, index) {
              final internship = internships[index];
              return Card(
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(
                    internship['title'],
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${internship['company']} • ${internship['location']}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                      SizedBox(height: 4),
                      Text(
                        internship['description'],
                        style: TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.open_in_new),
                    onPressed: () => _launchUrl(internship['url']),
                  ),
                  onTap: () => _launchUrl(internship['url']),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRegularMessageWidget(ChatMessage message) {
    final isUser = message.isUser;
    final timeString =
        DateFormat('hh:mm a').format(message.timestamp);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColorLight : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.black : Colors.black87,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 4),
            Text(
              timeString,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Life Navigator'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageWidget(message);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircularProgressIndicator(strokeWidth: 2),
                  SizedBox(width: 12),
                  Text("Thinking...", style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.only(
                left: 10, right: 10, bottom: MediaQuery.of(context).padding.bottom + 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _handleSend(),
                    decoration: InputDecoration(
                      hintText: _onboardingComplete
                          ? "Type your message..."
                          : "Answer the question...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _isTyping ? null : _handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}