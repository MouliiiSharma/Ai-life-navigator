// import 'package:ai_life_navigator/screens/chat_screen.dart';
// import 'package:ai_life_navigator/services/firestore_service.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class DeepDiveScreen extends StatefulWidget {
//   const DeepDiveScreen({super.key});

//   @override
//   State<DeepDiveScreen> createState() => _DeepDiveScreenState();
// }

// class _DeepDiveScreenState extends State<DeepDiveScreen> with SingleTickerProviderStateMixin {
//   final _firestoreService = FirestoreService();
//   List<Map<String, dynamic>> _recommendations = [];
//   List<Map<String, dynamic>> _filteredRecommendations = [];
//   bool _isLoading = true;
//   String _selectedFilter = 'all';
//   final TextEditingController _searchController = TextEditingController();
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadRecommendations();
//   }

//   Future<void> _loadRecommendations() async {
//     setState(() => _isLoading = true);
//     try {
//       final recommendations = await _firestoreService.getRecommendationsHistory();
//       setState(() {
//         _recommendations = recommendations;
//         _filteredRecommendations = recommendations;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showErrorSnackbar('Error loading recommendations: $e');
//     }
//   }

//   void _filterRecommendations() {
//     setState(() {
//       _filteredRecommendations = _recommendations.where((rec) {
//         // Search filter
//         bool matchesSearch = _searchController.text.isEmpty ||
//             rec['recommendation'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
//             rec['reasoning'].toString().toLowerCase().contains(_searchController.text.toLowerCase());

//         // Type filter
//         bool matchesType = _selectedFilter == 'all' || rec['type'] == _selectedFilter;

//         return matchesSearch && matchesType;
//       }).toList();
//     });
//   }

//   void _showErrorSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.red,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showSuccessSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: Colors.green,
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   // Add this method to trigger career prediction
//   Future<void> _generateCareerPrediction() async {
//     setState(() => _isLoading = true);
//     try {
//       final prediction = await _firestoreService.generateCareerPrediction(
//         userProfile: await _firestoreService.getUserProfile() ?? {},
//         chatContext: "Career prediction requested from Deep Dive screen",
//       );
//       _showSuccessSnackbar('Career prediction generated!');
//       _loadRecommendations(); // Refresh the list
//     } catch (e) {
//       _showErrorSnackbar('Error generating prediction: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   // Add this method to trigger comprehensive analysis
//   Future<void> _generateComprehensiveAnalysis() async {
//     setState(() => _isLoading = true);
//     try {
//       final analysis = await _firestoreService.generateComprehensiveAnalysis();
//       _showSuccessSnackbar('Comprehensive analysis generated!');
//       _loadRecommendations(); // Refresh the list
//     } catch (e) {
//       _showErrorSnackbar('Error generating analysis: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Deep Dive Analysis'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         bottom: TabBar(
//           controller: _tabController,
//           indicatorColor: Colors.white,
//           labelColor: Colors.white,
//           unselectedLabelColor: Colors.white70,
//           tabs: [
//             Tab(icon: Icon(Icons.analytics), text: 'All'),
//             Tab(icon: Icon(Icons.lightbulb), text: 'AI Analysis'),
//             Tab(icon: Icon(Icons.chat), text: 'Chat Insights'),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           // Search and Filter Section
//           Container(
//             padding: EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.deepPurple.shade50,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // Search Bar
//                 TextField(
//                   controller: _searchController,
//                   decoration: InputDecoration(
//                     hintText: 'Search recommendations...',
//                     prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(25),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: Colors.white,
//                     contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                   ),
//                   onChanged: (value) => _filterRecommendations(),
//                 ),
//                 SizedBox(height: 12),
//                 // Filter Chips
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       _buildFilterChip('all', 'All', Icons.all_inclusive),
//                       _buildFilterChip('comprehensive_analysis', 'Complete Analysis', Icons.psychology),
//                       _buildFilterChip('chat_recommendation', 'Chat Insights', Icons.chat_bubble),
//                       _buildFilterChip('legacy', 'Legacy', Icons.history),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
          
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildAllRecommendations(),
//                 _buildFilteredView('comprehensive_analysis'),
//                 _buildFilteredView('chat_recommendation'),
//               ],
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _loadRecommendations,
//         backgroundColor: Colors.deepPurple,
//         tooltip: 'Refresh Recommendations',
//         child: Icon(Icons.refresh, color: Colors.white),
//       ),
//     );
//   }

