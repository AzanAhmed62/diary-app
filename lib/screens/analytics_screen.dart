import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '30d';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateDateRange();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case '7d':
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
        break;
      case '30d':
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
        break;
      case '90d':
        _startDate = now.subtract(const Duration(days: 90));
        _endDate = now;
        break;
      case '1y':
        _startDate = DateTime(now.year - 1, now.month, now.day);
        _endDate = now;
        break;
      default:
        _startDate = now.subtract(const Duration(days: 30));
        _endDate = now;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: theme.colorScheme.surfaceVariant,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.date_range),
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _updateDateRange();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              const PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              const PopupMenuItem(value: '90d', child: Text('Last 3 months')),
              const PopupMenuItem(value: '1y', child: Text('Last year')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Activity', icon: Icon(Icons.timeline)),
            Tab(text: 'Moods', icon: Icon(Icons.mood)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildActivityTab(),
          _buildMoodsTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = AnalyticsService.getWritingStats(
      startDate: _startDate,
      endDate: _endDate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          
          // Summary cards
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Entries',
                '${stats['totals']?['entries'] ?? 0}',
                Icons.note,
                Colors.blue,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Words',
                '${stats['totals']?['words'] ?? 0}',
                Icons.text_fields,
                Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(child: _buildStatCard(
                'Avg/Day',
                '${stats['averages']?['wordsPerDay'] ?? 0}',
                Icons.trending_up,
                Colors.orange,
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(
                'Streak',
                '${stats['streak']?['currentStreak'] ?? 0} days',
                Icons.local_fire_department,
                Colors.red,
              )),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Writing activity chart
          _buildSectionTitle('Writing Activity'),
          const SizedBox(height: 16),
          _buildActivityChart(),
          
          const SizedBox(height: 24),
          
          // Quick stats
          _buildSectionTitle('Quick Stats'),
          const SizedBox(height: 16),
          _buildQuickStats(stats),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    final activity = AnalyticsService.getWritingActivity(
      startDate: _startDate,
      endDate: _endDate,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          
          _buildSectionTitle('Daily Word Count'),
          const SizedBox(height: 16),
          _buildWordCountChart(activity),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Daily Entries'),
          const SizedBox(height: 16),
          _buildEntriesChart(activity),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Activity Calendar'),
          const SizedBox(height: 16),
          _buildActivityCalendar(activity),
        ],
      ),
    );
  }

  Widget _buildMoodsTab() {
    final moodTrends = AnalyticsService.getMoodTrends(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    final stats = AnalyticsService.getWritingStats(
      startDate: _startDate,
      endDate: _endDate,
    );
    
    final moodCounts = stats['moods'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          
          if (moodCounts.isNotEmpty) ...[
            _buildSectionTitle('Mood Distribution'),
            const SizedBox(height: 16),
            _buildMoodPieChart(moodCounts),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Mood Trends'),
            const SizedBox(height: 16),
            _buildMoodTrendsChart(moodTrends),
            
            const SizedBox(height: 24),
            
            _buildSectionTitle('Mood Summary'),
            const SizedBox(height: 16),
            _buildMoodSummary(moodCounts),
          ] else ...[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mood, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No mood data available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start adding moods to your entries to see trends',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    final insights = AnalyticsService.getProductivityInsights();
    final topTags = AnalyticsService.getTopTags();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodHeader(),
          const SizedBox(height: 20),
          
          _buildSectionTitle('Productivity Insights'),
          const SizedBox(height: 16),
          _buildProductivityInsights(insights),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Top Tags'),
          const SizedBox(height: 16),
          _buildTopTags(topTags),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Writing Patterns'),
          const SizedBox(height: 16),
          _buildWritingPatterns(insights),
        ],
      ),
    );
  }

  Widget _buildPeriodHeader() {
    final formatter = DateFormat('MMM d, yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Period: ${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Chip(
            label: Text(_getPeriodLabel()),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case '7d': return '7 Days';
      case '30d': return '30 Days';
      case '90d': return '3 Months';
      case '1y': return '1 Year';
      default: return '30 Days';
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    final activity = AnalyticsService.getWritingActivity(
      startDate: _startDate,
      endDate: _endDate,
    );

    if (activity.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No activity data')),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < activity.length; i++) {
      final words = activity[i]['words'] as int;
      spots.add(FlSpot(i.toDouble(), words.toDouble()));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: activity.length > 30 ? 7 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < activity.length) {
                    final date = activity[index]['date'] as DateTime;
                    return Text(
                      DateFormat('M/d').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCountChart(List<Map<String, dynamic>> activity) {
    if (activity.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < activity.length; i++) {
      final words = activity[i]['words'] as int;
      spots.add(FlSpot(i.toDouble(), words.toDouble()));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: activity.length > 30 ? 7 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < activity.length) {
                    final date = activity[index]['date'] as DateTime;
                    return Text(
                      DateFormat('M/d').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.green.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesChart(List<Map<String, dynamic>> activity) {
    if (activity.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available')),
      );
    }

    final bars = <BarChartGroupData>[];
    for (int i = 0; i < activity.length; i++) {
      final entries = activity[i]['entries'] as int;
      bars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: entries.toDouble(),
            color: Colors.orange,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: activity.length > 30 ? 7 : 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < activity.length) {
                    final date = activity[index]['date'] as DateTime;
                    return Text(
                      DateFormat('M/d').format(date),
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          barGroups: bars,
        ),
      ),
    );
  }

  Widget _buildActivityCalendar(List<Map<String, dynamic>> activity) {
    // This would be a heatmap-style calendar showing activity levels
    // For now, we'll show a simplified grid
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Activity Calendar\n(Heatmap view coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMoodPieChart(Map<String, dynamic> moodCounts) {
    final sections = <PieChartSectionData>[];
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
    ];
    
    int colorIndex = 0;
    moodCounts.forEach((mood, count) {
      final emoji = MoodConstants.moodEmojis[mood] ?? '😊';
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        title: '$emoji\n$count',
        color: colors[colorIndex % colors.length],
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ));
      colorIndex++;
    });

    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: sections,
          centerSpaceRadius: 40,
          sectionsSpace: 2,
        ),
      ),
    );
  }

  Widget _buildMoodTrendsChart(List<Map<String, dynamic>> moodTrends) {
    // This would show mood trends over time
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Mood Trends Chart\n(Timeline view coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildMoodSummary(Map<String, dynamic> moodCounts) {
    final sortedMoods = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedMoods.map((entry) {
        final mood = entry.key;
        final count = entry.value;
        final emoji = MoodConstants.moodEmojis[mood] ?? '😊';
        final total = moodCounts.values.fold(0, (sum, value) => sum + value);
        final percentage = ((count / total) * 100).round();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mood.toUpperCase(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: count / total,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count ($percentage%)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    final totals = stats['totals'] as Map<String, dynamic>? ?? {};
    final averages = stats['averages'] as Map<String, dynamic>? ?? {};
    
    return Column(
      children: [
        _buildQuickStatRow('Total Characters', '${totals['characters'] ?? 0}'),
        _buildQuickStatRow('Total Edits', '${totals['edits'] ?? 0}'),
        _buildQuickStatRow('Average Entries/Day', '${averages['entriesPerDay']?.toStringAsFixed(1) ?? '0.0'}'),
        _buildQuickStatRow('Estimated Reading Time', _formatDuration(totals['estimatedReadingTime'] ?? Duration.zero)),
      ],
    );
  }

  Widget _buildQuickStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityInsights(Map<String, dynamic> insights) {
    final trends = insights['trends'] as Map<String, dynamic>? ?? {};
    final patterns = insights['patterns'] as Map<String, dynamic>? ?? {};
    final streaks = insights['streaks'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        _buildInsightCard(
          'Writing Trend',
          trends['wordsTrendUp'] == true ? 'Trending Up! 📈' : 'Keep Going! 📊',
          trends['wordsTrendUp'] == true ? Colors.green : Colors.orange,
          trends['wordsTrendUp'] == true
              ? 'You\'re writing more words recently'
              : 'Your writing volume could use a boost',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          'Best Writing Day',
          '${patterns['bestDayOfWeek'] ?? 'Unknown'} 📅',
          Colors.blue,
          'You tend to write most on this day',
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          'Current Streak',
          '${streaks['current'] ?? 0} days 🔥',
          Colors.red,
          'Keep the momentum going!',
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String value, Color color, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTags(List<Map<String, dynamic>> topTags) {
    if (topTags.isEmpty) {
      return const Center(
        child: Text(
          'No tags used yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: topTags.take(10).map((tagData) {
        final tag = tagData['tag'] as String;
        final count = tagData['count'] as int;
        final maxCount = topTags.first['count'] as int;
        final ratio = count / maxCount;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  tag,
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWritingPatterns(Map<String, dynamic> insights) {
    final patterns = insights['patterns'] as Map<String, dynamic>? ?? {};
    
    return Column(
      children: [
        _buildPatternRow('Best Writing Day', '${patterns['bestDayOfWeek'] ?? 'Unknown'}'),
        _buildPatternRow('Most Productive Hour', '${patterns['mostProductiveHour'] ?? 'Unknown'}:00'),
      ],
    );
  }

  Widget _buildPatternRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
