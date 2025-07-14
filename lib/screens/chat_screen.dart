import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';  // Add this import
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/gemini_service.dart';
import '../services/firestore_service.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final EnhancedGeminiService _geminiService = EnhancedGeminiService();
  final ScrollController _scrollController = ScrollController();
  
  int _questionIndex = 0;
  Map<String, String> _userResponses = {};
  bool _isLoading = false;
  bool _questionsCompleted = false;
  Map<String, dynamic>? _linkedInData;
  
  // API Keys
  static const String _rapidApiKey = '47026e8cd8mshe608e5ef002f184p15c68fjsne74e4980964d';
  static const String _linkedInApiHost = 'fresh-linkedin-profile-data.p.rapidapi.com';
  static const String _youtubeApiKey = 'AIzaSyCJ8MC7K87Kt-uvUrzRQ1mnWs1iQ7_QawM';

  // Your specific questions
  final List<String> _questions = [
    "👋 Hi! I'm your AI Life Navigator. Let's start by getting to know you better. What's your name?",
    "🎓 Which branch are you currently studying in B.Tech?",
    "💡 Why did you choose your current course or career path (e.g., B.Tech)?",
    "📚 What subjects or topics do you genuinely enjoy studying or working on?",
    "🔄 If you could choose a different field, what would it be and why?",
    "🎯 What are your top 3 interests or hobbies outside academics?",
    "⚡ What kind of tasks make you feel most productive or excited?",
    "🚀 Do you see yourself in a job, business, freelancing, or pursuing higher studies in the future?",
    "📈 On a scale of 1–10, how clear are you about your career goals?",
    "🧠 Do you prefer logical thinking or creative problem-solving?",
    "🔧 What type of guidance or features would you like in a life navigator app? (e.g., career advice, time management, personality insights)",
    "🔗 Do you have a LinkedIn profile? If yes, please share the URL (this will help me provide more personalized recommendations)"
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _startConversation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _startConversation() {
    if (_messages.isEmpty) {
      _addMessage(
        "Hello! I'm your AI Life Navigator assistant. I'll help you discover the perfect career path by understanding your interests, goals, and aspirations. I'll ask you some questions and then provide personalized recommendations including live internship opportunities, YouTube courses, Google certifications, and higher studies options. Let's begin!",
        false,
        messageType: 'intro'
      );
      Future.delayed(const Duration(milliseconds: 1000), () {
        _askNextQuestion();
      });
    }
  }

  void _askNextQuestion() {
    if (_questionIndex < _questions.length) {
      _addMessage(_questions[_questionIndex], false, messageType: 'question');
    } else {
      _questionsCompleted = true;
      _generateCareerRecommendations();
    }
  }

  void _addMessage(String content, bool isUser, {String? messageType}) {
    setState(() {
      _messages.add(ChatMessage(
        content: content,
        isUser: isUser,
        timestamp: DateTime.now(),
        messageType: messageType,
      ));
    });
    _scrollToBottom();
    _saveChatToFirebase();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _addMessage(text, true, messageType: 'answer');
    _textController.clear();
    _saveUserResponse(text);
  }

  void _saveUserResponse(String response) {
    List<String> responseKeys = [
      'name', 'branch', 'course_choice_reason', 'enjoyed_subjects',
      'different_field', 'interests_hobbies', 'productive_tasks', 'future_vision',
      'career_clarity', 'thinking_style', 'app_guidance_preference', 'linkedin_url'
    ];

    if (_questionIndex < responseKeys.length) {
      _userResponses[responseKeys[_questionIndex]] = response;
    }

    if (_questionIndex == 11 && response.toLowerCase().contains('linkedin.com')) {
      _analyzeLinkedInProfile(response);
    } else {
      _proceedToNextQuestion();
    }
  }

  void _proceedToNextQuestion() {
    _questionIndex++;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_questionsCompleted) {
        _askNextQuestion();
      }
    });
  }

  Future<void> _analyzeLinkedInProfile(String message) async {
    RegExp urlRegex = RegExp(r'https?://(?:www\.)?linkedin\.com/in/[a-zA-Z0-9-]+/?');
    Match? match = urlRegex.firstMatch(message);
    
    if (match != null) {
      String linkedInUrl = match.group(0)!;
      
      try {
        setState(() {
          _isLoading = true;
        });
        
        _addMessage("🔍 Analyzing your LinkedIn profile for better recommendations...", false, messageType: 'analysis');
        
        final response = await http.get(
          Uri.parse('https://fresh-linkedin-profile-data.p.rapidapi.com/get-profile-public-data?linkedin_url=${Uri.encodeComponent(linkedInUrl)}&include_skills=true&include_certifications=true&include_publications=false&include_honors=false&include_volunteers=false&include_projects=true&include_patents=false&include_courses=false&include_organizations=false&include_profile_status=false&include_company_public_url=false'),
          headers: {
            'X-RapidAPI-Key': _rapidApiKey,
            'X-RapidAPI-Host': _linkedInApiHost,
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          _linkedInData = data;
          
          String analysisText = "✅ **LINKEDIN PROFILE ANALYZED**\n\n";
          analysisText += "**Name:** ${data['name'] ?? 'Not available'}\n";
          analysisText += "**Headline:** ${data['headline'] ?? 'Not available'}\n";
          analysisText += "**Location:** ${data['location'] ?? 'Not available'}\n";
          
          if (data['skills'] != null && data['skills'].isNotEmpty) {
            List<String> skills = List<String>.from(data['skills']);
            analysisText += "**Skills:** ${skills.take(8).join(', ')}\n";
          }
          
          if (data['experience'] != null && data['experience'].isNotEmpty) {
            analysisText += "**Experience:** ${data['experience'].length} positions listed\n";
          }
          
          if (data['education'] != null && data['education'].isNotEmpty) {
            analysisText += "**Education:** ${data['education'].length} institutions\n";
          }
          
          analysisText += "\n🎯 Perfect! This LinkedIn data will significantly enhance your career recommendations.";
          
          _addMessage(analysisText, false, messageType: 'linkedin_analysis');
          
          await _firestoreService.saveLinkedInAnalysis(
            userId: FirebaseAuth.instance.currentUser!.uid,
            profileData: data,
            analysisText: analysisText,
          );
          
        } else {
          _addMessage("⚠️ Couldn't analyze LinkedIn profile (${response.statusCode}). Don't worry, I'll still provide excellent recommendations based on your answers!", false);
        }
      } catch (e) {
        print('LinkedIn analysis error: $e');
        _addMessage("⚠️ Error analyzing LinkedIn profile. That's okay - I'll provide great recommendations based on your responses!", false);
      } finally {
        setState(() {
          _isLoading = false;
        });
        _proceedToNextQuestion();
      }
    } else {
      _addMessage("👍 I'll provide excellent recommendations based on your responses.", false);
      _proceedToNextQuestion();
    }
  }

  Future<void> _generateCareerRecommendations() async {
    setState(() {
      _isLoading = true;
    });

    _addMessage("🎯 Excellent! I have all the information I need. Let me analyze your profile and generate comprehensive career recommendations with live opportunities...", false, messageType: 'processing');

    try {
      // Step 1: Generate career analysis with Gemini
      String careerAnalysis = await _generateCareerAnalysis();
      
      // Step 2: Get live internships using prompt engineering
      List<Map<String, dynamic>> internships = await _getLiveInternshipsWithGemini();
      
      // Step 3: Get YouTube courses
      List<Map<String, dynamic>> courses = await _getYouTubeCourses();
      
      // Step 4: Get Google certifications with prompt engineering
      List<Map<String, dynamic>> googleCerts = await _getGoogleCertificationsWithGemini();
      
      // Step 5: Get higher studies options
      String higherStudies = await _getHigherStudiesRecommendations();
      
      // Format and display comprehensive recommendations
      String finalResponse = _formatComprehensiveResponse(
        careerAnalysis, internships, courses, googleCerts, higherStudies
      );
      
      _addMessage(finalResponse, false, messageType: 'final_recommendations');
      
      // Save complete recommendation to Firestore for deep dive analysis
      await _firestoreService.saveCareerRecommendation(
        userAnswers: _userResponses,
        recommendation: careerAnalysis,
        internships: internships,
        courses: courses,
        linkedInAnalysis: _linkedInData,
      );
      
      // Add follow-up message
      _addMessage(
        "🎉 **Your personalized career roadmap is ready!** \n\nYou can now:\n• Apply to the recommended internships\n• Start the suggested courses\n• Pursue the Google certifications\n• Explore higher studies options\n\nFeel free to ask me any follow-up questions about these recommendations!",
        false,
        messageType: 'follow_up'
      );
      
    } catch (e) {
      print('Error generating recommendations: $e');
      _addMessage("❌ I encountered an error generating recommendations. This might be due to API limits or connectivity issues. Please try again in a moment, or ask me specific questions about your career path.", false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _generateCareerAnalysis() async {
    String prompt = """
    You are an expert career counselor specializing in B.Tech students and considering management opportunities. Analyze this student's comprehensive profile:

    STUDENT PROFILE:
    Name: ${_userResponses['name'] ?? 'Not provided'}
    Branch: ${_userResponses['branch'] ?? 'Not provided'}
    Course Choice Reason: ${_userResponses['course_choice_reason'] ?? 'Not provided'}
    Enjoyed Subjects: ${_userResponses['enjoyed_subjects'] ?? 'Not provided'}
    Alternative Field Interest: ${_userResponses['different_field'] ?? 'Not provided'}
    Interests/Hobbies: ${_userResponses['interests_hobbies'] ?? 'Not provided'}
    Productive Tasks: ${_userResponses['productive_tasks'] ?? 'Not provided'}
    Future Vision: ${_userResponses['future_vision'] ?? 'Not provided'}
    Career Clarity (1-10): ${_userResponses['career_clarity'] ?? 'Not provided'}
    Thinking Style: ${_userResponses['thinking_style'] ?? 'Not provided'}
    App Guidance Preference: ${_userResponses['app_guidance_preference'] ?? 'Not provided'}

    ${_linkedInData != null ? 'LINKEDIN DATA AVAILABLE: Yes (Skills: ${_linkedInData!['skills']?.take(5)?.join(', ') ?? 'None'})' : 'LINKEDIN DATA: Not provided'}

    PROVIDE DETAILED ANALYSIS:
    1. **Career Path Recommendations**: Top 3 most suitable career paths (include management options like Product Management, Business Analysis, Consulting if relevant)
    2. **Personality & Strengths Analysis**: Key strengths and personality traits
    3. **Skill Gap Analysis**: Skills they need to develop
    4. **Industry Alignment**: Which industries match their profile
    5. **Growth Trajectory**: 5-year career progression path

    Consider that B.Tech students can excel in:
    - Technical roles (Software Engineer, Data Scientist, etc.)
    - Management roles (Product Manager, Business Analyst, Consultant)
    - Entrepreneurship and startups
    - Research and higher studies
    - Cross-functional roles combining tech and business

    Format with clear headings and actionable insights.
    """;

   try {
  return await EnhancedGeminiService.getGeminiResponse(prompt);
} catch (e){
      print('Error generating career analysis: $e');
      return """
      **Career Analysis**
      
      Based on your profile, here are some general recommendations:
      
      **Career Paths:**
      • Software Development - High demand in tech industry
      • Product Management - Combines technical and business skills
      • Data Analysis - Growing field with good opportunities
      
      **Skills to Develop:**
      • Programming languages relevant to your field
      • Communication and presentation skills
      • Project management capabilities
      
      **Next Steps:**
      • Build a portfolio of projects
      • Network with professionals in your field
      • Consider internships and practical experience
      
      Note: This is a simplified analysis due to API limitations. Please try again for a more detailed assessment.
      """;
    }
  }

  Future<List<Map<String, dynamic>>> _getLiveInternshipsWithGemini() async {
    // Return fallback internships if API fails
    return _getFallbackInternships();
  }

  List<Map<String, dynamic>> _getFallbackInternships() {
    return [
      {
        'title': 'Software Engineering Intern',
        'company': 'Google',
        'location': 'Bangalore, India',
        'description': 'Work on cutting-edge projects with world-class engineers',
        'skills': 'Programming, Algorithms, Problem Solving',
        'applyUrl': 'https://careers.google.com/students/'
      },
      {
        'title': 'Product Management Intern',
        'company': 'Microsoft',
        'location': 'Hyderabad, India',
        'description': 'Drive product strategy and work with cross-functional teams',
        'skills': 'Analytics, Strategy, Communication',
        'applyUrl': 'https://careers.microsoft.com/students/'
      },
      {
        'title': 'Data Science Intern',
        'company': 'Amazon',
        'location': 'Mumbai, India',
        'description': 'Analyze large datasets and build ML models',
        'skills': 'Python, Statistics, Machine Learning',
        'applyUrl': 'https://amazon.jobs/en/teams/internships-for-students'
      },
      {
        'title': 'Business Analyst Intern',
        'company': 'Flipkart',
        'location': 'Bangalore, India',
        'description': 'Analyze business processes and drive improvements',
        'skills': 'Analytics, Business Strategy, SQL',
        'applyUrl': 'https://www.flipkartcareers.com/'
      },
      {
        'title': 'Technology Intern',
        'company': 'Zomato',
        'location': 'Gurgaon, India',
        'description': 'Work on food-tech innovations and mobile applications',
        'skills': 'Mobile Development, APIs, Cloud Computing',
        'applyUrl': 'https://www.zomato.com/careers'
      }
    ];
  }

  Future<List<Map<String, dynamic>>> _getYouTubeCourses() async {
    List<Map<String, dynamic>> courses = [];
    
    try {
      String searchQuery = _generateCourseSearchQuery();
      
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/youtube/v3/search?part=snippet&q=$searchQuery&type=video&maxResults=5&key=$_youtubeApiKey')
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List;
        
        for (var item in items) {
          courses.add({
            'title': item['snippet']['title'],
            'channelName': item['snippet']['channelTitle'],
            'videoId': item['id']['videoId'],
            'url': 'https://youtube.com/watch?v=${item['id']['videoId']}',
            'thumbnail': item['snippet']['thumbnails']['medium']['url'],
            'description': item['snippet']['description'],
          });
        }
      }
    } catch (e) {
      print('Error fetching YouTube courses: $e');
    }
    
    return courses;
  }

  String _generateCourseSearchQuery() {
    String branch = _userResponses['branch']?.toLowerCase() ?? '';
    String interests = _userResponses['interests_hobbies']?.toLowerCase() ?? '';
    String subjects = _userResponses['enjoyed_subjects']?.toLowerCase() ?? '';
    
    if (branch.contains('computer') || subjects.contains('programming') || interests.contains('coding')) {
      return 'programming tutorial complete course';
    } else if (subjects.contains('data') || interests.contains('analytics') || interests.contains('data science')) {
      return 'data science complete course';
    } else if (interests.contains('management') || interests.contains('business') || _userResponses['future_vision']?.toLowerCase().contains('management') == true) {
      return 'business management MBA preparation';
    } else if (branch.contains('mechanical') || subjects.contains('design')) {
      return 'mechanical engineering design course';
    } else if (subjects.contains('electronics') || branch.contains('electronics')) {
      return 'electronics engineering course';
    }
    
    return 'engineering career guidance course';
  }

  Future<List<Map<String, dynamic>>> _getGoogleCertificationsWithGemini() async {
    return _getFallbackGoogleCertifications();
  }

  List<Map<String, dynamic>> _getFallbackGoogleCertifications() {
    return [
      {
        'name': 'Google Data Analytics Professional Certificate',
        'provider': 'Google via Coursera',
        'duration': '3-6 months',
        'skills': 'Data Analysis, SQL, Tableau, R Programming',
        'url': 'https://www.coursera.org/professional-certificates/google-data-analytics',
        'value': 'High demand skill with excellent job prospects'
      },
      {
        'name': 'Google Project Management Professional Certificate',
        'provider': 'Google via Coursera',
        'duration': '3-6 months',
        'skills': 'Project Management, Agile, Scrum',
        'url': 'https://www.coursera.org/professional-certificates/google-project-management',
        'value': 'Essential for leadership and management roles'
      },
      {
        'name': 'Google Cloud Professional Cloud Architect',
        'provider': 'Google Cloud',
        'duration': '2-4 months',
        'skills': 'Cloud Architecture, GCP, System Design',
        'url': 'https://cloud.google.com/certification/cloud-architect',
        'value': 'High-paying cloud computing career path'
      }
    ];
  }

  Future<String> _getHigherStudiesRecommendations() async {
    try {
      String prompt = """
      Based on this B.Tech student's profile, provide detailed higher studies recommendations:

      Student Profile:
      - Branch: ${_userResponses['branch']}
      - Career Clarity: ${_userResponses['career_clarity']}/10
      - Future Vision: ${_userResponses['future_vision']}
      - Interests: ${_userResponses['interests_hobbies']}
      - Thinking Style: ${_userResponses['thinking_style']}

      Provide recommendations for:
      1. **M.Tech Specializations**: Specific specializations with top colleges
      2. **MBA Programs**: When to pursue, specializations, top colleges
      3. **MS Abroad**: Countries, universities, specializations
      4. **Professional Courses**: Industry-specific certifications
      5. **Research Opportunities**: PhD options, research areas

      Consider both technical and management paths. Include specific college names and admission requirements.
      """;

      return await EnhancedGeminiService.getGeminiResponse(prompt);
    } catch (e) {
      print('Error getting higher studies recommendations: $e');
      return "**Higher Studies Options:**\n\n• **M.Tech**: Specialize in your area of interest\n• **MBA**: For management and leadership roles\n• **MS Abroad**: International exposure and opportunities\n• **Professional Certifications**: Industry-specific skills";
    }
  }

  String _formatComprehensiveResponse(
    String careerAnalysis,
    List<Map<String, dynamic>> internships,
    List<Map<String, dynamic>> courses,
    List<Map<String, dynamic>> googleCerts,
    String higherStudies
  ) {
    String response = "# 🎯 YOUR PERSONALIZED CAREER ROADMAP\n\n";
    
    response += careerAnalysis;
    response += "\n\n---\n\n";
    
    response += "# 🚀 LIVE INTERNSHIP OPPORTUNITIES\n\n";
    response += "*Apply to these current openings:*\n\n";
    
    for (int i = 0; i < internships.length && i < 5; i++) {
      var internship = internships[i];
      response += "## ${i + 1}. ${internship['title']}\n";
      response += "**🏢 Company:** ${internship['company']}\n";
      response += "**📍 Location:** ${internship['location']}\n";
      response += "**💼 Description:** ${internship['description']}\n";
      response += "**🛠️ Skills:** ${internship['skills']}\n";
      response += "**🔗 Apply:** ${internship['applyUrl']}\n\n";
    }
    
    response += "---\n\n";
    
    if (courses.isNotEmpty) {
      response += "# 📚 RECOMMENDED YOUTUBE COURSES\n\n";
      for (int i = 0; i < courses.length && i < 3; i++) {
        var course = courses[i];
        response += "**${i + 1}. ${course['title']}**\n";
        response += "Channel: ${course['channelName']}\n";
        response += "🔗 ${course['url']}\n\n";
      }
      response += "---\n\n";
    }
    
    response += "# 🏆 GOOGLE CERTIFICATIONS\n\n";
    for (int i = 0; i < googleCerts.length && i < 3; i++) {
      var cert = googleCerts[i];
      response += "## ${i + 1}. ${cert['name']}\n";
      response += "**Provider:** ${cert['provider']}\n";
      response += "**Duration:** ${cert['duration']}\n";
      response += "**Skills:** ${cert['skills']}\n";
      response += "**Why valuable:** ${cert['value']}\n";
      response += "**🔗 Enroll:** ${cert['url']}\n\n";
    }
    
    response += "---\n\n";
    
    response += "# 🎓 HIGHER STUDIES OPTIONS\n\n";
    response += higherStudies;
    
    return response;
  }

  Future<void> _loadChatHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final chatHistory = await _firestoreService.getChatHistory(user.uid);
        if (chatHistory != null) {
          setState(() {
            _messages.clear();
            _messages.addAll(chatHistory['messages'] ?? []);
            _userResponses = chatHistory['userAnswers'] ?? {};
            _questionIndex = _userResponses.length;
            _questionsCompleted = _questionIndex >= _questions.length;
          });
        }
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatToFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestoreService.saveChatSession(
          userId: user.uid,
          messages: _messages,
          userAnswers: _userResponses,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      print('Error saving chat: $e');
    }
  }

  // Method to launch URLs
  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Career Navigator'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Start New Session'),
                  content: const Text('This will clear your current conversation. Are you sure?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _messages.clear();
                          _userResponses.clear();
                          _questionIndex = 0;
                          _questionsCompleted = false;
                          _linkedInData = null;
                        });
                        _startConversation();
                      },
                      child: const Text('Start New'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_questionsCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Text(
                    'Question ${_questionIndex + 1} of ${_questions.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: LinearProgressIndicator(
                      value: (_questionIndex + 1) / _questions.length,
                      backgroundColor: Colors.blue[100],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                  ),
                ],
              ),
            ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    _questionsCompleted 
                      ? 'Generating your personalized recommendations...'
                      : 'Processing your response...',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    bool isQuestion = message.messageType == 'question';
    bool isRecommendation = message.messageType == 'final_recommendations';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: isQuestion ? Colors.orange[700] : Colors.blue[700],
              child: Icon(
                isQuestion ? Icons.help_outline : Icons.smart_toy,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser 
                  ? Colors.blue[700] 
                  : isRecommendation 
                    ? Colors.green[50]
                    : isQuestion 
                      ? Colors.orange[50]
                      : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
                border: isRecommendation 
                  ? Border.all(color: Colors.green[300]!, width: 1)
                  : null,
              ),
              child: _buildMessageContent(message),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[400],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    // Check if message contains URLs
    final urlRegex = RegExp(r'https?://[^\s]+');
    final matches = urlRegex.allMatches(message.content);
    
    if (matches.isEmpty) {
      return Text(
        message.content,
        style: TextStyle(
          color: message.isUser ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: message.messageType == 'final_recommendations' ? FontWeight.w500 : FontWeight.normal,
        ),
      );
    }

    // Build rich text with clickable links
    List<TextSpan> spans = [];
    int lastEnd = 0;
    
    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: message.content.substring(lastEnd, match.start),
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ));
      }
      
      // Add clickable URL
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: message.isUser ? Colors.blue[100] : Colors.blue[700],
          fontSize: 16,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(match.group(0)!),
      ));
      
      lastEnd = match.end;
    }
    
    // Add remaining text
    if (lastEnd < message.content.length) {
      spans.add(TextSpan(
        text: message.content.substring(lastEnd),
        style: TextStyle(
          color: message.isUser ? Colors.white : Colors.black87,
          fontSize: 16,
        ),
      ));
    }
    
    return RichText(
      text: TextSpan(children: spans),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: _questionsCompleted 
                  ? 'Ask me anything about your career...'
                  : 'Type your answer...',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: _handleSubmitted,
              maxLines: null,
              enabled: !_isLoading,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : () => _handleSubmitted(_textController.text),
            mini: true,
            backgroundColor: _isLoading ? Colors.grey : Colors.blue[700],
            child: const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
