import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterIntakeGraphScreen extends StatefulWidget {
  const WaterIntakeGraphScreen({super.key});

  @override
  State<WaterIntakeGraphScreen> createState() => _WaterIntakeGraphScreenState();
}

class _WaterIntakeGraphScreenState extends State<WaterIntakeGraphScreen>
    with TickerProviderStateMixin {
  List<BarChartGroupData> barGroups = [];
  double maxValue = 2000; // Default max value in ml
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
    _loadWaterData();
  }

  void _updateGraphWithCachedData() {
    if (_cachedData[_currentView]!.isNotEmpty) {
      setState(() {
        _animationController.reset();
        maxValue = _cachedData[_currentView]!.reduce((a, b) => a > b ? a : b);
        maxValue = (maxValue / 500).ceil() * 500;
        if (maxValue < 2000) maxValue = 2000;

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
      _loadWaterData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadWaterData() async {
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
      print('Error loading water data: $e');
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
              .collection('water_intake')
              .doc(todayKey)
              .get();

      final yesterdayDoc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('water_intake')
              .doc(yesterdayKey)
              .get();

      final todayValue = todayDoc.data()?['amount'] ?? 0;
      final yesterdayValue = yesterdayDoc.data()?['amount'] ?? 0;

      _cachedData['Daily'] = [yesterdayValue.toDouble(), todayValue.toDouble()];
      _cachedLabels['Daily'] = ['Yesterday', 'Today'];
    }

    maxValue = _cachedData['Daily']!.reduce((a, b) => a > b ? a : b);
    maxValue = (maxValue / 500).ceil() * 500;
    if (maxValue < 2000) maxValue = 2000;

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
                .collection('water_intake')
                .doc(dateKey)
                .get();

        final value = doc.data()?['amount'] ?? 0;
        weeklyValues.add(value.toDouble());
        weekDays.add(DateFormat('E').format(date));
      }

      _cachedData['Weekly'] = weeklyValues;
      _cachedLabels['Weekly'] = weekDays;
    }

    maxValue = _cachedData['Weekly']!.reduce((a, b) => a > b ? a : b);
    maxValue = (maxValue / 500).ceil() * 500;
    if (maxValue < 2000) maxValue = 2000;

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
                .collection('water_intake')
                .doc(dateKey)
                .get();

        final value = doc.data()?['amount'] ?? 0;
        monthlyValues.add(value.toDouble());
        dates.add(DateFormat('d').format(date));
      }

      _cachedData['Monthly'] = monthlyValues;
      _cachedLabels['Monthly'] = dates;
    }

    maxValue = _cachedData['Monthly']!.reduce((a, b) => a > b ? a : b);
    maxValue = (maxValue / 500).ceil() * 500;
    if (maxValue < 2000) maxValue = 2000;

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
    double getBarWidth() {
      switch (_currentView) {
        case 'Daily':
          return 50;
        case 'Weekly':
          return 28;
        case 'Monthly':
          return 6;
        default:
          return 40;
      }
    }

    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: getBarWidth(),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Water Intake Tracking',
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
              Container(
                height: 45,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: const Color(0xFF7B61FF),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[400],
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Daily'),
                    Tab(text: 'Weekly'),
                    Tab(text: 'Monthly'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Container(
                          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  bottom: 24,
                                ),
                                child: Text(
                                  'Water Intake Progress',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    right: 16,
                                    left: 8,
                                    bottom: 8,
                                  ),
                                  child: FadeTransition(
                                    opacity: _animation,
                                    child: BarChart(
                                      BarChartData(
                                        alignment:
                                            BarChartAlignment.spaceEvenly,
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
                                                '${rod.toY.toInt()}ml',
                                                GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 12,
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
                                              reservedSize: 32,
                                              getTitlesWidget: (value, meta) {
                                                String text = '';
                                                switch (_currentView) {
                                                  case 'Daily':
                                                    text =
                                                        value.toInt() == 0
                                                            ? 'Yesterday'
                                                            : 'Today';
                                                    break;
                                                  case 'Weekly':
                                                    text =
                                                        barGroups.length >
                                                                value.toInt()
                                                            ? DateFormat(
                                                              'E',
                                                            ).format(
                                                              DateTime.now()
                                                                  .subtract(
                                                                    Duration(
                                                                      days:
                                                                          6 -
                                                                          value
                                                                              .toInt(),
                                                                    ),
                                                                  ),
                                                            )
                                                            : '';
                                                    break;
                                                  case 'Monthly':
                                                    text =
                                                        barGroups.length >
                                                                value.toInt()
                                                            ? (value.toInt() +
                                                                    1)
                                                                .toString()
                                                            : '';
                                                    break;
                                                }
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                  child: Text(
                                                    text,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[400],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              interval: 1000,
                                              reservedSize: 46,
                                              getTitlesWidget: (value, meta) {
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 8.0,
                                                      ),
                                                  child: Text(
                                                    '${value.toInt()}ml',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[400],
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          rightTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                          topTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: false,
                                            ),
                                          ),
                                        ),
                                        gridData: FlGridData(
                                          show: true,
                                          horizontalInterval: 1000,
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
