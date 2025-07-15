
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class DeepDiveScreen extends StatefulWidget {
  const DeepDiveScreen({super.key});

  @override
  State<DeepDiveScreen> createState() => _DeepDiveScreenState();
}

class _DeepDiveScreenState extends State<DeepDiveScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final recommendations = await _firestoreService.getRecommendationsHistory();
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar('Error loading recommendations: $e', isError: true);
    }
  }

  Future<void> _generateCareerPrediction() async {
    setState(() => _isLoading = true);
    try {
      final userProfile = await _firestoreService.getUserProfile() ?? {};
      await _firestoreService.generateCareerPrediction(
        userProfile: userProfile,
        chatContext: "Career prediction requested from Deep Dive",
      );
      _showSnackbar('Career prediction generated!');
      _loadRecommendations();
    } catch (e) {
      _showSnackbar('Error generating prediction: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateComprehensiveAnalysis() async {
    setState(() => _isLoading = true);
    try {
      await _firestoreService.generateComprehensiveAnalysis();
      _showSnackbar('Comprehensive analysis generated!');
      _loadRecommendations();
    } catch (e) {
      _showSnackbar('Error generating analysis: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String recommendationId) async {
    try {
      await _firestoreService.markRecommendationAsRead(recommendationId);
      _showSnackbar('Marked as read');
      _loadRecommendations();
    } catch (e) {
      _showSnackbar('Error marking as read: $e', isError: true);
    }
  }

  Future<void> _deleteRecommendation(String recommendationId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recommendation'),
        content: const Text('Are you sure you want to delete this recommendation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteRecommendation(recommendationId);
        _showSnackbar('Recommendation deleted');
        _loadRecommendations();
      } catch (e) {
        _showSnackbar('Error deleting recommendation: $e', isError: true);
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRecommendations {
    if (_selectedFilter == 'all') return _recommendations;
    return _recommendations.where((rec) => rec['type'] == _selectedFilter).toList();
  }

  // Enhanced reasoning extraction method
  String _extractDetailedReasoning(Map<String, dynamic> recommendation) {
    // First, check if reasoning exists directly
    String directReasoning = recommendation['reasoning']?.toString() ?? '';
    if (directReasoning.isNotEmpty && directReasoning.length > 20) {
      return directReasoning;
    }

    // Try to extract reasoning from the recommendation text
    String fullRecommendation = recommendation['recommendation']?.toString() ?? '';
    
    // Look for reasoning patterns
    List<String> reasoningKeywords = [
      'because', 'since', 'due to', 'given that', 'considering',
      'based on', 'this is recommended because', 'the reason is',
      'this will help', 'given your', 'taking into account',
      'your responses indicate', 'analysis shows', 'this suggests',
      'your profile shows', 'considering your'
    ];

    List<String> sentences = fullRecommendation.split(RegExp(r'[.!?]+'));
    List<String> reasoningSentences = [];

    for (String sentence in sentences) {
      String lowerSentence = sentence.toLowerCase().trim();
      if (lowerSentence.isNotEmpty &&
          reasoningKeywords.any((keyword) => lowerSentence.contains(keyword))) {
        reasoningSentences.add(sentence.trim());
      }
    }

    if (reasoningSentences.isNotEmpty) {
      return '${reasoningSentences.take(3).join('. ').trim()}.';
    }

    // Check user answers for context-based reasoning
    Map<String, dynamic> userAnswers = recommendation['userAnswers'] ?? {};
    if (userAnswers.isNotEmpty) {
      String branch = userAnswers['branch'] ?? 'your field';
      String interests = userAnswers['interests_hobbies'] ?? 'your interests';
      String careerClarity = userAnswers['career_clarity'] ?? 'moderate';
      
      return """
**Why this recommendation was made:**

🎓 **Academic Background**: Based on your $branch background, this path aligns with your technical foundation.

🎯 **Interest Analysis**: Your interests in $interests were key factors in this recommendation.

📊 **Career Clarity**: With a clarity level of $careerClarity/10, this recommendation provides clear direction for your career path.

🤖 **AI Analysis**: The AI analyzed your complete conversation history, responses to career questions, and personal preferences to generate this personalized guidance.
      """;
    }

    // Enhanced fallback reasoning
    String recommendationType = recommendation['type']?.toString() ?? 'general';
    switch (recommendationType) {
      case 'comprehensive_analysis':
        return """
**Comprehensive Analysis Reasoning:**

This recommendation is based on a holistic analysis of your personality, skills, and career goals. The AI considered multiple factors including your academic background, interests, thinking style, and future aspirations to provide comprehensive career guidance.

Key factors analyzed:
• Your responses to career clarity questions
• Personality traits and thinking preferences
• Academic strengths and interests
• Long-term career vision
        """;
      
      case 'career_prediction':
        return """
**Career Prediction Reasoning:**

This career prediction was generated using advanced AI analysis of your profile data. The system evaluated your skills, interests, and career goals to predict the most suitable career paths for your future success.

Analysis included:
• Skills assessment and gap analysis
• Interest-career alignment matching
• Market demand and growth potential
• Personal preference compatibility
        """;
      
      case 'chat_recommendation':
        return """
**Chat-Based Reasoning:**

This recommendation emerged from your conversation with the AI assistant. The system analyzed your responses, questions, and expressed concerns to provide targeted advice for your specific situation.

Conversation insights:
• Your specific questions and concerns
• Expressed interests and preferences
• Career-related doubts and aspirations
• Real-time personalized guidance
        """;
      
      default:
        return """
**AI Recommendation Reasoning:**

This personalized recommendation was generated by analyzing your complete profile and interaction history. The AI considered your unique combination of skills, interests, and goals to provide tailored career guidance.

The recommendation takes into account your individual circumstances and provides actionable advice for your career development.
        """;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deep Dive Analysis'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: _generateComprehensiveAnalysis,
            tooltip: 'Generate Analysis',
          ),
          IconButton(
            icon: const Icon(Icons.work),
            onPressed: _generateCareerPrediction,
            tooltip: 'Career Prediction',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('all', 'All'),
                _buildFilterChip('comprehensive_analysis', 'Analysis'),
                _buildFilterChip('chat_recommendation', 'Chat'),
                _buildFilterChip('career_prediction', 'Career'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecommendations.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRecommendations,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRecommendations.length,
                          itemBuilder: (context, index) {
                            return _buildRecommendationCard(_filteredRecommendations[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
        },
        selectedColor: Colors.deepPurple,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Recommendations Yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate analysis or chat with AI to get recommendations',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _generateComprehensiveAnalysis,
            child: const Text('Generate Analysis'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final timestamp = recommendation['timestamp']?.toDate() ?? DateTime.now();
    final isUnread = recommendation['is_read'] == false;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isUnread ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isUnread ? Border.all(color: Colors.deepPurple, width: 2) : null,
        ),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _getTypeColor(recommendation['type']),
            child: Icon(_getTypeIcon(recommendation['type']), color: Colors.white),
          ),
          title: Text(
            _getTypeTitle(recommendation['type']),
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
              color: isUnread ? Colors.deepPurple : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'New',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommendation Section
                  _buildSection(
                    'AI Recommendation',
                    recommendation['recommendation'] ?? 'No recommendation available',
                    Icons.lightbulb,
                    Colors.amber,
                  ),
                  const SizedBox(height: 16),
                  // Enhanced Reasoning Section
                  _buildSection(
                    'Why This Recommendation?',
                    _extractDetailedReasoning(recommendation),
                    Icons.psychology,
                    Colors.deepPurple,
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (isUnread)
                        TextButton.icon(
                          onPressed: () => _markAsRead(recommendation['id']),
                          icon: const Icon(Icons.mark_email_read, size: 16),
                          label: const Text('Mark as Read'),
                          style: TextButton.styleFrom(foregroundColor: Colors.green),
                        ),
                      TextButton.icon(
                        onPressed: () => _deleteRecommendation(recommendation['id']),
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          onExpansionChanged: (expanded) {
            if (expanded && isUnread) {
              _markAsRead(recommendation['id']);
            }
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'comprehensive_analysis':
        return Colors.deepPurple;
      case 'chat_recommendation':
        return Colors.blue;
      case 'career_prediction':
        return Colors.orange;
      default:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'comprehensive_analysis':
        return Icons.psychology;
      case 'chat_recommendation':
        return Icons.chat_bubble;
      case 'career_prediction':
        return Icons.work;
      default:
        return Icons.lightbulb;
    }
  }

  String _getTypeTitle(String? type) {
    switch (type) {
      case 'comprehensive_analysis':
        return 'Comprehensive Analysis';
      case 'chat_recommendation':
        return 'Chat Recommendation';
      case 'career_prediction':
        return 'Career Prediction';
      default:
        return 'AI Recommendation';
    }
  }
}
