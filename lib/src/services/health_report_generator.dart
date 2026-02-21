import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/care_data.dart';
import '../models/plant.dart';

class HealthReportGenerator {
  /// Generate a health report PDF for a plant
  Future<File> generatePDF({
    required Plant plant,
    required List<CareLog> careLogs,
    required int totalWaterings,
    required int totalFertilizations,
    required int currentStreak,
    required DateTime? lastWateredDate,
  }) async {
    final pdf = pw.Document();

    // Calculate statistics
    final waterLogs =
        careLogs.where((log) => log.type == CareType.water).toList();
    final fertilizeLogs =
        careLogs.where((log) => log.type == CareType.fertilize).toList();

    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));
    final recentLogs =
        careLogs.where((log) => log.date.isAfter(last30Days)).toList();

    // Add page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(10)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Plant Health Report',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      plant.nameEn,
                      style: pw.TextStyle(
                        fontSize: 20,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.Text(
                      plant.scientific,
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.green100,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Summary Section
              _buildSection(
                'Summary',
                [
                  _buildStatRow('Total Waterings', totalWaterings.toString()),
                  _buildStatRow(
                      'Total Fertilizations', totalFertilizations.toString()),
                  _buildStatRow('Current Streak', '$currentStreak days 🔥'),
                  _buildStatRow(
                    'Last Watered',
                    lastWateredDate != null
                        ? DateFormat('MMM dd, yyyy').format(lastWateredDate)
                        : 'Never',
                  ),
                  _buildStatRow(
                      'Total Care Actions', careLogs.length.toString()),
                ],
              ),

              pw.SizedBox(height: 20),

              // Recent Activity (Last 30 Days)
              _buildSection(
                'Recent Activity (Last 30 Days)',
                [
                  _buildStatRow('Water',
                      '${recentLogs.where((l) => l.type == CareType.water).length} times'),
                  _buildStatRow('Fertilize',
                      '${recentLogs.where((l) => l.type == CareType.fertilize).length} times'),
                  _buildStatRow('Prune',
                      '${recentLogs.where((l) => l.type == CareType.prune).length} times'),
                  _buildStatRow('Repot',
                      '${recentLogs.where((l) => l.type == CareType.repot).length} times'),
                ],
              ),

              pw.SizedBox(height: 20),

              // Plant Care Info
              _buildSection(
                'Care Requirements',
                [
                  _buildStatRow(
                      'Watering Interval', '${plant.waterIntervalDays} days'),
                  _buildStatRow('Fertilizing Interval',
                      '${plant.fertilizeIntervalDays} days'),
                  _buildStatRow('Light Requirements', plant.light as String),
                  _buildStatRow('Difficulty', plant.difficulty as String),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey300),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated on ${DateFormat('MMM dd, yyyy').format(now)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Plantify App 🌱',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.green700,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save to file
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/plant_health_report_${plant.id}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildStatRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
