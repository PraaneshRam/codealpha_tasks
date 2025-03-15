import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class FoodScreen extends StatefulWidget {
  const FoodScreen({super.key});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _detectedFood = "";
  int _calories = 0;
  int _protein = 0;
  int _totalCalories = 0;
  int _totalProtein = 0;
  bool _isAnalyzing = false;

  final String _apiKey = "AIzaSyC_kd2KIV24Kzwz5I3oh2McSRZntg1ADpA";

  @override
  void initState() {
    super.initState();
    _loadTodaysTotals();
  }

  Future<void> _loadTodaysTotals() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Listen to nutrition history changes
    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('nutrition_history')
        .doc(today)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _totalCalories = snapshot.data()?['totalCalories'] ?? 0;
          _totalProtein = snapshot.data()?['totalProtein'] ?? 0;
        });
      }
    });
  }

  Future<void> _pickAndAnalyzeImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _detectedFood = "Analyzing...";
        _calories = 0;
        _protein = 0;
        _isAnalyzing = true;
      });

      await _analyzeImage();
    } catch (e) {
      setState(() {
        _detectedFood = "Error picking image";
        _isAnalyzing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_image == null) return;

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "Identify the food item in the image and estimate its calories and protein content. Reply strictly in the format: Name: [food name], Calories: [number] kcal, Protein: [number] g"
                },
                {
                  "inlineData": {"mimeType": "image/jpeg", "data": base64Image}
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['candidates'] != null &&
            jsonResponse['candidates'].isNotEmpty) {
          String result =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];

          // Parse the response
          RegExp nameExp = RegExp(r'Name:\s*(.*?),');
          RegExp calExp = RegExp(r'Calories:\s*(\d+)\s*kcal');
          RegExp proExp = RegExp(r'Protein:\s*(\d+)\s*g');

          String? name = nameExp.firstMatch(result)?.group(1);
          int calories =
              int.tryParse(calExp.firstMatch(result)?.group(1) ?? "0") ?? 0;
          int protein =
              int.tryParse(proExp.firstMatch(result)?.group(1) ?? "0") ?? 0;

          if (name == null || name.isEmpty) {
            throw Exception("Could not detect food name from the image");
          }

          setState(() {
            _detectedFood = name;
            _calories = calories;
            _protein = protein;
            _isAnalyzing = false;
          });

          // Save to Firestore with user-specific data
          final user = _auth.currentUser;
          if (user != null) {
            final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
            final userRef = _firestore.collection('users').doc(user.uid);
            final nutritionRef =
                userRef.collection('nutrition_history').doc(today);

            // Get current totals from nutrition history
            final nutritionDoc = await nutritionRef.get();
            final currentData = nutritionDoc.data() ?? {};
            final currentCalories = currentData['totalCalories'] ?? 0;
            final currentProtein = currentData['totalProtein'] ?? 0;

            // Create new food entry
            Map<String, dynamic> newFood = {
              'name': _detectedFood,
              'calories': calories,
              'protein': protein,
              'addedAt': DateTime.now().millisecondsSinceEpoch,
            };

            // Update nutrition history
            await nutritionRef.set({
              'totalCalories': currentCalories + calories,
              'totalProtein': currentProtein + protein,
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
              'foods': FieldValue.arrayUnion([newFood]),
            }, SetOptions(merge: true));

            // Update daily stats
            await userRef.collection('daily_stats').doc(today).set({
              'totalCalories': currentCalories + calories,
              'totalProtein': currentProtein + protein,
              'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            }, SetOptions(merge: true));

            // Show success message
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Food added successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception("No food detected in the image");
        }
      } else {
        throw Exception("Error analyzing image: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        _detectedFood = "Could not analyze food";
        _calories = 0;
        _protein = 0;
        _isAnalyzing = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Your Food',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // Image Preview and Add Food Section
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 48,
                            color: Colors.blue[300],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select a food image',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _pickAndAnalyzeImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              icon: const Icon(Icons.camera_alt),
              label: Text(_isAnalyzing ? 'Analyzing...' : 'Take Photo'),
            ),
            const SizedBox(height: 24),
            // Analysis Result
            if (_detectedFood.isNotEmpty && _detectedFood != "Analyzing...")
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Analysis Result',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnalysisItem(
                              'Food',
                              _detectedFood,
                              Icons.fastfood,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildAnalysisItem(
                                    'Calories',
                                    '$_calories kcal',
                                    Icons.local_fire_department,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildAnalysisItem(
                                    'Protein',
                                    '$_protein g',
                                    Icons.fitness_center,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Today's Totals
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.today,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Today\'s Totals',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildAnalysisItem(
                              'Total Calories',
                              '$_totalCalories kcal',
                              Icons.local_fire_department,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildAnalysisItem(
                              'Total Protein',
                              '$_totalProtein g',
                              Icons.fitness_center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.blue,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