//   Widget _buildFilterChip(String value, String label, IconData icon) {
//     bool isSelected = _selectedFilter == value;
//     return Padding(
//       padding: EdgeInsets.only(right: 8),
//       child: FilterChip(
//         avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.deepPurple),
//         label: Text(label),
//         selected: isSelected,
//         onSelected: (selected) {
//           setState(() {
//             _selectedFilter = value;
//             _filterRecommendations();
//           });
//         },
//         selectedColor: Colors.deepPurple,
//         backgroundColor: Colors.white,
//         labelStyle: TextStyle(
//           color: isSelected ? Colors.white : Colors.deepPurple,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }

//   Widget _buildAllRecommendations() {
//     if (_isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(color: Colors.deepPurple),
//             SizedBox(height: 16),
//             Text('Loading your recommendations...', style: TextStyle(color: Colors.grey.shade600)),
//           ],
//         ),
//       );
//     }

//     if (_filteredRecommendations.isEmpty) {
//       return _buildEmptyState();
//     }

//     return RefreshIndicator(
//       onRefresh: _loadRecommendations,
//       color: Colors.deepPurple,
//       child: ListView.builder(
//         padding: EdgeInsets.all(16),
//         itemCount: _filteredRecommendations.length,
//         itemBuilder: (context, index) {
//           return _buildRecommendationCard(_filteredRecommendations[index], index);
//         },
//       ),
//     );
//   }

//   Widget _buildFilteredView(String type) {
//     final filteredByType = _recommendations.where((rec) => rec['type'] == type).toList();
    
//     if (_isLoading) {
//       return Center(child: CircularProgressIndicator(color: Colors.deepPurple));
//     }

//     if (filteredByType.isEmpty) {
//       return _buildEmptyState(specificType: type);
//     }

//     return ListView.builder(
//       padding: EdgeInsets.all(16),
//       itemCount: filteredByType.length,
//       itemBuilder: (context, index) {
//         return _buildRecommendationCard(filteredByType[index], index);
//       },
//     );
//   }

//   Widget _buildEmptyState({String? specificType}) {
//     String message;
//     String submessage;
//     IconData icon;
    
//     if (specificType != null) {
//       switch (specificType) {
//         case 'comprehensive_analysis':
//           message = 'No Complete Analysis Yet';
//           submessage = 'Complete the AI onboarding to get your first comprehensive analysis!';
//           icon = Icons.psychology;
//           break;
//         case 'chat_recommendation':
//           message = 'No Chat Insights Yet';
//           submessage = 'Start chatting with the AI to get personalized recommendations!';
//           icon = Icons.chat_bubble;
//           break;
//         default:
//           message = 'No Recommendations Found';
//           submessage = 'Try interacting with the AI assistant to generate insights.';
//           icon = Icons.lightbulb_outline;
//       }
//     } else {
//       message = _searchController.text.isNotEmpty ? 'No Results Found' : 'No Recommendations Yet';
//       submessage = _searchController.text.isNotEmpty 
//           ? 'Try adjusting your search terms.' 
//           : 'Start chatting with the AI to get personalized recommendations!';
//       icon = Icons.search_off;
//     }

//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(icon, size: 80, color: Colors.grey.shade400),
//           SizedBox(height: 16),
//           Text(
//             message,
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           SizedBox(height: 8),
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 32),
//             child: Text(
//               submessage,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey.shade500,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           SizedBox(height: 24),
//           ElevatedButton.icon(
//             onPressed: () => Navigator.pop(context),
//             icon: Icon(Icons.chat),
//             label: Text('Go to AI Assistant'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.deepPurple,
//               foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendationCard(Map<String, dynamic> recommendation, int index) {
//     final timestamp = recommendation['timestamp']?.toDate() ?? DateTime.now();
//     final isUnread = recommendation['is_read'] == false;
    
