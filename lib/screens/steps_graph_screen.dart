import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepsGraphScreen extends StatefulWidget {
  const StepsGraphScreen({super.key});

  @override
  State<StepsGraphScreen> createState() => _StepsGraphScreenState();
}

class _StepsGraphScreenState extends State<StepsGraphScreen>
    with SingleTickerProviderStateMixin {
  List<BarChartGroupData> barGroups = [];
  double maxSteps = 5000;
  bool isLoading = true;
  late TabController _tabController;
  String _currentView = 'Daily';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        _loadStepsData();
      }
    });
    _loadStepsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStepsData() async {
    try {
      setState(() => isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();

      switch (_currentView) {
        case 'Daily':
          await _loadDailyData(prefs, today);
          break;
        case 'Weekly':
          await _loadWeeklyData(prefs, today);
          break;
        case 'Monthly':
          await _loadMonthlyData(prefs, today);
          break;
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading steps data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadDailyData(SharedPreferences prefs, DateTime today) async {
    final yesterday = today.subtract(const Duration(days: 1));
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    final yesterdayKey = DateFormat('yyyy-MM-dd').format(yesterday);

    final todaySteps = prefs.getInt('steps_$todayKey') ?? 0;
    final yesterdaySteps = prefs.getInt('steps_$yesterdayKey') ?? 0;

    maxSteps =
        [todaySteps, yesterdaySteps].reduce((a, b) => a > b ? a : b).toDouble();
    maxSteps = (maxSteps / 1000).ceil() * 1000;
    if (maxSteps < 5000) maxSteps = 5000;

    barGroups = [
      _makeGroupData(0, yesterdaySteps.toDouble(), 'Yesterday'),
      _makeGroupData(1, todaySteps.toDouble(), 'Today'),
    ];
  }

  Future<void> _loadWeeklyData(SharedPreferences prefs, DateTime today) async {
    List<double> weeklySteps = [];
    List<String> weekDays = [];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final steps = prefs.getInt('steps_$dateKey') ?? 0;
      weeklySteps.add(steps.toDouble());
      weekDays.add(
        DateFormat('E').format(date),
      ); // Short day name (Mon, Tue, etc.)
    }

    maxSteps = weeklySteps.reduce((a, b) => a > b ? a : b);
    maxSteps = (maxSteps / 1000).ceil() * 1000;
    if (maxSteps < 5000) maxSteps = 5000;

    barGroups = List.generate(7, (index) {
      return _makeGroupData(index, weeklySteps[index], weekDays[index]);
    });
  }

  Future<void> _loadMonthlyData(SharedPreferences prefs, DateTime today) async {
    List<double> monthlySteps = [];
    List<String> dates = [];

    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final currentDay = today.day;

    for (int i = 0; i < daysInMonth; i++) {
      if (i > currentDay - 1) break; // Don't show future dates
      final date = DateTime(today.year, today.month, i + 1);
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final steps = prefs.getInt('steps_$dateKey') ?? 0;
      monthlySteps.add(steps.toDouble());
      dates.add(DateFormat('d').format(date)); // Day of month
    }

    maxSteps = monthlySteps.reduce((a, b) => a > b ? a : b);
    maxSteps = (maxSteps / 1000).ceil() * 1000;
    if (maxSteps < 5000) maxSteps = 5000;

    barGroups = List.generate(monthlySteps.length, (index) {
      return _makeGroupData(index, monthlySteps[index], dates[index]);
    });
  }

  BarChartGroupData _makeGroupData(int x, double y, String label) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: const LinearGradient(
            colors: [Color(0xFF6B48FF), Color(0xFF9C88FF)],
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
                    child: const Icon(
                      Icons.directions_walk,
                      color: Color(0xFF6B48FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Steps Comparison',
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
                height: 48, // Fixed height for the tab bar
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.all(4),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontSize: 14, // Reduced font size
                    fontWeight: FontWeight.w400,
                  ),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFF6B48FF),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B48FF).withOpacity(0.3),
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
                    SizedBox(
                      // Wrap in SizedBox for consistent width
                      width: 80,
                      child: Tab(text: 'Monthly'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
                          ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF6B48FF),
                            ),
                          )
                          : Column(
                            children: [
                              Text(
                                'Steps Progress',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Expanded(
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: maxSteps,
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
                                            '${rod.toY.toInt()} steps\n',
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
                                            } else if (_currentView ==
                                                'Weekly') {
                                              label =
                                                  barGroups[value.toInt()].x
                                                      .toString();
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
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    gridData: FlGridData(
                                      show: true,
                                      horizontalInterval: 1000,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: Colors.grey[800]!,
                                          strokeWidth: 0.5,
                                        );
                                      },
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: barGroups,
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
