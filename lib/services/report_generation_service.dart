import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/bounty_rules.dart';

enum UserReportType { requester, helper }

class ReportGenerationService {
  ReportGenerationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _blue = PdfColor.fromInt(0xFF3B82F6);
  static const _lightBlue = PdfColor.fromInt(0xFFEFF6FF);
  static const _purple = PdfColor.fromInt(0xFFA78BFA);
  static const _lightPurple = PdfColor.fromInt(0xFFF5F3FF);
  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _muted = PdfColor.fromInt(0xFF6B7280);

  Future<void> generateRequesterReport() async {
    final data = await _loadData(UserReportType.requester);
    final bytes = await _buildPdf(data);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'campus-bughunter-requester-report.pdf',
    );
  }

  Future<void> generateHelperReport() async {
    final data = await _loadData(UserReportType.helper);
    final bytes = await _buildPdf(data);
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'campus-bughunter-helper-report.pdf',
    );
  }

  Future<_ReportData> _loadData(UserReportType type) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not signed in');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final profile = userDoc.data() ?? {};
    final now = DateTime.now();
    final semesterStart = DateTime(now.year, now.month - 6, now.day);

    final bountyQuery = type == UserReportType.requester
        ? await _firestore
              .collection('bounties')
              .where('ownerId', isEqualTo: user.uid)
              .get()
        : await _firestore
              .collection('bounties')
              .where('hunterId', isEqualTo: user.uid)
              .get();

    final allBounties = bountyQuery.docs
        .map((doc) => _BountyReportItem(doc.id, doc.data()))
        .where((item) {
          if (type == UserReportType.helper) {
            return item.status == 'COMPLETED';
          }
          return true;
        })
        .toList();
    final recentBounties = allBounties.where((item) {
      final date = item.createdAt ?? item.claimedAt ?? item.completedAt;
      return date != null && !date.isBefore(semesterStart);
    }).toList();

    final reportSnapshot = await _firestore
        .collection('issue_reports')
        .where('reporterId', isEqualTo: user.uid)
        .get();
    final role = type == UserReportType.helper ? 'hunter' : 'requester';
    final recentReports = reportSnapshot.docs.map((doc) => doc.data()).where((
      data,
    ) {
      final createdAt = timestampDate(data['createdAt']);
      return data['reporterRole'] == role &&
          createdAt != null &&
          !createdAt.isBefore(semesterStart);
    }).toList();

    return _ReportData(
      type: type,
      displayName:
          profile['username']?.toString() ??
          user.email ??
          'Campus BugHunter User',
      allBounties: allBounties,
      recentBounties: recentBounties,
      recentReports: recentReports,
    );
  }

  Future<List<int>> _buildPdf(_ReportData data) async {
    final logoBytes = await rootBundle.load('assets/images/blue_tone_icon.png');
    final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 84, 42, 64),
          theme: pw.ThemeData.withFont(),
        ),
        header: (context) => _header(context, logo),
        footer: _footer,
        build: (context) => [
          _cover(data),
          pw.SizedBox(height: 22),
          _summarySection(data),
          pw.SizedBox(height: 18),
          _techSection(data),
          pw.SizedBox(height: 18),
          _bountySection(data),
          pw.SizedBox(height: 18),
          _reportIssueSection(data),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _header(pw.Context context, pw.ImageProvider logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _blue, width: 1.2)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 46,
            height: 46,
            decoration: pw.BoxDecoration(
              color: _lightBlue,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Image(logo, fit: pw.BoxFit.cover),
          ),
          pw.SizedBox(width: 14),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Campus BugHunter Officially Generated',
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Performance report powered by Campus BugHunter',
                style: const pw.TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ),
          pw.Spacer(),
          pw.Container(width: 36, height: 4, color: _purple),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _purple, width: 0.8)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Copyright 2026 Campus BugHunter Demo. Generated for platform activity review only. Confidential student activity summary.',
              style: const pw.TextStyle(color: _muted, fontSize: 8),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              color: _ink,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _cover(_ReportData data) {
    final title = data.type == UserReportType.requester
        ? 'Requester Activity Report'
        : 'Helper Activity Report';
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(colors: [_lightBlue, _lightPurple]),
        borderRadius: pw.BorderRadius.circular(22),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 30,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Prepared for ${data.displayName}',
            style: const pw.TextStyle(color: _muted, fontSize: 13),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            data.type == UserReportType.requester
                ? 'This report reviews your bounty posting history, technical interests, spending distribution, and recent issue reports.'
                : 'This report reviews your completed bounty history, technical strengths, reward distribution, and recent issue reports.',
            style: const pw.TextStyle(
              color: _ink,
              fontSize: 13,
              lineSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _summarySection(_ReportData data) {
    final totalCount = data.allBounties.length;
    final semesterCount = data.recentBounties.length;
    return _section(
      title: 'Your Platform Snapshot',
      child: pw.Row(
        children: [
          pw.Expanded(
            child: _metricCard(
              data.type == UserReportType.requester
                  ? 'Total posted bounties'
                  : 'Total completed bounties',
              '$totalCount',
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(child: _metricCard('Last semester', '$semesterCount')),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: _metricCard(
              data.type == UserReportType.requester
                  ? 'Total posted value'
                  : 'Total earned',
              'RM ${data.totalValue.toStringAsFixed(2)}',
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _techSection(_ReportData data) {
    final allTech = _countTech(data.allBounties);
    final recentTech = _countTech(data.recentBounties);
    final allTop = _topKey(allTech);
    final recentTop = _topKey(recentTech);
    final talentText = data.type == UserReportType.requester
        ? 'The topics that once felt confusing may now feel more familiar. Do you have more confidence and experience now? Campus BugHunter is always with you when new challenges appear.'
        : 'You seem especially strong in ${_mergedTopSkills(allTop, recentTop)}. While helping others, you may also have learned a lot. Please keep using your experience and talent to support students who need help.';

    return _section(
      title: 'Technical Stack Distribution',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _pieBlock('All time', allTech)),
              pw.SizedBox(width: 16),
              pw.Expanded(child: _pieBlock('Last semester', recentTech)),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            talentText,
            style: const pw.TextStyle(fontSize: 12, color: _ink),
          ),
          if (allTop != null || recentTop != null)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8),
              child: pw.Text(
                'Most frequent overall: ${allTop ?? 'Not enough data'}. Most frequent last semester: ${recentTop ?? 'Not enough data'}.',
                style: const pw.TextStyle(fontSize: 11, color: _muted),
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _bountySection(_ReportData data) {
    final valueCounts = _countRewardRanges(data.allBounties, data.type);
    final topRecent = _highestRecent(data);
    final rangeMessage = data.type == UserReportType.helper
        ? switch (_topKey(valueCounts)) {
            'RM 5-9.99' => 'The more, the better!',
            'RM 10-14.99' => 'Excellent ability!',
            'RM 15+' => 'Difficult problem hunter!',
            _ => 'Keep building your record!',
          }
        : 'Your bounty distribution shows how you invested in solving different levels of difficulty.';

    return _section(
      title: data.type == UserReportType.requester
          ? 'Bounty Spending Review'
          : 'Reward Earnings Review',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _pieBlock('Reward distribution', valueCounts)),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _metricCard(
                      data.type == UserReportType.requester
                          ? 'Last semester posted value'
                          : 'Last semester earned value',
                      'RM ${data.recentValue.toStringAsFixed(2)}',
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      rangeMessage,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (topRecent != null) ...[
            pw.SizedBox(height: 16),
            _bountyHighlight(data, topRecent),
          ],
        ],
      ),
    );
  }

  pw.Widget _reportIssueSection(_ReportData data) {
    final issueCounts = <String, int>{};
    for (final report in data.recentReports) {
      final type = report['issueType']?.toString() ?? 'Other';
      issueCounts[type] = (issueCounts[type] ?? 0) + 1;
    }
    final topIssue = _topKey(issueCounts);
    return _section(
      title: 'Issue Report Review',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _metricCard(
            'Reports in last semester',
            '${data.recentReports.length}',
          ),
          pw.SizedBox(height: 10),
          if (topIssue != null)
            pw.Text(
              'Your most common issue category was "$topIssue". We are continuously improving to bring you a better experience.',
              style: const pw.TextStyle(fontSize: 12, color: _ink),
            )
          else
            pw.Text(
              'Everything seems to have gone smoothly. Great!',
              style: const pw.TextStyle(fontSize: 12, color: _ink),
            ),
        ],
      ),
    );
  }

  pw.Widget _bountyHighlight(_ReportData data, _BountyReportItem item) {
    final value = data.type == UserReportType.requester
        ? item.amount
        : item.hunterReceive;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightPurple,
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: _purple, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            data.type == UserReportType.requester
                ? 'Highest bounty you posted last semester'
                : 'Highest reward you earned last semester',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            item.title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${_formatDate(item.createdAt ?? item.completedAt)} | RM ${value.toStringAsFixed(2)}',
            style: const pw.TextStyle(color: _muted, fontSize: 10),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            _truncate(item.description, 190),
            maxLines: 3,
            overflow: pw.TextOverflow.clip,
            style: const pw.TextStyle(fontSize: 11, lineSpacing: 2),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            data.type == UserReportType.requester
                ? 'Do you still remember it? That difficult problem may have bothered you for a long time, but it was eventually solved.'
                : 'That problem must have been difficult, but the reward after completion was truly meaningful.',
            style: pw.TextStyle(
              color: _blue,
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _section({required String title, required pw.Widget child}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(18),
        border: pw.Border.all(
          color: const PdfColor.fromInt(0xFFD8B4FE),
          width: 0.7,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 6, height: 22, color: _blue),
              pw.SizedBox(width: 8),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  pw.Widget _metricCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: _lightBlue,
        borderRadius: pw.BorderRadius.circular(14),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: _muted, fontSize: 9)),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pieBlock(String title, Map<String, int> values) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 104,
              height: 104,
              child: pw.SvgImage(svg: _pieSvg(values)),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(child: _legend(values)),
          ],
        ),
      ],
    );
  }

  pw.Widget _legend(Map<String, int> values) {
    if (values.isEmpty) {
      return pw.Text(
        'No data yet',
        style: const pw.TextStyle(color: _muted, fontSize: 10),
      );
    }
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entries.length && i < 6; i++)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 5),
            child: pw.Row(
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  color: _chartColors[i % _chartColors.length],
                ),
                pw.SizedBox(width: 5),
                pw.Expanded(
                  child: pw.Text(
                    '${entries[i].key}: ${entries[i].value}',
                    style: const pw.TextStyle(fontSize: 9, color: _ink),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _pieSvg(Map<String, int> values) {
    if (values.isEmpty || values.values.every((value) => value == 0)) {
      return '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="42" fill="#E5E7EB"/></svg>';
    }

    final total = values.values.fold<int>(
      0,
      (runningTotal, value) => runningTotal + value,
    );
    var start = -math.pi / 2;
    final paths = <String>[];
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (var i = 0; i < entries.length; i++) {
      final sweep = entries[i].value / total * math.pi * 2;
      final end = start + sweep;
      paths.add(
        _arcPath(start, end, _colorHex(_chartColors[i % _chartColors.length])),
      );
      start = end;
    }
    return '<svg viewBox="0 0 100 100">${paths.join()}<circle cx="50" cy="50" r="19" fill="#FFFFFF"/></svg>';
  }

  String _arcPath(double start, double end, String color) {
    const cx = 50.0;
    const cy = 50.0;
    const r = 42.0;
    final x1 = cx + r * math.cos(start);
    final y1 = cy + r * math.sin(start);
    final x2 = cx + r * math.cos(end);
    final y2 = cy + r * math.sin(end);
    final largeArc = end - start > math.pi ? 1 : 0;
    return '<path d="M $cx $cy L ${x1.toStringAsFixed(2)} ${y1.toStringAsFixed(2)} A $r $r 0 $largeArc 1 ${x2.toStringAsFixed(2)} ${y2.toStringAsFixed(2)} Z" fill="$color"/>';
  }

  Map<String, int> _countTech(List<_BountyReportItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      for (final stack in item.techStacks) {
        counts[stack] = (counts[stack] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, int> _countRewardRanges(
    List<_BountyReportItem> items,
    UserReportType type,
  ) {
    final counts = {'RM 5-9.99': 0, 'RM 10-14.99': 0, 'RM 15+': 0};
    for (final item in items) {
      final value = type == UserReportType.requester
          ? item.amount
          : item.hunterReceive;
      if (value < 10) {
        counts['RM 5-9.99'] = counts['RM 5-9.99']! + 1;
      } else if (value < 15) {
        counts['RM 10-14.99'] = counts['RM 10-14.99']! + 1;
      } else {
        counts['RM 15+'] = counts['RM 15+']! + 1;
      }
    }
    return counts;
  }

  _BountyReportItem? _highestRecent(_ReportData data) {
    if (data.recentBounties.isEmpty) return null;
    final items = [...data.recentBounties];
    items.sort((a, b) {
      final av = data.type == UserReportType.requester
          ? a.amount
          : a.hunterReceive;
      final bv = data.type == UserReportType.requester
          ? b.amount
          : b.hunterReceive;
      return bv.compareTo(av);
    });
    return items.first;
  }

  String? _topKey(Map<String, int> values) {
    if (values.isEmpty) return null;
    final entries = values.entries.where((entry) => entry.value > 0).toList();
    if (entries.isEmpty) return null;
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  String _mergedTopSkills(String? allTop, String? recentTop) {
    final skills = <String>{};
    if (allTop != null) skills.add(allTop);
    if (recentTop != null) skills.add(recentTop);
    if (skills.isEmpty) return 'new technical challenges';
    return skills.join(' and ');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not recorded';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}...';
  }

  String _colorHex(PdfColor color) {
    final r = (color.red * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (color.green * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (color.blue * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }
}

const _chartColors = [
  PdfColor.fromInt(0xFF60A5FA),
  PdfColor.fromInt(0xFFA78BFA),
  PdfColor.fromInt(0xFF38BDF8),
  PdfColor.fromInt(0xFFC084FC),
  PdfColor.fromInt(0xFF818CF8),
  PdfColor.fromInt(0xFF93C5FD),
];

class _ReportData {
  final UserReportType type;
  final String displayName;
  final List<_BountyReportItem> allBounties;
  final List<_BountyReportItem> recentBounties;
  final List<Map<String, dynamic>> recentReports;

  const _ReportData({
    required this.type,
    required this.displayName,
    required this.allBounties,
    required this.recentBounties,
    required this.recentReports,
  });

  double get totalValue => allBounties.fold<double>(
    0,
    (runningTotal, item) =>
        runningTotal +
        (type == UserReportType.requester ? item.amount : item.hunterReceive),
  );

  double get recentValue => recentBounties.fold<double>(
    0,
    (runningTotal, item) =>
        runningTotal +
        (type == UserReportType.requester ? item.amount : item.hunterReceive),
  );
}

class _BountyReportItem {
  final String id;
  final Map<String, dynamic> data;

  const _BountyReportItem(this.id, this.data);

  String get status => (data['status'] ?? '').toString().toUpperCase();
  String get title {
    final value = data['title']?.toString().trim();
    return value == null || value.isEmpty ? 'Untitled bounty' : value;
  }

  String get description =>
      data['description']?.toString() ?? 'No description provided.';
  double get amount => (data['amount'] ?? 0).toDouble();
  double get hunterReceive =>
      (data['hunterReceive'] ??
              amount - ((data['platformFee'] ?? amount * 0.05).toDouble()))
          .toDouble();
  DateTime? get createdAt => timestampDate(data['createdAt']);
  DateTime? get claimedAt => timestampDate(data['claimedAt']);
  DateTime? get completedAt => timestampDate(data['completedAt']);
  List<String> get techStacks =>
      (data['techStacks'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
}
