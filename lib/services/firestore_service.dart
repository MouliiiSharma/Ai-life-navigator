import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

// Response Models
class EnhancedChatResponse {
  final String geminiResponse;
  final List<CareerPrediction> careerPaths;
  final List<InternshipOpportunity> internships;
  final List<YouTubeCourse> courses;
  final List<GoogleCertification> certifications;
  final DateTime timestamp;

  EnhancedChatResponse({
    required this.geminiResponse,
    required this.careerPaths,
    required this.internships,
    required this.courses,
    required this.certifications,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'geminiResponse': geminiResponse,
      'careerPaths': careerPaths.map((e) => e.toJson()).toList(),
      'internships': internships.map((e) => e.toJson()).toList(),
      'courses': courses.map((e) => e.toJson()).toList(),
      'certifications': certifications.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class CareerPrediction {
  final String careerPath;
  final double confidence;
  final String description;
  final List<String> requiredSkills;

  CareerPrediction({
    required this.careerPath,
    required this.confidence,
    required this.description,
    required this.requiredSkills,
  });

  Map<String, dynamic> toJson() {
    return {
      'careerPath': careerPath,
      'confidence': confidence,
      'description': description,
      'requiredSkills': requiredSkills,
    };
  }
}

class InternshipOpportunity {
  final String title;
  final String company;
  final String location;
  final String url;
  final String description;
  final String type; // remote, onsite, hybrid

  InternshipOpportunity({
    required this.title,
    required this.company,
    required this.location,
    required this.url,
    required this.description,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'url': url,
      'description': description,
      'type': type,
    };
  }
}

class YouTubeCourse {
  final String title;
  final String channelName;
  final String videoId;
  final String thumbnail;
  final String duration;
  final String description;

  YouTubeCourse({
    required this.title,
    required this.channelName,
    required this.videoId,
    required this.thumbnail,
    required this.duration,
    required this.description,
  });

  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'channelName': channelName,
      'videoId': videoId,
      'thumbnail': thumbnail,
      'duration': duration,
      'description': description,
    };
  }
}

class GoogleCertification {
  final String title;
  final String provider;
  final String url;
  final String description;
  final String estimatedTime;
  final bool isFree;

  GoogleCertification({
    required this.title,
    required this.provider,
    required this.url,
    required this.description,
    required this.estimatedTime,
    required this.isFree,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'provider': provider,
      'url': url,
      'description': description,
      'estimatedTime': estimatedTime,
      'isFree': isFree,
    };
  }
}

class UserProfile {
  final String branch;
  final String skills;
  final double cgpa;
  final String interests;
  final String goals;
  final String whyBtech;

  UserProfile({
    required this.branch,
    required this.skills,
    required this.cgpa,
    required this.interests,
    required this.goals,
    required this.whyBtech,
  });
}

class EnhancedGeminiService {
  static const String _geminiApiKey = 'AIzaSyAolU9wBgaWS0Gt7HAWIpDKXlc695_mlzU';
  static const String _youtubeApiKey = 'AIzaSyCJ8MC7K87Kt-uvUrzRQ1mnWs1iQ7_QawM';
  static const String _rapidApiKey = '47026e8cd8mshe608e5ef002f184p15c68fjsne74e4980964d';
  
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent?key=$_geminiApiKey';
  static const String _youtubeUrl = 'https://www.googleapis.com/youtube/v3/search';
  static const String _linkedinUrl = 'https://fresh-linkedin-scraper-api.p.rapidapi.com/api/v1/search/jobs';

