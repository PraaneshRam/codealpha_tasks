
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> analyzeProgress(
    Map<String, dynamic> currentFace,
  ) async {
    try {
      
      final previousPhotos =
          await _firestore
              .collection('photos')
              .orderBy('date', descending: true)
              .limit(2)
              .get();

      if (previousPhotos.docs.isEmpty) {
        return {
          'message':
              'Welcome! This is your first photo. Keep tracking your progress!',
          'type': 'initial',
          'metrics': {'cheekRatio': 0, 'faceRatio': 0},
          'changes': null,
        };
      }

      // Get the previous face data for comparison
      final previousFace =
          previousPhotos.docs.first.data()['face'] as Map<String, dynamic>;

      // Calculate detailed changes
      final changes = _calculateDetailedChanges(currentFace, previousFace);
      final message = _generateDetailedMessage(changes);

      return {
        'message': message,
        'type': changes['overallTrend'],
        'metrics': changes['metrics'],
        'changes': changes,
      };
    } catch (e) {
      print('Error analyzing progress: $e');
      return {
        'message': 'Keep going! Every step counts in your fitness journey.',
        'type': 'neutral',
        'metrics': {'cheekRatio': 0, 'faceRatio': 0},
        'changes': null,
      };
    }
  }

  Map<String, dynamic> _calculateDetailedChanges(
    Map<String, dynamic> current,
    Map<String, dynamic> previous,
  ) {
    // Calculate percentage changes in different facial measurements
    final cheekChange = _calculatePercentageChange(
      current['cheekDistanceRatio'],
      previous['cheekDistanceRatio'],
    );

    final faceWidthChange = _calculatePercentageChange(
      current['width'],
      previous['width'],
    );

    final jawlineChange = _calculatePercentageChange(
      current['earDistanceRatio'],
      previous['earDistanceRatio'],
    );

    final neckChange = _calculatePercentageChange(
      current['noseToMouthRatio'],
      previous['noseToMouthRatio'],
    );

    // Determine which areas show the most significant changes
    final significantChanges = <String, double>{};
    if (cheekChange.abs() > 2) significantChanges['cheeks'] = cheekChange;
    if (faceWidthChange.abs() > 2) {
      significantChanges['face width'] = faceWidthChange;
    }
    if (jawlineChange.abs() > 2) significantChanges['jawline'] = jawlineChange;
    if (neckChange.abs() > 2) significantChanges['neck area'] = neckChange;

    // Calculate overall trend
    final avgChange =
        [
          cheekChange,
          faceWidthChange,
          jawlineChange,
          neckChange,
        ].reduce((a, b) => a + b) /
        4;

    String overallTrend;
    if (avgChange < -2) {
      overallTrend = 'loss';
    } else if (avgChange > 2) {
      overallTrend = 'gain';
    } else {
      overallTrend = 'maintain';
    }

    return {
      'overallTrend': overallTrend,
      'metrics': {
        'cheekChange': cheekChange,
        'faceWidthChange': faceWidthChange,
        'jawlineChange': jawlineChange,
        'neckChange': neckChange,
        'averageChange': avgChange,
      },
      'significantChanges': significantChanges,
    };
  }

  double _calculatePercentageChange(dynamic current, dynamic previous) {
    if (current == null || previous == null) return 0.0;
    return ((current - previous) / previous) * 100;
  }

  String _generateDetailedMessage(Map<String, dynamic> changes) {
    final significantChanges =
        changes['significantChanges'] as Map<String, double>;
    final metrics = changes['metrics'] as Map<String, dynamic>;
    final overallTrend = changes['overallTrend'] as String;

    if (significantChanges.isEmpty) {
      return _generateMotivationalMessage(
        overallTrend,
        metrics['averageChange'].abs(),
      );
    }

    // Build detailed message about changes
    final StringBuffer message = StringBuffer();

    // Add opening line based on overall trend
    if (overallTrend == 'loss') {
      message.write('Great progress! 🎯 ');
    } else if (overallTrend == 'gain') {
      message.write('Keep pushing! 💪 ');
    } else {
      message.write('Staying consistent! ⚡ ');
    }

    // Add specific changes
    message.write('\n\nChanges detected in: ');
    significantChanges.forEach((area, change) {
      final direction = change < 0 ? 'reduction' : 'increase';
      message.write(
        '\n• ${area.toUpperCase()}: ${change.abs().toStringAsFixed(1)}% $direction',
      );
    });

    // Add motivational closing
    message.write('\n\n${_getClosingMessage(overallTrend)}');

    return message.toString();
  }

  String _getClosingMessage(String trend) {
    switch (trend) {
      case 'loss':
        return 'Your dedication is showing! Keep up the amazing work! 🌟';
      case 'gain':
        return 'Remember, progress isn\'t always linear. Stay focused! 🎯';
      default:
        return 'Consistency is key to long-term success! 💫';
    }
  }

  String _generateMotivationalMessage(
    String weightChange,
    double changePercent,
  ) {
    final messages = {
      'loss': [
        'Great progress! Your face shows positive changes. Keep up the good work! 💪',
        'You\'re making visible progress! Your dedication is paying off! 🌟',
        'Fantastic results! Your commitment to fitness is showing! 🎯',
      ],
      'gain': [
        'Keep pushing! Remember, fitness is a journey, not a destination. 🌱',
        'Stay motivated! Every day is a new opportunity to reach your goals! ⭐',
        'You\'ve got this! Focus on your healthy habits and keep moving forward! 🎯',
      ],
      'maintain': [
        'You\'re maintaining well! Consistency is key to long-term success! ⚡',
        'Steady progress is sustainable progress! Keep up the great work! 🌟',
        'You\'re staying consistent! That\'s the secret to lasting results! 💫',
      ],
    };

    final messageList = messages[weightChange] ?? messages['maintain']!;
    final index = changePercent.abs().floor() % messageList.length;
    return messageList[index];
  }
}







