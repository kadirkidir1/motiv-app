import 'package:flutter/material.dart';
import '../models/routine.dart';

class ProgressChart extends StatelessWidget {
  final List<RoutineProgress> progressList;
  final String period;

  const ProgressChart({
    super.key,
    required this.progressList,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlerleme Grafiği ($period)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildChart(),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final data = _processDataForPeriod();
    if (data.isEmpty) return const Center(child: Text('Veri yok'));

    final maxValue = data.map((e) => e['value'] as double).reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.asMap().entries.map((entry) {
        final item = entry.value;
        final value = item['value'] as double;
        final label = item['label'] as String;
        
        final height = maxValue > 0 ? (value / maxValue) * 100 : 0.0;
        
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: value > 0 ? Colors.blue.shade400 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _processDataForPeriod() {
    switch (period) {
      case 'Günlük':
        return _getDailyData();
      case 'Haftalık':
        return _getWeeklyData();
      case 'Aylık':
        return _getMonthlyData();
      default:
        return _getDailyData();
    }
  }

  List<Map<String, dynamic>> _getDailyData() {
    return progressList.take(14).map((progress) {
      return {
        'label': '${progress.date.day}/${progress.date.month}',
        'value': progress.completed ? (progress.minutesSpent.toDouble()) : 0.0,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _getWeeklyData() {
    final weeklyData = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      
      final weekProgress = progressList.where((p) =>
        p.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        p.date.isBefore(weekEnd.add(const Duration(days: 1)))
      ).toList();
      
      final totalMinutes = weekProgress
          .where((p) => p.completed)
          .fold(0.0, (sum, p) => sum + (p.minutesSpent.toDouble()));
      
      weeklyData.add({
        'label': 'H${4-i}',
        'value': totalMinutes,
      });
    }
    
    return weeklyData;
  }

  List<Map<String, dynamic>> _getMonthlyData() {
    final monthlyData = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      
      final monthProgress = progressList.where((p) =>
        p.date.year == month.year && p.date.month == month.month
      ).toList();
      
      final totalMinutes = monthProgress
          .where((p) => p.completed)
          .fold(0.0, (sum, p) => sum + (p.minutesSpent.toDouble()));
      
      monthlyData.add({
        'label': '${month.month}/${month.year.toString().substring(2)}',
        'value': totalMinutes,
      });
    }
    
    return monthlyData;
  }
}