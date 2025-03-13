import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quote/gemini_service.dart';
import 'package:flutter/services.dart' show SystemChrome, DeviceOrientation;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const QuoteApp());
  });
}

class QuoteApp extends StatefulWidget {
  const QuoteApp({Key? key}) : super(key: key);

  @override
  _QuoteAppState createState() => _QuoteAppState();
}

class _QuoteAppState extends State<QuoteApp> with SingleTickerProviderStateMixin {
  TextEditingController queryController = TextEditingController();
  String quote = "Enter a topic and get an inspiring quote!";
  bool isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getQuote(BuildContext context) async {
    if (queryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter a topic!", 
            style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.deepPurple.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    String result = await GeminiService.fetchQuote(queryController.text);

    setState(() {
      quote = result;
      isLoading = false;
    });
  }

  void copyQuote(BuildContext context) {
    Clipboard.setData(ClipboardData(text: quote));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Quote copied!", 
          style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void shareQuote() {
    Share.share(quote);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = size.width * 0.05;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade100,
                Colors.deepPurple.shade50,
              ],
            ),
          ),
          child: SafeArea(
            child: Builder(
              builder: (BuildContext scaffoldContext) {
                return ListView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.02),
                          Hero(
                            tag: 'title',
                            child: Text(
                              'Quote Generator',
                              style: GoogleFonts.lora(
                                fontSize: size.width * 0.07,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple.shade700,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.05),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.shade100,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: TextField(
                              maxLength: 60,
                              controller: queryController,
                              style: GoogleFonts.poppins(
                                color: Colors.deepPurple.shade700,
                              ),
                              decoration: InputDecoration(
                                labelText: "What's on your mind?",
                                labelStyle: TextStyle(color: Colors.deepPurple.shade400),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.deepPurple.shade200,
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide(
                                    color: Colors.deepPurple.shade400,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.05,
                                  vertical: size.height * 0.02,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          GestureDetector(
                            onTapDown: (_) => _controller.forward(),
                            onTapUp: (_) => _controller.reverse(),
                            onTapCancel: () => _controller.reverse(),
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: ElevatedButton(
                                onPressed: () => getQuote(scaffoldContext),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepPurple.shade400,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * 0.1,
                                    vertical: size.height * 0.02,
                                  ),
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: size.width * 0.05,
                                        height: size.width * 0.05,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        "Generate Quote",
                                        style: GoogleFonts.poppins(
                                          fontSize: size.width * 0.045,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.04),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: EdgeInsets.all(size.width * 0.06),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepPurple.shade100,
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Text(
                              quote,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lora(
                                fontSize: size.width * 0.045,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                                color: Colors.deepPurple.shade700,
                                height: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(height: size.height * 0.03),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildActionButton(
                                icon: Icons.copy,
                                label: "Copy",
                                onTap: () => copyQuote(scaffoldContext),
                                size: size,
                              ),
                              SizedBox(width: size.width * 0.04),
                              _buildActionButton(
                                icon: Icons.share,
                                label: "Share",
                                onTap: shareQuote,
                                size: size,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Size size,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade100,
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.04,
              vertical: size.height * 0.015,
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.deepPurple.shade400),
                SizedBox(width: size.width * 0.02),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.deepPurple.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}