  // Main method for comprehensive career guidance
  static Future<EnhancedChatResponse> getComprehensiveGuidance(
    String userQuery, 
    UserProfile userProfile
  ) async {
    try {
      // Step 1: Get enhanced Gemini response with career analysis
      final geminiResponse = await _getEnhancedGeminiResponse(userQuery, userProfile);
      
      // Step 2: Extract career keywords and predictions from response
      final careerPredictions = await _extractCareerPredictions(geminiResponse);
      
      // Step 3: Get career keywords for API searches
      final careerKeywords = _extractCareerKeywords(careerPredictions);
      
      // Step 4: Make parallel API calls
      final futures = await Future.wait([
        _getInternshipOpportunities(careerKeywords),
        _getYouTubeCourses(careerKeywords),
        _getGoogleCertifications(careerKeywords),
      ]);
      
      final internships = futures[0] as List<InternshipOpportunity>;
      final courses = futures[1] as List<YouTubeCourse>;
      final certifications = futures[2] as List<GoogleCertification>;
      
      return EnhancedChatResponse(
        geminiResponse: geminiResponse,
        careerPaths: careerPredictions,
        internships: internships,
        courses: courses,
        certifications: certifications,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error in comprehensive guidance: $e');
      // Return basic response with error handling
      return EnhancedChatResponse(
        geminiResponse: 'Sorry, I encountered an error while processing your request. Please try again.',
        careerPaths: [],
        internships: [],
        courses: [],
        certifications: [],
        timestamp: DateTime.now(),
      );
    }
  }

  // Enhanced Gemini response with career analysis
  static Future<String> _getEnhancedGeminiResponse(String userQuery, UserProfile userProfile) async {
    final enhancedPrompt = '''
    You are an AI Life Navigator for B.Tech students. Based on the user profile and query, provide comprehensive career guidance.

    User Profile:
    - Branch: ${userProfile.branch}
    - Skills: ${userProfile.skills}
    - CGPA: ${userProfile.cgpa}
    - Interests: ${userProfile.interests}
    - Goals: ${userProfile.goals}
    - Why B.Tech: ${userProfile.whyBtech}

    User Query: $userQuery

    Please provide:
    1. Career path analysis and recommendations
    2. Specific job roles that match their profile
    3. Skills they should develop
    4. Industry insights and trends
    5. Actionable next steps

    Format your response to be conversational and encouraging. Include specific career paths like "Software Engineer", "Data Scientist", "Product Manager", etc.
    ''';

    final response = await http.post(
      Uri.parse(_geminiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": enhancedPrompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "Sorry, couldn't understand the response.";
    } else {
      throw Exception('Failed to fetch response from Gemini');
    }
  }

  // Extract career predictions from Gemini response
  static Future<List<CareerPrediction>> _extractCareerPredictions(String geminiResponse) async {
    final analysisPrompt = '''
    Analyze this career guidance response and extract specific career paths mentioned:
    
    "$geminiResponse"
    
    Return ONLY a JSON array of career predictions in this exact format:
    [
      {
        "careerPath": "Software Engineer",
        "confidence": 0.85,
        "description": "Brief description of the role",
        "requiredSkills": ["Java", "Python", "Problem Solving"]
      }
    ]
    
    Include 3-5 career paths with confidence scores between 0.1 and 1.0.
    ''';

    try {
      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": analysisPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
        // Extract JSON from response
        final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(responseText);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final List<dynamic> careerData = jsonDecode(jsonStr);
          
          return careerData.map((item) => CareerPrediction(
            careerPath: item['careerPath'] ?? 'Unknown',
            confidence: (item['confidence'] ?? 0.5).toDouble(),
            description: item['description'] ?? 'No description available',
            requiredSkills: List<String>.from(item['requiredSkills'] ?? []),
          )).toList();
        }
      }
    } catch (e) {
      print('Error extracting career predictions: $e');
    }
    
    // Fallback career predictions
    return [
      CareerPrediction(
        careerPath: 'Software Engineer',
        confidence: 0.8,
        description: 'Develop software applications and systems',
        requiredSkills: ['Programming', 'Problem Solving', 'System Design'],
      ),
    ];
  }

  // Extract career keywords for API searches
  static List<String> _extractCareerKeywords(List<CareerPrediction> predictions) {
    final keywords = <String>[];
    for (final prediction in predictions) {
      keywords.add(prediction.careerPath);
      keywords.addAll(prediction.requiredSkills);
    }
    return keywords.take(10).toList(); // Limit to top 10 keywords
  }

