import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionGraphScreen extends StatefulWidget {
  final String type; // 'calories' or 'protein'
  const NutritionGraphScreen({super.key, required this.type});

  @override
  State<NutritionGraphScreen> createState() => _NutritionGraphScreenState();
}

class _NutritionGraphScreenState extends State<NutritionGraphScreen>
    with TickerProviderStateMixin {
  List<BarChartGroupData> barGroups = [];
  double maxValue = 2000; // Default max value
  bool isLoading = true;
  late TabController _tabController;
  String _currentView = 'Daily';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Cache for data
  Map<String, List<double>> _cachedData = {
    'Daily': [],
    'Weekly': [],
    'Monthly': [],
  };
  Map<String, List<String>> _cachedLabels = {
    'Daily': [],
    'Weekly': [],
    'Monthly': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          switch (_tabController.index) {
            case 0:
              _currentView = 'Daily';
              break;
            case 1:
              _currentView = 'Weekly';
              break;
            case 2:
              _currentView = 'Monthly';
              break;
          }
        });
        _updateGraphWithCachedData();
      }
    });
    _loadNutritionData();
  }

  void _updateGraphWithCachedData() {
    if (_cachedData[_currentView]!.isNotEmpty) {
      setState(() {
        _animationController.reset();
        maxValue = _cachedData[_currentView]!.reduce((a, b) => a > b ? a : b);
        maxValue = (maxValue / 100).ceil() * 100;
        if (maxValue < (widget.type == 'calories' ? 2000 : 100)) {
          maxValue = widget.type == 'calories' ? 2000 : 100;
        }

        barGroups = List.generate(
          _cachedData[_currentView]!.length,
          (index) => _makeGroupData(
            index,
            _cachedData[_currentView]![index],
            _cachedLabels[_currentView]![index],
          ),
        );
      });
      _animationController.forward();
    } else {
      _loadNutritionData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNutritionData() async {
    try {
      setState(() => isLoading = true);
      _animationController.reset();
      final today = DateTime.now();

      switch (_currentView) {
        case 'Daily':
          await _loadDailyData(today);
          break;
        case 'Weekly':
          await _loadWeeklyData(today);
          break;
        case 'Monthly':
          await _loadMonthlyData(today);
          break;
      }

      setState(() {
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error loading nutrition data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadDailyData(DateTime today) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_cachedData['Daily']!.isEmpty) {
      final yesterday = today.subtract(const Duration(days: 1));
      final todayKey = DateFormat('yyyy-MM-dd').format(today);
      final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);

      final todayDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('nutrition_history')
              .doc(todayKey)
              .get();

      final yesterdayDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('nutrition_history')
              .doc(yesterdayKey)
              .get();

      final todayValue =
          todayDoc.data()?[widget.type == 'calories'
              ? 'totalCalories'
              : 'totalProtein'] ??
          0;
      final yesterdayValue =
          yesterdayDoc.data()?[widget.type == 'calories'
              ? 'totalCalories'
              : 'totalProtein'] ??
          0;

      _cachedData['Daily'] = [yesterdayValue.toDouble(), todayValue.toDouble()];
      _cachedLabels['Daily'] = ['Yesterday', 'Today'];
    }

    maxValue = _cachedData['Daily']!.reduce((a, b) => a > b ? a : b);
    maxValue = (maxValue / 100).ceil() * 100;
    if (maxValue < (widget.type == 'calories' ? 2000 : 100)) {
      maxValue = widget.type == 'calories' ? 2000 : 100;
    }

    barGroups = List.generate(
      _cachedData['Daily']!.length,
      (index) => _makeGroupData(
        index,
        _cachedData['Daily']![index],
        _cachedLabels['Daily']![index],
      ),
    );
  }

  Future<void> _loadWeeklyData(DateTime today) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_cachedData['Weekly']!.isEmpty) {
      List<double> weeklyValues = [];
      List<String> weekDays = [];

      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        final doc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('nutrition_history')
                .doc(dateKey)
                .get();

        final value =
            doc.data()?[widget.type == 'calories'
                ? 'totalCalories'
                : 'totalProtein'] ??
            0;
        weeklyValues.add(value.toDouble());
        weekDays.add(DateFormat('E').format(date));
      }

      _cachedData['Weekly'] = weeklyValues;
      _cachedLabels['Weekly'] = weekDays;
    }

    maxValue = _cachedData['Weekly']!.reduce((a, b) => a > b ? a : b);
    maxValue = (maxValue / 100).ceil() * 100;
    if (maxValue < (widget.type == 'calories' ? 2000 : 100)) {
      maxValue = widget.type == 'calories' ? 2000 : 100;
    }

    barGroups = List.generate(
      _cachedData['Weekly']!.length,
      (index) => _makeGroupData(
        index,
        _cachedData['Weekly']![index],
        _cachedLabels['Weekly']![index],
      ),
    );
  }

  Future<void> _loadMonthlyData(DateTime today) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_cachedData['Monthly']!.isEmpty) {
      List<double> monthlyValues = [];
      List<String> dates = [];

      final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
      final currentDay = today.day;

      for (int i = 0; i < daysInMonth; i++) {
        if (i > currentDay - 1) break;
        final date = DateTime(today.year, today.month, i + 1);
        final dateKey = DateFormat('yyyy-MM-dd').format(date);

        final doc =
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('nutrition_history')
                .doc(dateKey)
                .get();

        final value =
            doc.data()?[widget.type == 'calories'
                ? 'totalCalories'
                : 'totalProtein'] ??
            0;
        monthlyValues.add(value.toDouble());
        dates.add(DateFormat('d').format(date));
      }

      _cachedData['Monthly'] = monthlyValues;
      _cachedLabels['Monthly'] = dates;
    }

    maxValue = _cachedData['Monthly']!.reduce((a, b) => a > b ? a : b);
    maxValue = (maxValue / 100).ceil() * 100;
    if (maxValue < (widget.type == 'calories' ? 2000 : 100)) {
      maxValue = widget.type == 'calories' ? 2000 : 100;
    }

    barGroups = List.generate(
      _cachedData['Monthly']!.length,
      (index) => _makeGroupData(
        index,
        _cachedData['Monthly']![index],
        _cachedLabels['Monthly']![index],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors:
                widget.type == 'calories'
                    ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                    : [const Color(0xFF4CAF50), const Color(0xFF81C784)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width:
              _currentView == 'Monthly'
                  ? 8
                  : (_currentView == 'Weekly' ? 25 : 45),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.type == 'calories'
                          ? Icons.local_fire_department
                          : Icons.fitness_center,
                      color:
                          widget.type == 'calories'
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFF4CAF50),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.type == 'calories'
                            ? 'Calories Tracking'
                            : 'Protein Tracking',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _getSubtitle(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tab Bar
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.all(4),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color:
                        widget.type == 'calories'
                            ? const Color(0xFFFF6B6B)
                            : const Color(0xFF4CAF50),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.type == 'calories'
                                ? const Color(0xFFFF6B6B)
                                : const Color(0xFF4CAF50))
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  tabs: const [
                    SizedBox(width: 80, child: Tab(text: 'Daily')),
                    SizedBox(width: 80, child: Tab(text: 'Weekly')),
                    SizedBox(width: 80, child: Tab(text: 'Monthly')),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Graph Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      isLoading
                          ? Center(
                            child: CircularProgressIndicator(
                              color:
                                  widget.type == 'calories'
                                      ? const Color(0xFFFF6B6B)
                                      : const Color(0xFF4CAF50),
                            ),
                          )
                          : Column(
                            children: [
                              Text(
                                widget.type == 'calories'
                                    ? 'Calories Progress'
                                    : 'Protein Progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Expanded(
                                child: FadeTransition(
                                  opacity: _animation,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: maxValue,
                                      minY: 0,
                                      groupsSpace:
                                          _currentView == 'Daily'
                                              ? 60
                                              : (_currentView == 'Weekly'
                                                  ? 12
                                                  : 4),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          tooltipRoundedRadius: 8,
                                          getTooltipItem: (
                                            group,
                                            groupIndex,
                                            rod,
                                            rodIndex,
                                          ) {
                                            return BarTooltipItem(
                                              '${rod.toY.toInt()}${widget.type == 'calories' ? ' cal' : 'g'}\n',
                                              GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              String label = '';
                                              if (_currentView == 'Daily') {
                                                label =
                                                    value == 0
                                                        ? 'Yesterday'
                                                        : 'Today';
                                              } else {
                                                label =
                                                    barGroups[value.toInt()].x
                                                        .toString();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8.0,
                                                ),
                                                child: Text(
                                                  label,
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.grey[400],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                '${value.toInt()}',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.grey[400],
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                            reservedSize: 40,
                                          ),
                                        ),
                                        topTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: FlGridData(
                                        show: true,
                                        horizontalInterval:
                                            widget.type == 'calories'
                                                ? 500
                                                : 20,
                                        drawVerticalLine: false,
                                        getDrawingHorizontalLine: (value) {
                                          return FlLine(
                                            color: Colors.grey[800]!,
                                            strokeWidth: 0.5,
                                            dashArray: [4, 4],
                                          );
                                        },
                                      ),
                                      borderData: FlBorderData(
                                        show: true,
                                        border: Border(
                                          left: BorderSide(
                                            color: Colors.grey[800]!,
                                            width: 0.8,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.grey[800]!,
                                            width: 0.8,
                                          ),
                                        ),
                                      ),
                                      barGroups: barGroups,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSubtitle() {
    switch (_currentView) {
      case 'Daily':
        return 'Today vs Yesterday';
      case 'Weekly':
        return 'Last 7 Days';
      case 'Monthly':
        return 'This Month';
      default:
        return '';
    }
  }
}
