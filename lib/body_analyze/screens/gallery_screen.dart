import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  void _showPhotoDetails(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder:
                (context, scrollController) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.blue[700]!, Colors.blue[900]!],
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(28),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.photo,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Photo Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CachedNetworkImage(
                                  imageUrl: data['url'] as String,
                                  width: double.infinity,
                                  height: 300,
                                  fit: BoxFit.cover,
                                  fadeInDuration: Duration(milliseconds: 300),
                                  fadeOutDuration: Duration(milliseconds: 300),
                                  maxWidthDiskCache: 800,
                                  maxHeightDiskCache: 800,
                                  memCacheWidth: 400,
                                  memCacheHeight: 400,
                                  placeholder:
                                      (context, url) => Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                        Colors.blue[300],
                                                      ),
                                                ),
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'Loading image...',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  errorWidget:
                                      (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        height: 300,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.error_outline,
                                                color: Colors.red[400],
                                                size: 32,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Failed to load image',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: Colors.red[400],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                              SizedBox(height: 24),
                              _buildDetailSection(
                                icon: Icons.calendar_today,
                                title: 'Date',
                                value: DateFormat('MMM dd, yyyy HH:mm').format(
                                  data['date'] is DateTime
                                      ? data['date'] as DateTime
                                      : (data['date'] as Timestamp).toDate(),
                                ),
                              ),
                              if (data['face'] != null) ...[
                                SizedBox(height: 16),
                                _buildDetailSection(
                                  icon: Icons.face,
                                  title: 'Face Detection',
                                  value:
                                      'Confidence: ${((data['face'] as Map)['confidence'] * 100).toStringAsFixed(1)}%',
                                ),
                                SizedBox(height: 16),
                                _buildDetailSection(
                                  icon: Icons.rotate_right,
                                  title: 'Head Position',
                                  value:
                                      'Y: ${(data['face'] as Map)['headAngleY']?.toStringAsFixed(1)}° | Z: ${(data['face'] as Map)['headAngleZ']?.toStringAsFixed(1)}°',
                                ),
                              ],
                              if (data['analysis'] != null) ...[
                                SizedBox(height: 24),
                                _buildAnalysisSection(
                                  data['analysis'] as Map<String, dynamic>,
                                ),
                              ],
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

  Widget _buildDetailSection({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue[700], size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(Map<String, dynamic> analysis) {
    final metrics = analysis['metrics'] as Map<String, dynamic>?;
    if (metrics == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[50]!, Colors.blue[100]!],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              _buildMetricRow('Cheeks', metrics['cheekChange']),
              _buildMetricRow('Face Width', metrics['faceWidthChange']),
              _buildMetricRow('Jawline', metrics['jawlineChange']),
              _buildMetricRow('Neck Area', metrics['neckChange']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricRow(String label, double? value) {
    if (value == null || value.abs() <= 2.0) return SizedBox.shrink();

    final isReduction = value < 0;
    final color = isReduction ? Colors.green : Colors.red;
    final icon = isReduction ? Icons.trending_down : Icons.trending_up;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${value.abs().toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF0D47A1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Progress Gallery',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: _buildGalleryContent(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/home'),
        backgroundColor: Colors.blue[700],
        icon: Icon(Icons.add_a_photo),
        label: Text(
          'Add Photo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildGalleryContent() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('photos')
              .orderBy('date', descending: true)
              .limit(20) // Limit initial load
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading your progress...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Error loading photos',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.red),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyGallery(context);
        }

        // Organize photos by month, week, and day
        final photos =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['date'] as Timestamp;
              return {...data, 'date': timestamp.toDate()};
            }).toList();

        // Group photos by month
        final monthlyPhotos = _groupPhotosByMonth(photos);

        if (monthlyPhotos['months'] == null) {
          return _buildEmptyGallery(context);
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: (monthlyPhotos['months'] as List).length,
          itemBuilder: (context, monthIndex) {
            final monthData =
                (monthlyPhotos['months'] as List)[monthIndex]
                    as Map<String, dynamic>;
            final monthDate = monthData['date'] as DateTime;
            final monthPhotos =
                monthData['photos'] as List<Map<String, dynamic>>;

            return _buildMonthSection(context, monthDate, monthPhotos);
          },
        );
      },
    );
  }

  Widget _buildMonthSection(
    BuildContext context,
    DateTime monthDate,
    List<Map<String, dynamic>> monthPhotos,
  ) {
    // Group photos by week
    final weeklyPhotos = _groupPhotosByWeek(monthPhotos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            DateFormat('MMMM yyyy').format(monthDate),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        ...weeklyPhotos.map((weekData) {
          final weekPhotos = weekData['photos'] as List<Map<String, dynamic>>;
          final weekStart = weekData['startDate'] as DateTime;
          final weekEnd = weekData['endDate'] as DateTime;

          return _buildWeekSection(context, weekStart, weekEnd, weekPhotos);
        }),
        Divider(height: 32, thickness: 2),
      ],
    );
  }

  Widget _buildWeekSection(
    BuildContext context,
    DateTime weekStart,
    DateTime weekEnd,
    List<Map<String, dynamic>> weekPhotos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, top: 8, bottom: 16),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Week ${DateFormat('d').format(weekStart)} - ${DateFormat('d').format(weekEnd)}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: weekPhotos.length,
          itemBuilder: (context, index) {
            final photo = weekPhotos[index];
            return _buildPhotoThumbnail(context, photo);
          },
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhotoThumbnail(
    BuildContext context,
    Map<String, dynamic> photo,
  ) {
    final date = photo['date'] as DateTime;
    final url = photo['url'] as String;
    final analysis = photo['analysis'] as Map<String, dynamic>?;
    final type = analysis?['type'] as String? ?? 'neutral';

    return GestureDetector(
      onTap: () => _showPhotoDetails(context, photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  fadeInDuration: Duration(milliseconds: 200),
                  fadeOutDuration: Duration(milliseconds: 200),
                  maxWidthDiskCache: 300,
                  maxHeightDiskCache: 300,
                  memCacheWidth: 150,
                  memCacheHeight: 150,
                  placeholder:
                      (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.blue[300],
                              ),
                            ),
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red[300],
                            size: 22,
                          ),
                        ),
                      ),
                ),
              ),
            ),
            if (type != 'neutral')
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 18,
                  ),
                ),
              ),
            if (type == 'neutral')
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.photo_camera,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _groupPhotosByMonth(List<Map<String, dynamic>> photos) {
    final Map<String, List<Map<String, dynamic>>> monthGroups = {};

    for (var photo in photos) {
      final date = photo['date'] as DateTime;
      final monthKey = DateFormat('yyyy-MM').format(date);

      monthGroups.putIfAbsent(monthKey, () => []).add(photo);
    }

    return {
      'months':
          monthGroups.entries.map((entry) {
            final firstPhotoDate = entry.value.first['date'] as DateTime;
            return {'date': firstPhotoDate, 'photos': entry.value};
          }).toList(),
    };
  }

  List<Map<String, dynamic>> _groupPhotosByWeek(
    List<Map<String, dynamic>> monthPhotos,
  ) {
    final Map<String, List<Map<String, dynamic>>> weekGroups = {};

    for (var photo in monthPhotos) {
      final date = photo['date'] as DateTime;
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      final weekKey = DateFormat('yyyy-MM-dd').format(weekStart);

      weekGroups.putIfAbsent(weekKey, () => []).add(photo);
    }

    return weekGroups.entries.map((entry) {
        final weekStart = DateTime.parse(entry.key);
        final weekEnd = weekStart.add(Duration(days: 6));
        return {
          'startDate': weekStart,
          'endDate': weekEnd,
          'photos': entry.value,
        };
      }).toList()
      ..sort(
        (a, b) =>
            (b['startDate'] as DateTime).compareTo(a['startDate'] as DateTime),
      );
  }

  Widget _buildEmptyGallery(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No photos yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start tracking your progress by adding photos',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: Icon(Icons.add_a_photo),
            label: Text(
              'Add First Photo',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'loss':
        return Colors.green;
      case 'gain':
        return Colors.red;
      case 'maintain':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'loss':
        return Icons.trending_down;
      case 'gain':
        return Icons.trending_up;
      case 'maintain':
        return Icons.horizontal_rule;
      default:
        return Icons.photo;
    }
  }

  String _getChangeText(double change) {
    if (change.abs() <= 2.0) return 'No significant change';
    final direction = change < 0 ? 'improvement' : 'decline';
    return '${change.abs().toStringAsFixed(1)}% $direction';
  }
}