  // Get internship opportunities from LinkedIn API
  static Future<List<InternshipOpportunity>> _getInternshipOpportunities(List<String> keywords) async {
    final internships = <InternshipOpportunity>[];
    
    for (final keyword in keywords.take(3)) { // Limit API calls
      try {
        final response = await http.get(
          Uri.parse('$_linkedinUrl?keywords=$keyword&location=India&job_type=internship'),
          headers: {
            'X-RapidAPI-Key': _rapidApiKey,
            'X-RapidAPI-Host': 'fresh-linkedin-scraper-api.p.rapidapi.com',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final jobs = data['data']?['jobs'] ?? [];
          
          for (final job in jobs.take(2)) { // Limit to 2 per keyword
            internships.add(InternshipOpportunity(
              title: job['title'] ?? 'Internship Opportunity',
              company: job['company']?['name'] ?? 'Company',
              location: job['location'] ?? 'Location not specified',
              url: job['url'] ?? 'https://linkedin.com',
              description: job['description'] ?? 'No description available',
              type: job['workplace_type'] ?? 'Not specified',
            ));
          }
        }
      } catch (e) {
        print('Error fetching internships for $keyword: $e');
      }
    }
    
    // Ensure we have at least 5 internships (add mock data if needed)
    if (internships.length < 5) {
      internships.addAll(_getMockInternships(5 - internships.length));
    }
    
    return internships.take(5).toList();
  }

  // Get YouTube courses
  static Future<List<YouTubeCourse>> _getYouTubeCourses(List<String> keywords) async {
    final courses = <YouTubeCourse>[];
    
    for (final keyword in keywords.take(3)) {
      try {
        final searchQuery = '$keyword tutorial course';
        final response = await http.get(
          Uri.parse('$_youtubeUrl?part=snippet&q=$searchQuery&type=video&maxResults=2&key=$_youtubeApiKey'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final videos = data['items'] ?? [];
          
          for (final video in videos) {
            courses.add(YouTubeCourse(
              title: video['snippet']['title'] ?? 'Course',
              channelName: video['snippet']['channelTitle'] ?? 'Channel',
              videoId: video['id']['videoId'] ?? '',
              thumbnail: video['snippet']['thumbnails']['medium']['url'] ?? '',
              duration: 'Duration not available',
              description: video['snippet']['description'] ?? 'No description',
            ));
          }
        }
      } catch (e) {
        print('Error fetching YouTube courses for $keyword: $e');
      }
    }
    
    return courses.take(5).toList();
  }

  // Get Google certifications using Gemini
  static Future<List<GoogleCertification>> _getGoogleCertifications(List<String> keywords) async {
    final certificationPrompt = '''
    Based on these career keywords: ${keywords.join(', ')}
    
    Provide 3-5 relevant FREE Google certifications and courses. Return ONLY JSON in this format:
    [
      {
        "title": "Google Data Analytics Professional Certificate",
        "provider": "Google via Coursera",
        "url": "https://coursera.org/professional-certificates/google-data-analytics",
        "description": "Learn data analytics fundamentals",
        "estimatedTime": "3-6 months",
        "isFree": true
      }
    ]
    
    Include Google Career Certificates, Google Cloud certifications, and Google Digital Marketing courses.
    ''';

    try {
      final response = await http.post(
        Uri.parse(_geminiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": certificationPrompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        
        final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(responseText);
        if (jsonMatch != null) {
          final jsonStr = jsonMatch.group(0)!;
          final List<dynamic> certData = jsonDecode(jsonStr);
          
          return certData.map((item) => GoogleCertification(
            title: item['title'] ?? 'Google Certification',
            provider: item['provider'] ?? 'Google',
            url: item['url'] ?? 'https://google.com',
            description: item['description'] ?? 'No description available',
            estimatedTime: item['estimatedTime'] ?? 'Not specified',
            isFree: item['isFree'] ?? true,
          )).toList();
        }
      }
    } catch (e) {
      print('Error fetching Google certifications: $e');
    }
    
    // Fallback certifications
    return [
      GoogleCertification(
        title: 'Google Career Certificates',
        provider: 'Google via Coursera',
        url: 'https://grow.google/certificates/',
        description: 'Professional certificates in high-growth fields',
        estimatedTime: '3-6 months',
        isFree: true,
      ),
    ];
  }

  // Mock internships for fallback
  static List<InternshipOpportunity> _getMockInternships(int count) {
    return List.generate(count, (index) => InternshipOpportunity(
      title: 'Software Development Internship',
      company: 'Tech Company ${index + 1}',
      location: 'India',
      url: 'https://linkedin.com/jobs/internship-${index + 1}',
      description: 'Exciting internship opportunity in software development',
      type: 'Hybrid',
    ));
  }

  // Simple Gemini response (for backward compatibility)
  static Future<String> getGeminiResponse(String prompt) async {
    final response = await http.post(
      Uri.parse(_geminiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ??
          "Sorry, couldn't understand the response.";
    } else {
      print("Gemini error: ${response.body}");
      throw Exception('Failed to fetch response from Gemini');
    }
  }
}Future<void> saveChatMessage(String prompt, String response) async {
  await FirebaseFirestore.instance.collection('chatMessages').add({
    'prompt': prompt,
    'response': response,
    'timestamp': FieldValue.serverTimestamp(),
  });
}

Future<void> saveRecommendation(Map<String, dynamic> recommendation) async {
  await FirebaseFirestore.instance.collection('recommendations').add({
    ...recommendation,
    'timestamp': FieldValue.serverTimestamp(),
  });
}


