import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class ParallelApiTestPage extends StatefulWidget {
  const ParallelApiTestPage({Key? key}) : super(key: key);

  @override
  State<ParallelApiTestPage> createState() => _ParallelApiTestPageState();
}

class _ParallelApiTestPageState extends State<ParallelApiTestPage> {
  // Define smaller text styles
  final TextStyle _labelStyle = const TextStyle(fontSize: 12);
  final TextStyle _inputStyle = const TextStyle(fontSize: 14);
  final TextStyle _buttonTextStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  final TextStyle _statsTitleStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  final TextStyle _statsValueStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
  final TextStyle _chartAxisLabelStyle = const TextStyle(fontSize: 9);
  final TextStyle _dashboardTitleStyle = const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);


  Widget _buildHistogram(BuildContext context) {
    // Ensure there are values before trying to reduce or build the chart
    if (_allResponseTimes.isEmpty) {
      return const Center(child: Text('No data yet for histogram', style: TextStyle(fontSize: 12)));
    }
    
    final bins = 10;
    // It's safer to check again, though the top check should cover this.
    if (_allResponseTimes.isEmpty) return const Center(child: Text('Not enough data for histogram'));
    
    final minVal = _allResponseTimes.reduce((a, b) => a < b ? a : b);
    final maxVal = _allResponseTimes.reduce((a, b) => a > b ? a : b);
    
    final binSize = (maxVal - minVal > 0) ? (maxVal - minVal) / bins : 1.0; 

    final counts = List<int>.filled(bins, 0);
    for (final v in _allResponseTimes) {
      int idx = (binSize > 0) ? ((v - minVal) ~/ binSize).clamp(0, bins - 1) : 0;
      counts[idx]++;
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (value, meta) {
              return Text(value.toInt().toString(), style: _chartAxisLabelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface));
            }),
            axisNameWidget: Text("Frequency", style: _chartAxisLabelStyle.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            axisNameSize: 20,
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int idx = value.toInt();
                if (idx < 0 || idx >= bins) return const SizedBox();
                final binStart = minVal + idx * binSize;
                final binEnd = binStart + binSize;
                if (binStart.isFinite && binEnd.isFinite) {
                    return Text('${binStart.toInt()}-${binEnd.toInt()}', style: _chartAxisLabelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface));
                }
                return const SizedBox();
              },
              reservedSize: 30, 
            ),
            axisNameWidget: Text("Response Time (ms)", style: _chartAxisLabelStyle.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            axisNameSize: 20,
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2))),
        barGroups: [
          for (int i = 0; i < bins; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: counts[i].toDouble(), color: Theme.of(context).colorScheme.primary, width: 15)
            ])
        ],
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), strokeWidth: 0.8)),
        minY: 0,
      ),
    );
  }

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _payloadController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '10');
  final TextEditingController _rpsController = TextEditingController(text: '5');
  String _selectedMethod = 'GET';
  bool _showPayload = false;
  bool _isTesting = false;
  List<double> _allResponseTimes = [];
  List<int> _requestsPerSecond = [];
  List<double> _successRate = [];
  int _totalRequests = 0;
  int _successCount = 0;
  int _failCount = 0;
  Timer? _timer;
  int _elapsed = 0;

  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded( // Make stat cards expand equally
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), // Slightly smaller radius
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: _statsTitleStyle.copyWith(color: color, fontSize: 13), // Adjusted font size
              ),
              const SizedBox(height: 6), // Reduced spacing
              Text(
                value.toString(),
                style: _statsValueStyle.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 18), // Adjusted font size
              ),
            ],
          ),
        ),
      ),
    );
  }

  final List<String> _methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];

  @override
  void dispose() {
    _timer?.cancel();
    _urlController.dispose();
    _payloadController.dispose();
    _durationController.dispose();
    _rpsController.dispose();
    super.dispose();
  }

  void _startTest() {
    setState(() {
      _isTesting = true;
      _allResponseTimes.clear();
      _requestsPerSecond.clear();
      _successRate.clear();
      _elapsed = 0;
      _totalRequests = 0;
      _successCount = 0;
      _failCount = 0;
    });
    int duration = int.tryParse(_durationController.text) ?? 10;
    int rps = int.tryParse(_rpsController.text) ?? 5;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async { // Make callback async
      int currentSecondSuccess = 0;
      int currentSecondFail = 0;
      List<double> currentSecondResponseTimes = [];

      for (int i = 0; i < rps; i++) {
        _totalRequests++;
        Stopwatch stopwatch = Stopwatch()..start();
        try {
          http.Response response;
          Uri uri = Uri.parse(_urlController.text);
          String method = _selectedMethod.toUpperCase();
          String? body = (_showPayload && _payloadController.text.isNotEmpty) ? _payloadController.text : null;
          Map<String, String> headers = {'Content-Type': 'application/json'};

          switch (method) {
            case 'POST':
              response = await http.post(uri, headers: headers, body: body);
              break;
            case 'PUT':
              response = await http.put(uri, headers: headers, body: body);
              break;
            case 'PATCH':
              response = await http.patch(uri, headers: headers, body: body);
              break;
            case 'DELETE':
              response = await http.delete(uri, headers: headers);
              break;
            case 'GET':
            default:
              response = await http.get(uri, headers: headers);
              break;
          }
          stopwatch.stop();
          double respTime = stopwatch.elapsedMilliseconds.toDouble();
          currentSecondResponseTimes.add(respTime);

          if (response.statusCode >= 200 && response.statusCode < 300) {
            _successCount++;
            currentSecondSuccess++;
          } else {
            _failCount++;
            currentSecondFail++;
          }
        } catch (e) {
          stopwatch.stop();
          // print('Error: ${e.toString()}'); // Optional: log error
          _failCount++;
          currentSecondFail++;
          // Optionally add a specific response time for errors if needed for histogram
          // currentSecondResponseTimes.add(5000.0); // Example: 5s for error
        }
      }

      setState(() {
        _elapsed++;
        _allResponseTimes.addAll(currentSecondResponseTimes);
        _requestsPerSecond.add(rps);
        _successRate.add(
            (currentSecondSuccess + currentSecondFail) > 0
            ? currentSecondSuccess / (currentSecondSuccess + currentSecondFail)
            : 0.0
        );
      });

      if (_elapsed >= duration) {
        _stopTest();
      }
    });
  }

  void _stopTest() {
    _timer?.cancel();
    setState(() {
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme for consistent styling

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface, // Use theme color
        elevation: 1,
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.bolt, color: theme.colorScheme.primary, size: 20), // Use theme color, smaller icon
            const SizedBox(width: 10),
            Text('Parallel API Test', style: theme.textTheme.titleMedium?.copyWith(fontSize: 18)), // Use theme text style, smaller
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface), // Use theme color
      ),
      body: SingleChildScrollView( // Ensures the whole page scrolls if content overflows
        child: Padding(
          padding: const EdgeInsets.all(12.0), // Reduced overall padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // Align columns to the top
            children: [
              // Left Column: Input Controls
              Expanded(
                flex: 2, // Give more space to controls initially, adjust as needed
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Slightly smaller radius
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0), // Reduced padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, // Make children take full width
                      children: [
                        Text('API Configuration', style: theme.textTheme.titleMedium?.copyWith(fontSize: 16)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _urlController,
                          style: _inputStyle,
                          decoration: InputDecoration(
                            labelText: 'API URL',
                            labelStyle: _labelStyle,
                            prefixIcon: const Icon(Icons.link, size: 18),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Adjust padding
                          ),
                        ),
                        const SizedBox(height: 10), // Reduced spacing
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedMethod,
                                style: _inputStyle,
                                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: _inputStyle))).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedMethod = val!;
                                    _showPayload = (val == 'POST' || val == 'PUT' || val == 'PATCH');
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Method',
                                  labelStyle: _labelStyle,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12), // Adjust padding
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _durationController,
                                style: _inputStyle,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Duration (s)',
                                  labelStyle: _labelStyle,
                                  prefixIcon: const Icon(Icons.timer, size: 18),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _rpsController,
                                style: _inputStyle,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'RPS',
                                  labelStyle: _labelStyle,
                                  prefixIcon: const Icon(Icons.speed, size: 18),
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                ),
                              ),
                            ),
                            if (_showPayload) ...[
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _payloadController,
                                  style: _inputStyle,
                                  maxLines: 1, // Keep it concise for this layout
                                  decoration: InputDecoration(
                                    labelText: 'Payload (JSON)',
                                    labelStyle: _labelStyle,
                                    prefixIcon: const Icon(Icons.data_object, size: 18),
                                    border: const OutlineInputBorder(),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                  ),
                                ),
                              ),
                            ] else Expanded(child: Container()), // Keep row balance if payload not shown
                          ],
                        ),
                        const SizedBox(height: 16), // Reduced spacing
                        ElevatedButton.icon(
                          icon: FaIcon(_isTesting ? FontAwesomeIcons.stop : FontAwesomeIcons.play, size: 14), // Smaller icon
                          label: Text(_isTesting ? 'Stop Test' : 'Start Test', style: _buttonTextStyle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTesting ? theme.colorScheme.error : theme.colorScheme.primary,
                            foregroundColor: _isTesting ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                            textStyle: _buttonTextStyle,
                          ),
                          onPressed: _isTesting ? _stopTest : _startTest,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12), // Spacing between columns

              // Right Column: Live Dashboard
              Expanded(
                flex: 3, // Give more space to dashboard
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Live Dashboard', style: _dashboardTitleStyle.copyWith(color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Total', _totalRequests, theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        _buildStatCard('Success', _successCount, Colors.green),
                        const SizedBox(width: 8),
                        _buildStatCard('Fail', _failCount, theme.colorScheme.error),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Graphs section - Removed Expanded wrapper from _buildChartCard
                    _buildChartCard(context, "Response Time Histogram", _buildHistogram(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to wrap charts in a styled Card with a title
  Widget _buildChartCard(BuildContext context, String title, Widget chartWidget) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Reduced padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min, // Ensure this Column shrink-wraps its content
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: 13, fontWeight: FontWeight.bold)), // Smaller title
            const SizedBox(height: 8),
            // Removed Expanded, wrapped chartWidget in a SizedBox with a fixed height
            SizedBox(
              height: 300, // Define a fixed height for the chart area
              child: chartWidget
            ),
          ],
        ),
      ),
    );
  }
}
