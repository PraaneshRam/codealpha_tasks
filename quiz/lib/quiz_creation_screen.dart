import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'quiz_model.dart';

class QuizCreationScreen extends StatefulWidget {
  const QuizCreationScreen({super.key});

  @override
  _QuizCreationScreenState createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  final TextEditingController _quizTitleController = TextEditingController();
  final List<QuestionModel> _questions = [];
  int _timePerQuestion = 30;

  void _addQuestion() {
    TextEditingController questionController = TextEditingController();
    TextEditingController answerController = TextEditingController();
    TextEditingController option1Controller = TextEditingController();
    TextEditingController option2Controller = TextEditingController();
    TextEditingController option3Controller = TextEditingController();
    TextEditingController option4Controller = TextEditingController();

    int choiceType = 0;
    int? correctChoiceIndex;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6200EE).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: const Color(0xFF6200EE),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Add Question",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Question Type",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButton<int>(
                        value: choiceType,
                        isExpanded: true,
                        underline: Container(),
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: Color(0xFF6200EE),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.short_text_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Single Answer",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 2,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "2 Choices",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 4,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.grid_view_rounded,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "4 Choices",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            choiceType = value!;
                            correctChoiceIndex = null;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: questionController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF424242),
                      ),
                      decoration: InputDecoration(
                        labelText: "Question",
                        labelStyle: GoogleFonts.poppins(
                          color: const Color(0xFF6200EE),
                        ),
                        hintText: "Enter your question here",
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
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (choiceType == 0)
                      TextField(
                        controller: answerController,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          labelText: "Answer",
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF6200EE),
                          ),
                          hintText: "Enter the correct answer",
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
                          prefixIcon: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF6200EE),
                          ),
                        ),
                      ),
                    if (choiceType >= 2) ...[
                      Text(
                        "Options",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: option1Controller,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          labelText: "Option A",
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF6200EE),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: option2Controller,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          labelText: "Option B",
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF6200EE),
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
                        ),
                      ),
                    ],
                    if (choiceType == 4) ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: option3Controller,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          labelText: "Option C",
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF6200EE),
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: option4Controller,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          labelText: "Option D",
                          labelStyle: GoogleFonts.poppins(
                            color: const Color(0xFF6200EE),
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
                        ),
                      ),
                    ],
                    if (choiceType > 0) ...[
                      const SizedBox(height: 24),
                      Text(
                        "Correct Answer",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButton<int>(
                          hint: Text(
                            "Select correct option",
                            style: GoogleFonts.poppins(
                              color: Colors.grey[400],
                            ),
                          ),
                          value: correctChoiceIndex,
                          isExpanded: true,
                          underline: Container(),
                          icon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Color(0xFF6200EE),
                          ),
                          items: List.generate(choiceType, (index) {
                            return DropdownMenuItem(
                              value: index,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.green[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Option ${String.fromCharCode(65 + index)}",
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          onChanged: (value) {
                            setDialogState(() {
                              correctChoiceIndex = value;
                            });
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (questionController.text.isEmpty ||
                                (choiceType == 0 && answerController.text.isEmpty) ||
                                (choiceType >= 2 &&
                                    (option1Controller.text.isEmpty ||
                                        option2Controller.text.isEmpty)) ||
                                (choiceType == 4 &&
                                    (option3Controller.text.isEmpty ||
                                        option4Controller.text.isEmpty)) ||
                                (choiceType > 0 && correctChoiceIndex == null)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Please fill all fields and select the correct answer!",
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: Colors.red[400],
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _questions.add(
                                QuestionModel(
                                  question: questionController.text,
                                  answer: choiceType == 0 ? answerController.text : null,
                                  options: choiceType > 0
                                      ? [
                                          option1Controller.text,
                                          option2Controller.text,
                                          if (choiceType == 4) option3Controller.text,
                                          if (choiceType == 4) option4Controller.text,
                                        ]
                                      : null,
                                  correctChoiceIndex:
                                      choiceType > 0 ? correctChoiceIndex : null,
                                ),
                              );
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6200EE),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Add Question",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _saveQuiz() {
    if (_quizTitleController.text.isEmpty || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quiz title and at least one question are required!",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final quizBox = Hive.box<QuizModel>('quizBox');
    final quiz = QuizModel(
      title: _quizTitleController.text,
      questions: List.from(_questions),
      timePerQuestion: _timePerQuestion,
    );

    quizBox.add(quiz);

    setState(() {
      _quizTitleController.clear();
      _questions.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Quiz saved successfully!",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF6200EE),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.create_rounded,
              size: 28,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 12),
            Text(
              "Create Quiz",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.quiz_rounded,
                                  size: 28,
                                  color: const Color(0xFF6200EE),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Quiz Details",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F1F1F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            TextField(
                              controller: _quizTitleController,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: const Color(0xFF424242),
                              ),
                              decoration: InputDecoration(
                                labelText: "Quiz Title",
                                labelStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF6200EE),
                                ),
                                hintText: "Enter a title for your quiz",
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
                                prefixIcon: const Icon(
                                  Icons.title_rounded,
                                  color: Color(0xFF6200EE),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Time per Question",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.timer_rounded,
                                    color: Color(0xFF6200EE),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Slider(
                                      value: _timePerQuestion.toDouble(),
                                      min: 10,
                                      max: 60,
                                      divisions: 10,
                                      activeColor: const Color(0xFF6200EE),
                                      inactiveColor: const Color(0xFF6200EE).withOpacity(0.2),
                                      label: "${_timePerQuestion.round()} seconds",
                                      onChanged: (value) {
                                        setState(() {
                                          _timePerQuestion = value.round();
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6200EE).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${_timePerQuestion}s",
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF6200EE),
                                      ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Questions (${_questions.length})",
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addQuestion,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: Text(
                            "Add Question",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF6200EE),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return Dismissible(
                          key: Key(question.question),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade400,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          onDismissed: (direction) {
                            setState(() {
                              _questions.removeAt(index);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Question deleted',
                                  style: GoogleFonts.poppins(color: Colors.white),
                                ),
                                backgroundColor: const Color(0xFF6200EE),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 4,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6200EE).withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          "${index + 1}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF6200EE),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          question.question,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF1F1F1F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (question.options != null) ...[
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      children: question.options!.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final option = entry.value;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: question.correctChoiceIndex == index
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: question.correctChoiceIndex == index
                                                  ? Colors.green
                                                  : Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Text(
                                            option,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: question.correctChoiceIndex == index
                                                  ? Colors.green[700]
                                                  : Colors.grey[700],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "Answer: ${question.answer}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.green[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveQuiz,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        "Save Quiz",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6200EE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
