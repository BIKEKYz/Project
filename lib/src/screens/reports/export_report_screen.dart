import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/stores/care_store.dart';
import '../../models/plant.dart';
import '../../services/health_report_generator.dart';
import '../../theme/app_colors.dart';

class ExportReportScreen extends StatefulWidget {
  final Plant plant;

  const ExportReportScreen({
    super.key,
    required this.plant,
  });

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  final HealthReportGenerator _generator = HealthReportGenerator();
  bool _isGenerating = false;

  Future<void> _generateAndShare() async {
    setState(() => _isGenerating = true);

    try {
      final careStore = context.read<CareStore>();

      // Get care history for this plant
      final careLogs = careStore.history
          .where((log) => log.plantId == widget.plant.id)
          .toList();

      // Calculate statistics
      final waterLogs = careLogs
          .where((log) => log.type.toString().contains('water'))
          .toList();
      final fertilizeLogs = careLogs
          .where((log) => log.type.toString().contains('fertilize'))
          .toList();

      final status = careStore.getPlantStatus(widget.plant.id);
      final lastWatered = status?.lastWateredDate;

      // Generate PDF
      final File pdfFile = await _generator.generatePDF(
        plant: widget.plant,
        careLogs: careLogs,
        totalWaterings: waterLogs.length,
        totalFertilizations: fertilizeLogs.length,
        currentStreak: 0, // TODO: Calculate actual streak
        lastWateredDate: lastWatered,
      );

      // Share the file
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: '${widget.plant.nameEn} Health Report 🌱',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully! 📊')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Report',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Plant Info Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.eco,
                      size: 60,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.plant.nameEn,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.plant.scientific,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Feature Description
            _buildFeatureCard(
              icon: Icons.picture_as_pdf,
              title: 'PDF Report',
              description: 'Beautiful PDF with all your plant care statistics',
              color: Colors.red[700]!,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.share,
              title: 'Easy Sharing',
              description: 'Share your plant care achievements with friends',
              color: Colors.blue[700]!,
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              icon: Icons.bar_chart,
              title: 'Detailed Stats',
              description: 'Care frequency, streak, and growth timeline',
              color: Colors.green[700]!,
            ),

            const SizedBox(height: 32),

            // Generate Button
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateAndShare,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              icon: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.file_download),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate & Share Report',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.notoSansThai(fontSize: 12),
        ),
      ),
    );
  }
}
