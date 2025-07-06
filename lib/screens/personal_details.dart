import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  final _skillsController = TextEditingController();
  final _interestsController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _birthdateController = TextEditingController();

  final _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _isLoading = false;
  bool _isInitialLoad = true;
  DateTime? _selectedBirthdate;

  User? get currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    _branchController.dispose();
    _yearController.dispose();
    _skillsController.dispose();
    _interestsController.dispose();
    _cgpaController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDetails() async {
    if (currentUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Load from your existing FirestoreService
      final data = await _firestoreService.getPersonalDetails();
      
      // Also try to load from the users collection for consistency
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      
      Map<String, dynamic>? userData;
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
      }
      
      if (data != null || userData != null) {
        // Prioritize data from your existing service, fallback to users collection
        _nameController.text = data?['name'] ?? userData?['name'] ?? currentUser!.displayName ?? '';
        _emailController.text = data?['email'] ?? userData?['email'] ?? currentUser!.email ?? '';
        _phoneController.text = data?['phone'] ?? userData?['phone'] ?? '';
        _collegeController.text = data?['college'] ?? userData?['college'] ?? '';
        _branchController.text = data?['branch'] ?? userData?['branch'] ?? '';
        _yearController.text = data?['year'] ?? userData?['year'] ?? '';
        _skillsController.text = data?['skills'] ?? userData?['skills'] ?? '';
        _interestsController.text = data?['interests'] ?? userData?['interests'] ?? '';
        _cgpaController.text = data?['cgpa'] ?? userData?['cgpa'] ?? '';
        
        // Handle birthdate
        if (data?['birthdate'] != null) {
          if (data!['birthdate'] is Timestamp) {
            _selectedBirthdate = (data['birthdate'] as Timestamp).toDate();
          } else if (data['birthdate'] is String) {
            _selectedBirthdate = DateTime.tryParse(data['birthdate']);
          }
        } else if (userData?['birthdate'] != null) {
          if (userData!['birthdate'] is Timestamp) {
            _selectedBirthdate = (userData['birthdate'] as Timestamp).toDate();
          } else if (userData['birthdate'] is String) {
            _selectedBirthdate = DateTime.tryParse(userData['birthdate']);
          }
        }
        
        if (_selectedBirthdate != null) {
          _birthdateController.text = 
              "${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}";
        }
        
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade600,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _birthdateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _saveDetails() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (currentUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Save using your existing FirestoreService
      await _firestoreService.savePersonalDetails(
        name: _nameController.text.trim(),
        branch: _branchController.text.trim(),
        year: _yearController.text.trim(),
        skills: _skillsController.text.trim(),
        interests: _interestsController.text.trim(),
        cgpa: _cgpaController.text.trim(),
      );
      
      // Also update the users collection for consistency with settings screen
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'college': _collegeController.text.trim(),
        'branch': _branchController.text.trim(),
        'year': _yearController.text.trim(),
        'skills': _skillsController.text.trim(),
        'interests': _interestsController.text.trim(),
        'cgpa': _cgpaController.text.trim(),
        'birthdate': _selectedBirthdate,
        'profileComplete': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Details saved successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back or to dashboard
      Navigator.of(context).pop();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving details: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Personal Details"),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Details"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Colors.blue.shade600,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Complete Your Profile',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Help our AI understand you better',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Personal Information Section
                _buildSectionHeader('Personal Information', Icons.person_outline),
                _buildFormCard([
                  _buildField("Full Name", _nameController, Icons.person),
                  _buildField("Email", _emailController, Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildField("Phone Number", _phoneController, Icons.phone, keyboardType: TextInputType.phone),
                  _buildBirthdateField(),
                ]),
                
                const SizedBox(height: 16),
                
                // Academic Information Section
                _buildSectionHeader('Academic Information', Icons.school),
                _buildFormCard([
                  _buildField("College/University", _collegeController, Icons.account_balance),
                  _buildField("Branch/Department", _branchController, Icons.category),
                  _buildDropdownField("Year of Study", _yearController, [
                    '1st Year', '2nd Year', '3rd Year', '4th Year', 'Final Year'
                  ]),
                  _buildField("CGPA/Percentage", _cgpaController, Icons.grade),
                ]),
                
                const SizedBox(height: 16),
                
                // Skills & Interests Section
                _buildSectionHeader('Skills & Interests', Icons.psychology),
                _buildFormCard([
                  _buildField("Technical Skills", _skillsController, Icons.code, 
                    hintText: "e.g., Python, Java, React, Machine Learning"),
                  _buildField("Interests & Hobbies", _interestsController, Icons.favorite,
                    hintText: "e.g., Web Development, Data Science, Sports"),
                ]),
                
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Profile",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, 
      {TextInputType keyboardType = TextInputType.text, String? hintText}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
        ),
        validator: (value) =>
            value == null || value.trim().isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildBirthdateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _birthdateController,
        readOnly: true,
        onTap: _selectBirthdate,
        decoration: InputDecoration(
          labelText: "Date of Birth",
          hintText: "Select your birthdate",
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select your birthdate' : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> options) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.school, color: Colors.blue.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
          ),
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              controller.text = newValue;
            });
          }
        },
        validator: (value) =>
            value == null || value.isEmpty ? 'Please select $label' : null,
      ),
    );
  }
}