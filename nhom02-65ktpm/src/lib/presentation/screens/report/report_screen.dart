import 'package:flutter/material.dart';

import '../../../application/build_weekly_report.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/report_strings.dart';
import '../../widgets/disclaimer_note.dart';
import '../../utils/formatters.dart';
import 'weekly_comparison_chart.dart';

/// Báo cáo tuần: số liệu thô, biểu đồ so sánh tuần trước, nhận xét tích cực.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final Stream<WeeklyReport> _stream = sl<BuildWeeklyReport>().watch();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(ReportStrings.title)),
      body: StreamBuilder<WeeklyReport>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text(ReportStrings.loadError));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return _ReportBody(report: snapshot.data!);
        },
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final WeeklyReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = report.current;
    final weekEnd = current.weekStart.add(const Duration(days: 6));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        Text(
          ReportStrings.weekRange(
            Formatters.shortDate(current.weekStart),
            Formatters.shortDate(weekEnd),
          ),
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (!report.currentSufficient)
          Card(
            color: theme.colorScheme.secondaryContainer,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text(ReportStrings.notEnoughData),
              subtitle: Text(ReportStrings.notEnoughDataHint(
                current.loggedDays,
                AppConfig.minLoggedDaysForSufficientWeek,
              )),
            ),
          ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.9,
          children: [
            _StatTile(
              icon: Icons.event_available_outlined,
              label: ReportStrings.loggedDays,
              value: '${current.loggedDays}/7',
            ),
            _StatTile(
              icon: Icons.local_cafe_outlined,
              label: ReportStrings.sugaryDrinks,
              value: '${current.sugaryDrinks}',
            ),
            _StatTile(
              icon: Icons.eco_outlined,
              label: ReportStrings.vegMeals,
              value: '${current.mealsWithVeg}/${current.totalMeals}',
            ),
            _StatTile(
              icon: Icons.local_fire_department_outlined,
              label: ReportStrings.highFatItems,
              value: '${current.highFatItems}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ReportStrings.chartTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 12),
                WeeklyComparisonChart(current: current, previous: report.previous),
                if (!report.previousSufficient) ...[
                  const SizedBox(height: 8),
                  Text(ReportStrings.previousNotEnough, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
        if (report.feedback.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ReportStrings.feedbackTitle, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (final f in report.feedback)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.auto_awesome, size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(ReportStrings.feedback(f))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        const DisclaimerNote(full: true),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
