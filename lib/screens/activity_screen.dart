import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/circular_progress_widget.dart';
import '../widgets/program_card.dart';
import '../widgets/water_intake_widget.dart';
import '../providers/workout_progress_provider.dart';
import '../services/firebase_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'steps_graph_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nutrition_graph_screen.dart';
import 'water_intake_graph_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int _steps = 0;
  bool _isCountingSteps = false;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _activityController = TextEditingController();
  final _durationController = TextEditingController();
  bool _isLoading = false;
  int _totalCalories = 0;
  int _totalProtein = 0;
  int _totalSteps = 0;
  int _waterIntake = 0;
  int _workoutProgress = 0;
  int _totalWorkouts = 0;

  @override
  void initState() {
    super.initState();
    _loadTodaysData();
    initStepCounting();
  }

  Future<void> _loadTodaysData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(const Duration(days: 1)));
    final userRef = _firestore.collection('users').doc(user.uid);
    final prefs = await SharedPreferences.getInstance();

    // Listen to nutrition history changes
    userRef.collection('nutrition_history').doc(today).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        setState(() {
          _totalCalories = snapshot.data()?['totalCalories'] ?? 0;
          _totalProtein = snapshot.data()?['totalProtein'] ?? 0;
        });
      }
    });

    // Listen to steps changes and sync with SharedPreferences
    userRef.collection('daily_stats').doc(today).snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final steps = snapshot.data()?['steps'] ?? 0;
        setState(() {
          _totalSteps = steps;
        });
        // Save to SharedPreferences
        prefs.setInt('steps_$today', steps);
      }
    });

    // Get yesterday's steps from Firestore and save to SharedPreferences
    final yesterdayDoc =
        await userRef.collection('daily_stats').doc(yesterday).get();
    if (yesterdayDoc.exists) {
      final yesterdaySteps = yesterdayDoc.data()?['steps'] ?? 0;
      await prefs.setInt('steps_$yesterday', yesterdaySteps);
    }

    // Listen to water intake changes
    userRef.collection('water_intake').doc(today).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        setState(() {
          _waterIntake = snapshot.data()?['amount'] ?? 0;
        });
      }
    });

    // Listen to workout progress changes
    userRef.collection('workoutProgress').doc(today).snapshots().listen((
      snapshot,
    ) {
      if (snapshot.exists) {
        setState(() {
          _workoutProgress =
              snapshot.data()?['completedExercises']?.length ?? 0;
          _totalWorkouts = snapshot.data()?['totalExercises'] ?? 0;
        });
      }
    });
  }

  void initStepCounting() {
    accelerometerEvents.listen((AccelerometerEvent event) async {
      if (!_isCountingSteps && event.y.abs() > 12) {
        setState(() {
          _steps++;
          _totalSteps++;
          _isCountingSteps = true;
        });

        // Update steps in Firestore and SharedPreferences
        final user = _auth.currentUser;
        if (user != null) {
          final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

          // Update Firestore
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('daily_stats')
              .doc(today)
              .set({
                'steps': _totalSteps,
                'lastUpdated': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

          // Update SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('steps_$today', _totalSteps);
        }
      } else if (event.y.abs() < 6) {
        _isCountingSteps = false;
      }
    });
  }

  Future<void> _addActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final activity = _activityController.text.trim();
      final duration = int.parse(_durationController.text.trim());
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('activities')
          .add({
            'activity': activity,
            'duration': duration,
            'date': date,
            'timestamp': FieldValue.serverTimestamp(),
          });

      _activityController.clear();
      _durationController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Activity added successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding activity: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Track Your Activity',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),

                // Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildStatCard(
                      'Total Calories',
                      '$_totalCalories',
                      Icons.local_fire_department,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Steps',
                      '$_totalSteps',
                      Icons.directions_walk,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Total Protein',
                      '${_totalProtein}g',
                      Icons.fitness_center,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Water Intake',
                      '${_waterIntake}ml',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Water Intake Section
                const WaterIntakeWidget(),

                const SizedBox(height: 20),

                // Workout Progress
                Consumer<WorkoutProgressProvider>(
                  builder: (context, workoutProvider, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Workout Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${workoutProvider.remainingExercises} exercises left',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                            ],
                          ),
                          CircularProgressWidget(
                            progress: workoutProvider.progressPercentage,
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Programs Section
                const Text(
                  'Programs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ProgramCard(
                          icon: Icons.directions_run,
                          label: 'Jog',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProgramCard(
                          icon: Icons.self_improvement,
                          label: 'Yoga',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProgramCard(
                          icon: Icons.directions_bike,
                          label: 'Cycling',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ProgramCard(
                          icon: Icons.fitness_center,
                          label: 'Workout',
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Add Activity Form
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Add New Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _activityController,
                            decoration: const InputDecoration(
                              labelText: 'Activity Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter an activity name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _durationController,
                            decoration: const InputDecoration(
                              labelText: 'Duration (minutes)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter duration';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _addActivity,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text('Add Activity'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Recent Activities
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      _firestore
                          .collection('users')
                          .doc(_auth.currentUser?.uid)
                          .collection('activities')
                          .orderBy('timestamp', descending: true)
                          .limit(5)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Error loading activities');
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final activities = snapshot.data!.docs;

                    if (activities.isEmpty) {
                      return const Center(
                        child: Text('No activities recorded yet'),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        final activity =
                            activities[index].data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.directions_run),
                            title: Text(
                              activity['activity'] ?? 'Unknown activity',
                              style: const TextStyle(color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${activity['duration']} minutes • ${activity['date']}',
                              style: TextStyle(color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    bool isStepsCard = label == 'Steps';
    bool isCaloriesCard = label == 'Total Calories';
    bool isProteinCard = label == 'Total Protein';
    bool isWaterCard = label == 'Water Intake';
    bool isClickable =
        isStepsCard || isCaloriesCard || isProteinCard || isWaterCard;

    return InkWell(
      onTap:
          isClickable
              ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          isStepsCard
                              ? const StepsGraphScreen()
                              : isWaterCard
                              ? const WaterIntakeGraphScreen()
                              : NutritionGraphScreen(
                                type: isCaloriesCard ? 'calories' : 'protein',
                              ),
                ),
              )
              : null,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isClickable)
                    Icon(Icons.arrow_forward_ios, color: color, size: 14),
                ],
              ),
              const SizedBox(height: 12),
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
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activityController.dispose();
    _durationController.dispose();
    super.dispose();
  }
}
