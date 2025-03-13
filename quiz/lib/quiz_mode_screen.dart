import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz/quiz_model.dart';
import 'package:flip_card/flip_card.dart';

class QuizModeScreen extends StatefulWidget {
  final QuizModel quiz;

  const QuizModeScreen({super.key, required this.quiz});

  @override
  _QuizModeScreenState createState() => _QuizModeScreenState();
}

class _QuizModeScreenState extends State<QuizModeScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _timeLeft = 0;
  Timer? _timer;
  bool _answered = false;
  int? _selectedAnswer;
  String? _writtenAnswer;
  final TextEditingController _answerController = TextEditingController();
  final GlobalKey<FlipCardState> _flipCardKey = GlobalKey<FlipCardState>();

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.quiz.timePerQuestion;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = widget.quiz.timePerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          if (!_answered) {
            _checkAnswer();
          }
        }
      });
    });
  }

  void _checkAnswer() {
    final question = widget.quiz.questions[_currentQuestionIndex];
    bool isCorrect = false;

    if (question.options != null && _selectedAnswer != null) {
      isCorrect = _selectedAnswer == question.correctChoiceIndex;
    } else if (question.answer != null && _writtenAnswer != null) {
      isCorrect = _writtenAnswer!.toLowerCase().trim() == question.answer!.toLowerCase().trim();
    }

    setState(() {
      _answered = true;
      if (isCorrect) _score++;
    });

    _flipCardKey.currentState?.toggleCard();

    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex < widget.quiz.questions.length - 1) {
        _flipCardKey.currentState?.toggleCard();
        setState(() {
          _currentQuestionIndex++;
          _answered = false;
          _selectedAnswer = null;
          _writtenAnswer = null;
          _answerController.clear();
        });
        _startTimer();
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6200EE).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _score >= widget.quiz.questions.length / 2
                      ? Icons.emoji_events_rounded
                      : Icons.psychology_rounded,
                  size: 48,
                  color: const Color(0xFF6200EE),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Quiz Completed!",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Your Score",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$_score/${widget.quiz.questions.length}",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6200EE),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Return to home screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6200EE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Back to Home",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.quiz.questions.length;
    final timeProgress = _timeLeft / widget.quiz.timePerQuestion;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6200EE).withOpacity(0.95),
              const Color(0xFF3700B3).withOpacity(0.9),
            ],
            stops: const [0.2, 0.9],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white,
                    ),
                    Text(
                      "Question ${_currentQuestionIndex + 1}/${widget.quiz.questions.length}",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "Score: $_score",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: timeProgress,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        timeProgress > 0.5
                            ? Colors.white
                            : timeProgress > 0.25
                                ? Colors.orange
                                : Colors.red,
                      ),
                      strokeWidth: 8,
                    ),
                  ),
                  Text(
                    "$_timeLeft",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Expanded(
                child: FlipCard(
                  key: _flipCardKey,
                  flipOnTouch: false,
                  direction: FlipDirection.HORIZONTAL,
                  front: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxHeight: 500),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.question,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (question.options != null) ...[
                          Expanded(
                            child: ListView.builder(
                              itemCount: question.options!.length,
                              itemBuilder: (context, index) {
                                final option = question.options![index];
                                final isSelected = _selectedAnswer == index;

                                return GestureDetector(
                                  onTap: _answered ? null : () {
                                    setState(() {
                                      _selectedAnswer = index;
                                    });
                                    _checkAnswer();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF6200EE).withOpacity(0.1) : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF6200EE) : Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFF6200EE).withOpacity(0.1) : Colors.grey[100],
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              String.fromCharCode(65 + index),
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isSelected ? const Color(0xFF6200EE) : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: const Color(0xFF424242),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _answerController,
                            enabled: !_answered,
                            onSubmitted: (value) {
                              if (!_answered && value.isNotEmpty) {
                                setState(() {
                                  _writtenAnswer = value;
                                });
                                _checkAnswer();
                              }
                            },
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF424242),
                            ),
                            decoration: InputDecoration(
                              labelText: "Your Answer",
                              labelStyle: GoogleFonts.poppins(
                                color: const Color(0xFF6200EE),
                              ),
                              hintText: "Type your answer here",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[400],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6200EE),
                                  width: 2,
                                ),
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send_rounded),
                                color: const Color(0xFF6200EE),
                                onPressed: _answered ? null : () {
                                  if (_answerController.text.isNotEmpty) {
                                    setState(() {
                                      _writtenAnswer = _answerController.text;
                                    });
                                    _checkAnswer();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  back: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    padding: const EdgeInsets.all(24),
                    constraints: const BoxConstraints(maxHeight: 500),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == question.correctChoiceIndex || 
                            _writtenAnswer?.toLowerCase().trim() == question.answer?.toLowerCase().trim()
                          ? Colors.green[50]
                          : Colors.red[50],
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedAnswer == question.correctChoiceIndex || 
                          _writtenAnswer?.toLowerCase().trim() == question.answer?.toLowerCase().trim()
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 64,
                          color: _selectedAnswer == question.correctChoiceIndex || 
                                _writtenAnswer?.toLowerCase().trim() == question.answer?.toLowerCase().trim()
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _selectedAnswer == question.correctChoiceIndex || 
                          _writtenAnswer?.toLowerCase().trim() == question.answer?.toLowerCase().trim()
                              ? "Correct!"
                              : "Incorrect",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _selectedAnswer == question.correctChoiceIndex || 
                                  _writtenAnswer?.toLowerCase().trim() == question.answer?.toLowerCase().trim()
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                        if (!(_selectedAnswer == question.correctChoiceIndex || 
                             _writtenAnswer?.toLowerCase().trim() == question.answer?.toLowerCase().trim())) ...[
                          const SizedBox(height: 16),
                          Text(
                            "Correct Answer:",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            question.options != null
                                ? question.options![question.correctChoiceIndex!]
                                : question.answer!,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[900],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
