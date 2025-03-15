import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  late SharedPreferences _prefs;
  bool _isLoading = true;
  TimeOfDay _workoutTime = const TimeOfDay(hour: 8, minute: 0);

  // Notification settings
  bool _workoutNotifications = true;
  bool _waterNotifications = true;
  bool _stepNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _workoutNotifications = _prefs.getBool('workoutNotifications') ?? true;
      _waterNotifications = _prefs.getBool('waterNotifications') ?? true;
      _stepNotifications = _prefs.getBool('stepNotifications') ?? true;
      
      final hour = _prefs.getInt('workoutHour') ?? 8;
      final minute = _prefs.getInt('workoutMinute') ?? 0;
      _workoutTime = TimeOfDay(hour: hour, minute: minute);
      
      _isLoading = false;
    });
  }

  Future<void> _updateWorkoutTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _workoutTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Color(0xFF2D2D2D),
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialHandColor: Colors.blue,
              dialBackgroundColor: Color(0xFF1E1E1E),
              dialTextColor: Colors.white,
              entryModeIconColor: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _workoutTime) {
      setState(() => _workoutTime = picked);
      await _prefs.setInt('workoutHour', picked.hour);
      await _prefs.setInt('workoutMinute', picked.minute);
      
      if (_workoutNotifications) {
        await _notificationService.scheduleWorkoutReminder(picked);
      }
    }
  }

  Future<void> _toggleNotification(String type, bool value) async {
    switch (type) {
      case 'workout':
        setState(() => _workoutNotifications = value);
        await _prefs.setBool('workoutNotifications', value);
        if (value) {
          await _notificationService.scheduleWorkoutReminder(_workoutTime);
        } else {
          await _notificationService.cancelNotification(1);
        }
        break;
      case 'water':
        setState(() => _waterNotifications = value);
        await _prefs.setBool('waterNotifications', value);
        if (value) {
          await _notificationService.scheduleWaterReminders();
        } else {
          for (int i = 8; i <= 20; i += 2) {
            await _notificationService.cancelNotification(i);
          }
        }
        break;
      case 'steps':
        setState(() => _stepNotifications = value);
        await _prefs.setBool('stepNotifications', value);
        if (value) {
          await _notificationService.scheduleStepGoalReminder();
        } else {
          await _notificationService.cancelNotification(100);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize your notifications to stay on track with your fitness goals.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Workout Reminders',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Daily reminder at ${_workoutTime.format(context)}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      secondary: const Icon(Icons.fitness_center, color: Colors.blue),
                      value: _workoutNotifications,
                      onChanged: (value) => _toggleNotification('workout', value),
                    ),
                    if (_workoutNotifications)
                      ListTile(
                        leading: const SizedBox(width: 32),
                        title: Text(
                          'Reminder Time',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        trailing: TextButton(
                          onPressed: _updateWorkoutTime,
                          child: Text(_workoutTime.format(context)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Water Intake Reminders',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Reminders every 2 hours (8 AM - 8 PM)',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  secondary: const Icon(Icons.water_drop, color: Colors.blue),
                  value: _waterNotifications,
                  onChanged: (value) => _toggleNotification('water', value),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Color(0xFF2D2D2D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Step Goal Reminders',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    'Daily reminder at 6 PM',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  secondary: const Icon(Icons.directions_walk, color: Colors.blue),
                  value: _stepNotifications,
                  onChanged: (value) => _toggleNotification('steps', value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 