/*import 'package:cloud_firestore/cloud_firestore.dart';

class AnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> analyzeProgress(
    Map<String, dynamic> currentFace,
  ) async {
    try {
      
      final previousPhotos =
          await _firestore
              .collection('photos')
              .orderBy('date', descending: true)
              .limit(2)
              .get();

      if (previousPhotos.docs.isEmpty) {
        return {
          'message':
              'Welcome! This is your first photo. Keep tracking your progress!',
          'type': 'initial',
          'metrics': {'cheekRatio': 0, 'faceRatio': 0},
          'changes': null,
        };
      }

      // Get the previous face data for comparison
      final previousFace =
          previousPhotos.docs.first.data()['face'] as Map<String, dynamic>;

      // Calculate detailed changes
      final changes = _calculateDetailedChanges(currentFace, previousFace);
      final message = _generateDetailedMessage(changes);

      return {
        'message': message,
        'type': changes['overallTrend'],
        'metrics': changes['metrics'],
        'changes': changes,
      };
    } catch (e) {
      print('Error analyzing progress: $e');
      return {
        'message': 'Keep going! Every step counts in your fitness journey.',
        'type': 'neutral',
        'metrics': {'cheekRatio': 0, 'faceRatio': 0},
        'changes': null,
      };
    }
  }

  Map<String, dynamic> _calculateDetailedChanges(
    Map<String, dynamic> current,
    Map<String, dynamic> previous,
  ) {
    // Calculate percentage changes in different facial measurements
    final cheekChange = _calculatePercentageChange(
      current['cheekDistanceRatio'],
      previous['cheekDistanceRatio'],
    );

    final faceWidthChange = _calculatePercentageChange(
      current['width'],
      previous['width'],
    );

    final jawlineChange = _calculatePercentageChange(
      current['earDistanceRatio'],
      previous['earDistanceRatio'],
    );

    final neckChange = _calculatePercentageChange(
      current['noseToMouthRatio'],
      previous['noseToMouthRatio'],
    );

    // Determine which areas show the most significant changes
    final significantChanges = <String, double>{};
    if (cheekChange.abs() > 2) significantChanges['cheeks'] = cheekChange;
    if (faceWidthChange.abs() > 2) {
      significantChanges['face width'] = faceWidthChange;
    }
    if (jawlineChange.abs() > 2) significantChanges['jawline'] = jawlineChange;
    if (neckChange.abs() > 2) significantChanges['neck area'] = neckChange;

    // Calculate overall trend
    final avgChange =
        [
          cheekChange,
          faceWidthChange,
          jawlineChange,
          neckChange,
        ].reduce((a, b) => a + b) /
        4;

    String overallTrend;
    if (avgChange < -2) {
      overallTrend = 'loss';
    } else if (avgChange > 2) {
      overallTrend = 'gain';
    } else {
      overallTrend = 'maintain';
    }

    return {
      'overallTrend': overallTrend,
      'metrics': {
        'cheekChange': cheekChange,
        'faceWidthChange': faceWidthChange,
        'jawlineChange': jawlineChange,
        'neckChange': neckChange,
        'averageChange': avgChange,
      },
      'significantChanges': significantChanges,
    };
  }

  double _calculatePercentageChange(dynamic current, dynamic previous) {
    if (current == null || previous == null) return 0.0;
    return ((current - previous) / previous) * 100;
  }

  String _generateDetailedMessage(Map<String, dynamic> changes) {
    final significantChanges =
        changes['significantChanges'] as Map<String, double>;
    final metrics = changes['metrics'] as Map<String, dynamic>;
    final overallTrend = changes['overallTrend'] as String;

    if (significantChanges.isEmpty) {
      return _generateMotivationalMessage(
        overallTrend,
        metrics['averageChange'].abs(),
      );
    }

    // Build detailed message about changes
    final StringBuffer message = StringBuffer();

    // Add opening line based on overall trend
    if (overallTrend == 'loss') {
      message.write('Great progress! 🎯 ');
    } else if (overallTrend == 'gain') {
      message.write('Keep pushing! 💪 ');
    } else {
      message.write('Staying consistent! ⚡ ');
    }

    // Add specific changes
    message.write('\n\nChanges detected in: ');
    significantChanges.forEach((area, change) {
      final direction = change < 0 ? 'reduction' : 'increase';
      message.write(
        '\n• ${area.toUpperCase()}: ${change.abs().toStringAsFixed(1)}% $direction',
      );
    });

    // Add motivational closing
    message.write('\n\n${_getClosingMessage(overallTrend)}');

    return message.toString();
  }

  String _getClosingMessage(String trend) {
    switch (trend) {
      case 'loss':
        return 'Your dedication is showing! Keep up the amazing work! 🌟';
      case 'gain':
        return 'Remember, progress isn\'t always linear. Stay focused! 🎯';
      default:
        return 'Consistency is key to long-term success! 💫';
    }
  }

  String _generateMotivationalMessage(
    String weightChange,
    double changePercent,
  ) {
    final messages = {
      'loss': [
        'Great progress! Your face shows positive changes. Keep up the good work! 💪',
        'You\'re making visible progress! Your dedication is paying off! 🌟',
        'Fantastic results! Your commitment to fitness is showing! 🎯',
      ],
      'gain': [
        'Keep pushing! Remember, fitness is a journey, not a destination. 🌱',
        'Stay motivated! Every day is a new opportunity to reach your goals! ⭐',
        'You\'ve got this! Focus on your healthy habits and keep moving forward! 🎯',
      ],
      'maintain': [
        'You\'re maintaining well! Consistency is key to long-term success! ⚡',
        'Steady progress is sustainable progress! Keep up the great work! 🌟',
        'You\'re staying consistent! That\'s the secret to lasting results! 💫',
      ],
    };

    final messageList = messages[weightChange] ?? messages['maintain']!;
    final index = changePercent.abs().floor() % messageList.length;
    return messageList[index];
  }
}
*/