//     return Card(
//       margin: EdgeInsets.only(bottom: 16),
//       elevation: isUnread ? 4 : 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(12),
//           border: isUnread ? Border.all(color: Colors.deepPurple, width: 2) : null,
//         ),
//         child: ExpansionTile(
//           leading: CircleAvatar(
//             backgroundColor: _getTypeColor(recommendation['type']),
//             child: Icon(_getTypeIcon(recommendation['type']), color: Colors.white, size: 20),
//           ),
//           title: Text(
//             _getTypeTitle(recommendation['type']),
//             style: TextStyle(
//               fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
//               color: isUnread ? Colors.deepPurple : Colors.black87,
//             ),
//           ),
//           subtitle: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
//                 style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
//               ),
//               if (isUnread) 
//                 Container(
//                   margin: EdgeInsets.only(top: 4),
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                   decoration: BoxDecoration(
//                     color: Colors.deepPurple,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Text(
//                     'New',
//                     style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//             ],
//           ),
//           children: [
//             Container(
//               width: double.infinity,
//               padding: EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Recommendation Section
//                   _buildSection(
//                     'AI Recommendation',
//                     recommendation['recommendation'] ?? 'No recommendation available',
//                     Icons.lightbulb,
//                     Colors.amber,
//                   ),
                  
//                   SizedBox(height: 16),
                  
//                   // Reasoning Section
//                   _buildSection(
//                     'Why This Recommendation?',
//                     _extractDetailedReasoning(recommendation),
//                     Icons.psychology,
//                     Colors.deepPurple,
//                   ),
                  
//                   SizedBox(height: 16),
                  
//                   // Debug Section (Remove this in production)
//                   _buildDebugSection(recommendation),
                  
//                   SizedBox(height: 16),
                  
//                   // Action Buttons
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       if (isUnread)
//                         TextButton.icon(
//                           onPressed: () => _markAsRead(recommendation['id']),
//                           icon: Icon(Icons.mark_email_read, size: 16),
//                           label: Text('Mark as Read'),
//                           style: TextButton.styleFrom(foregroundColor: Colors.green),
//                         ),
//                       TextButton.icon(
//                         onPressed: () => _shareRecommendation(recommendation),
//                         icon: Icon(Icons.share, size: 16),
//                         label: Text('Share'),
//                         style: TextButton.styleFrom(foregroundColor: Colors.blue),
//                       ),
//                       TextButton.icon(
//                         onPressed: () => _deleteRecommendation(recommendation['id']),
//                         icon: Icon(Icons.delete, size: 16),
//                         label: Text('Delete'),
//                         style: TextButton.styleFrom(foregroundColor: Colors.red),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//           onExpansionChanged: (expanded) {
//             if (expanded && isUnread) {
//               _markAsRead(recommendation['id']);
//             }
//           },
//         ),
//       ),
//     );
//   }

//   // Debug section to see what data is actually coming from Firestore
//   Widget _buildDebugSection(Map<String, dynamic> recommendation) {
//     return ExpansionTile(
//       title: Text(
//         'Debug Info (Remove in Production)',
//         style: TextStyle(fontSize: 12, color: Colors.red),
//       ),
//       children: [
//         Container(
//           padding: EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: Colors.red.shade50,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text('Raw Data:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
//               SizedBox(height: 8),
//               Text('reasoning: ${recommendation['reasoning']}', style: TextStyle(fontSize: 11)),
//               SizedBox(height: 4),
//               Text('user_profile: ${recommendation['user_profile']}', style: TextStyle(fontSize: 11)),
//               SizedBox(height: 4),
//               Text('type: ${recommendation['type']}', style: TextStyle(fontSize: 11)),
//               SizedBox(height: 4),
//               Text('All keys: ${recommendation.keys.toList()}', style: TextStyle(fontSize: 11)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSection(String title, String content, IconData icon, Color color) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Icon(icon, color: color, size: 18),
//             SizedBox(width: 8),
//             Text(
//               title,
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 16,
//                 color: color,
//               ),
//             ),
//           ],
//         ),
//         SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           padding: EdgeInsets.all(12),
//           decoration: BoxDecoration(
//             color: color.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: color.withOpacity(0.3)),
//           ),
//           child: Text(
//             content,
//             style: TextStyle(
//               fontSize: 14,
//               height: 1.5,
//               color: Colors.black87,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   String _extractDetailedReasoning(Map<String, dynamic> recommendation) {
//     // First, let's try to get the raw reasoning
//     String reasoning = recommendation['reasoning']?.toString() ?? '';
    
//     // Remove common prefixes that might be added by the system
//     reasoning = reasoning.replaceAll('Generated by deep learning analysis:', '').trim();
//     reasoning = reasoning.replaceAll('Based on comprehensive analysis:', '').trim();
    
//     // If we have actual reasoning content, use it
//     if (reasoning.isNotEmpty && reasoning.length > 10) {
//       return reasoning;
//     }
    
//     // Try to extract from the recommendation text itself
//     String fullRecommendation = recommendation['recommendation']?.toString() ?? '';
    
//     // Look for reasoning patterns in the recommendation
//     List<String> reasoningPatterns = [
//       'because', 'since', 'due to', 'given that', 'considering',
//       'based on', 'this is because', 'the reason is', 'this will help',
//       'given your', 'considering your', 'taking into account'
//     ];
    
//     List<String> sentences = fullRecommendation.split(RegExp(r'[.!?]+'));
//     List<String> reasoningSentences = [];
    
//     for (String sentence in sentences) {
//       String lowerSentence = sentence.toLowerCase().trim();
//       if (lowerSentence.isNotEmpty && 
//           reasoningPatterns.any((pattern) => lowerSentence.contains(pattern))) {
//         reasoningSentences.add(sentence.trim());
//       }
//     }
    
//     if (reasoningSentences.isNotEmpty) {
//       return '${reasoningSentences.join('. ').trim()}.';
//     }
    
//     // If still no reasoning found, check other fields
//     String userProfile = recommendation['user_profile']?.toString() ?? '';    
//     // Return a meaningful fallback based on available data
//     if (userProfile.isNotEmpty && 
//         userProfile != "Legacy deep dive entry" && 
//         userProfile != "Follow-up chat interaction") {
//       return "This recommendation was generated based on your profile analysis and conversation history. The AI considered your specific situation, goals, and preferences to provide personalized advice.";
//     }
    
//     // Last resort fallback
//     return "The AI analyzed your conversation and context to generate this personalized recommendation. For more detailed reasoning, please ensure the AI provides explanations when making recommendations.";
//   }

//   Color _getTypeColor(String? type) {
//     switch (type) {
//       case 'comprehensive_analysis':
//         return Colors.deepPurple;
//       case 'chat_recommendation':
//         return Colors.blue;
//       case 'legacy':
//         return Colors.grey;
//       default:
//         return Colors.teal;
//     }
//   }

//   IconData _getTypeIcon(String? type) {
//     switch (type) {
//       case 'comprehensive_analysis':
//         return Icons.psychology;
//       case 'chat_recommendation':
//         return Icons.chat_bubble;
//       case 'legacy':
//         return Icons.history;
//       default:
//         return Icons.lightbulb;
//     }
//   }

//   String _getTypeTitle(String? type) {
//     switch (type) {
//       case 'comprehensive_analysis':
//         return 'Complete Personality Analysis';
//       case 'chat_recommendation':
//         return 'Chat-based Recommendation';
//       case 'legacy':
//         return 'Legacy Recommendation';
//       default:
//         return 'AI Recommendation';
//     }
//   }

//   Future<void> _markAsRead(String recommendationId) async {
//     try {
//       await _firestoreService.markRecommendationAsRead(recommendationId);
//       _showSuccessSnackbar('Marked as read');
//       _loadRecommendations(); // Refresh the list
//     } catch (e) {
//       _showErrorSnackbar('Error marking as read: $e');
//     }
//   }

//   Future<void> _shareRecommendation(Map<String, dynamic> recommendation) async {
//     // TODO: Implement share functionality
//     // For now, just show a placeholder
//     _showSuccessSnackbar('Share feature coming soon!');
//   }

//   Future<void> _deleteRecommendation(String recommendationId) async {
//     // Show confirmation dialog
//     bool? confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Delete Recommendation'),
//         content: Text('Are you sure you want to delete this recommendation? This action cannot be undone.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: TextButton.styleFrom(foregroundColor: Colors.red),
//             child: Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await _firestoreService.deleteRecommendation(recommendationId);
//         _showSuccessSnackbar('Recommendation deleted');
//         _loadRecommendations(); // Refresh the list
//       } catch (e) {
//         _showErrorSnackbar('Error deleting recommendation: $e');
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     _tabController.dispose();
//     super.dispose();
//   }
// }









// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../services/firestore_service.dart';

// class DeepDiveScreen extends StatefulWidget {
//   const DeepDiveScreen({super.key});

//   @override
//   State<DeepDiveScreen> createState() => _DeepDiveScreenState();
// }

// class _DeepDiveScreenState extends State<DeepDiveScreen> {
//   final _firestoreService = FirestoreService();
//   List<Map<String, dynamic>> _recommendations = [];
//   bool _isLoading = true;
//   String _selectedFilter = 'all';

//   @override
//   void initState() {
//     super.initState();
//     _loadRecommendations();
//   }

//   Future<void> _loadRecommendations() async {
//     setState(() => _isLoading = true);
//     try {
//       final recommendations = await _firestoreService.getRecommendationsHistory();
//       setState(() {
//         _recommendations = recommendations;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showSnackbar('Error loading recommendations: $e', isError: true);
//     }
//   }

//   Future<void> _generateCareerPrediction() async {
//     setState(() => _isLoading = true);
//     try {
//       final userProfile = await _firestoreService.getUserProfile() ?? {};
//       await _firestoreService.generateCareerPrediction(
//         userProfile: userProfile,
//         chatContext: "Career prediction requested",
//       );
//       _showSnackbar('Career prediction generated!');
//       _loadRecommendations();
//     } catch (e) {
//       _showSnackbar('Error generating prediction: $e', isError: true);
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _generateComprehensiveAnalysis() async {
//     setState(() => _isLoading = true);
//     try {
//       await _firestoreService.generateComprehensiveAnalysis();
//       _showSnackbar('Comprehensive analysis generated!');
//       _loadRecommendations();
//     } catch (e) {
//       _showSnackbar('Error generating analysis: $e', isError: true);
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _markAsRead(String recommendationId) async {
//     try {
//       await _firestoreService.markRecommendationAsRead(recommendationId);
//       _showSnackbar('Marked as read');
//       _loadRecommendations();
//     } catch (e) {
//       _showSnackbar('Error marking as read: $e', isError: true);
//     }
//   }

//   Future<void> _deleteRecommendation(String recommendationId) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Delete Recommendation'),
//         content: const Text('Are you sure you want to delete this recommendation?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text('Delete'),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await _firestoreService.deleteRecommendation(recommendationId);
//         _showSnackbar('Recommendation deleted');
//         _loadRecommendations();
//       } catch (e) {
//         _showSnackbar('Error deleting recommendation: $e', isError: true);
//       }
//     }
//   }

//   void _showSnackbar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//       ),
//     );
//   }

//   List<Map<String, dynamic>> get _filteredRecommendations {
//     if (_selectedFilter == 'all') return _recommendations;
//     return _recommendations.where((rec) => rec['type'] == _selectedFilter).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Deep Dive Analysis'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.psychology),
//             onPressed: _generateComprehensiveAnalysis,
//             tooltip: 'Generate Analysis',
//           ),
//           IconButton(
//             icon: const Icon(Icons.work),
//             onPressed: _generateCareerPrediction,
//             tooltip: 'Career Prediction',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Filter Bar
//           Container(
//             height: 50,
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 _buildFilterChip('all', 'All'),
//                 _buildFilterChip('comprehensive_analysis', 'Analysis'),
//                 _buildFilterChip('chat_recommendation', 'Chat'),
//                 _buildFilterChip('career_prediction', 'Career'),
//               ],
//             ),
//           ),
//           // Content
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _filteredRecommendations.isEmpty
//                     ? _buildEmptyState()
//                     : RefreshIndicator(
//                         onRefresh: _loadRecommendations,
//                         child: ListView.builder(
//                           padding: const EdgeInsets.all(16),
//                           itemCount: _filteredRecommendations.length,
//                           itemBuilder: (context, index) {
//                             return _buildRecommendationCard(_filteredRecommendations[index]);
//                           },
//                         ),
//                       ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterChip(String value, String label) {
//     final isSelected = _selectedFilter == value;
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text(label),
//         selected: isSelected,
//         onSelected: (selected) {
//           setState(() => _selectedFilter = value);
//         },
//         selectedColor: Colors.deepPurple,
//         backgroundColor: Colors.grey[200],
//         labelStyle: TextStyle(
//           color: isSelected ? Colors.white : Colors.black,
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
//           const SizedBox(height: 16),
//           Text(
//             'No Recommendations Yet',
//             style: TextStyle(fontSize: 20, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Generate analysis or chat with AI to get recommendations',
//             style: TextStyle(color: Colors.grey[500]),
//           ),
//           const SizedBox(height: 24),
//           ElevatedButton(
//             onPressed: _generateComprehensiveAnalysis,
//             child: const Text('Generate Analysis'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
//     final timestamp = recommendation['timestamp']?.toDate() ?? DateTime.now();
//     final isUnread = recommendation['is_read'] == false;

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: isUnread ? 4 : 2,
//       child: ExpansionTile(
//         leading: CircleAvatar(
//           backgroundColor: _getTypeColor(recommendation['type']),
//           child: Icon(_getTypeIcon(recommendation['type']), color: Colors.white),
//         ),
//         title: Text(
//           _getTypeTitle(recommendation['type']),
//           style: TextStyle(
//             fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
//           ),
//         ),
//         subtitle: Text(
//           DateFormat('MMM dd, yyyy - HH:mm').format(timestamp),
//           style: TextStyle(color: Colors.grey[600]),
//         ),
//         trailing: isUnread
//             ? Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color: Colors.red,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Text(
//                   'New',
//                   style: TextStyle(color: Colors.white, fontSize: 12),
//                 ),
//               )
//             : null,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Recommendation:',
//                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(recommendation['recommendation'] ?? 'No recommendation available'),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Reasoning:',
//                   style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(recommendation['reasoning'] ?? 'No reasoning provided'),
//                 const SizedBox(height: 16),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     if (isUnread)
//                       TextButton.icon(
//                         onPressed: () => _markAsRead(recommendation['id']),
//                         icon: const Icon(Icons.mark_email_read, size: 16),
//                         label: const Text('Mark as Read'),
//                       ),
//                     TextButton.icon(
//                       onPressed: () => _deleteRecommendation(recommendation['id']),
//                       icon: const Icon(Icons.delete, size: 16),
//                       label: const Text('Delete'),
//                       style: TextButton.styleFrom(foregroundColor: Colors.red),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//         onExpansionChanged: (expanded) {
//           if (expanded && isUnread) {
//             _markAsRead(recommendation['id']);
//           }
//         },
//       ),
//     );
//   }

//   Color _getTypeColor(String? type) {
//     switch (type) {
//       case 'comprehensive_analysis':
//         return Colors.deepPurple;
//       case 'chat_recommendation':
//         return Colors.blue;
//       case 'career_prediction':
//         return Colors.orange;
//       default:
//         return Colors.teal;
//     }
//   }

//   IconData _getTypeIcon(String? type) {
//     switch (type) {
//       case 'comprehensive_analysis':
//         return Icons.psychology;
//       case 'chat_recommendation':
//         return Icons.chat_bubble;
//       case 'career_prediction':
//         return Icons.work;
//       default:
//         return Icons.lightbulb;
//     }
//   }

//   String _getTypeTitle(String? type) {
//     switch (type) {
//       case 'comprehensive_analysis':
//         return 'Comprehensive Analysis';
//       case 'chat_recommendation':
//         return 'Chat Recommendation';
//       case 'career_prediction':
//         return 'Career Prediction';
//       default:
//         return 'AI Recommendation';
//     }
//   }
// }


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
