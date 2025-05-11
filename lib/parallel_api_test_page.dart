import 'dart:ui'; // Required for ImageFilter

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class ParallelApiTestPage extends StatefulWidget {
  const ParallelApiTestPage({super.key});

  @override
  State<ParallelApiTestPage> createState() => _ParallelApiTestPageState();
}

class _ParallelApiTestPageState extends State<ParallelApiTestPage> {
  // Define smaller text styles
  final TextStyle _labelStyle = const TextStyle(fontSize: 13, fontWeight: FontWeight.w500); // Adjusted for clarity
  final TextStyle _inputStyle = const TextStyle(fontSize: 14);
  final TextStyle _buttonTextStyle = const TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
  final TextStyle _statsTitleStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
  final TextStyle _statsValueStyle = const TextStyle(fontSize: 22, fontWeight: FontWeight.bold); // Made value larger
  final TextStyle _chartAxisLabelStyle = const TextStyle(fontSize: 10); // Adjusted for clarity
  final TextStyle _dashboardTitleStyle = const TextStyle(fontSize: 20, fontWeight: FontWeight.bold); // Made title larger


  Widget _buildHistogram(BuildContext context) {
    // Ensure there are values before trying to reduce or build the chart
    if (_allResponseTimes.isEmpty) {
      return Center(child: Text('No data yet for histogram', style: _labelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))));
    }
    
    final bins = 10;
    // It's safer to check again, though the top check should cover this.
    if (_allResponseTimes.isEmpty) return Center(child: Text('Not enough data for histogram', style: _labelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))));
    
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
            sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) { // Increased reservedSize
              return Text(value.toInt().toString(), style: _chartAxisLabelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
            }),
            axisNameWidget: Text("Frequency", style: _chartAxisLabelStyle.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 11)),
            axisNameSize: 22,
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
                    return Text('${binStart.toInt()}-${binEnd.toInt()}', style: _chartAxisLabelStyle.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)));
                }
                return const SizedBox();
              },
              reservedSize: 32, // Increased reservedSize 
            ),
            axisNameWidget: Text("Response Time (ms)", style: _chartAxisLabelStyle.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface, fontSize: 11)),
            axisNameSize: 22,
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3), width: 1.5)), // Thicker border
        barGroups: [
          for (int i = 0; i < bins; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: counts[i].toDouble(), 
                color: Theme.of(context).colorScheme.primary.withOpacity(0.85), // Slightly transparent bars
                width: 20, // Wider bars
                borderRadius: const BorderRadius.all(Radius.circular(6)) // Rounded bars
              )
            ])
        ],
        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15), strokeWidth: 1)), // More visible grid
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
  final List<double> _allResponseTimes = [];
  final List<int> _requestsPerSecond = [];
  final List<double> _successRate = [];
  int _totalRequests = 0;
  int _successCount = 0;
  int _failCount = 0;
  Timer? _timer;
  int _elapsed = 0;

  Widget _buildStatCard(String title, int value, Color color) {
    return Expanded( 
      child: ClipRRect( // Clip for glassmorphism
        borderRadius: BorderRadius.circular(18), // Consistent rounded corners
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Subtle blur for stat cards
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // More pronounced radius
            elevation: 0, // Glassmorphism handles depth
            color: Theme.of(context).colorScheme.surface.withOpacity(0.6), // Semi-transparent
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0), // Adjusted padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: _statsTitleStyle.copyWith(color: color, fontSize: 15), // Adjusted font size
                  ),
                  const SizedBox(height: 8), // Consistent spacing
                  Text(
                    value.toString(),
                    style: _statsValueStyle.copyWith(color: Theme.of(context).colorScheme.onSurface, fontSize: 24), // Adjusted font size
                  ),
                ],
              ),
            ),
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
    final theme = Theme.of(context); 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withOpacity(0.5), // Semi-transparent for glassmorphism
        elevation: 0, // Flat for modern look
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.boltLightning, color: theme.colorScheme.primary, size: 22), // Updated icon, theme color
            const SizedBox(width: 12),
            Text('Parallel API Test', style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)), // Bolder title
          ],
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface), 
      ),
      body: SingleChildScrollView( 
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Consistent padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              // Left Column: Input Controls
              Expanded(
                flex: 2, 
                child: ClipRRect( // Clip for glassmorphism
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Match theme
                      elevation: 0, // Glassmorphism handles depth
                      color: theme.colorScheme.surface.withOpacity(0.65), // Semi-transparent
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), // Consistent padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch, 
                          children: [
                            Text('API Configuration', style: theme.textTheme.titleLarge?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _urlController,
                              style: _inputStyle,
                              decoration: InputDecoration(
                                labelText: 'API URL',
                                labelStyle: _labelStyle,
                                prefixIcon: const Icon(Icons.link, size: 20),
                                // Border and contentPadding inherited from theme
                              ),
                            ),
                            const SizedBox(height: 12), 
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
                                      // Border and contentPadding inherited from theme
                                    ),
                                    dropdownColor: theme.colorScheme.surface.withOpacity(0.9), // Glassy dropdown
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _durationController,
                                    style: _inputStyle,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Duration (s)',
                                      labelStyle: _labelStyle,
                                      prefixIcon: const Icon(Icons.timer_outlined, size: 20), // Outlined icon
                                      // Border and contentPadding inherited from theme
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
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
                                      prefixIcon: const Icon(Icons.speed_outlined, size: 20), // Outlined icon
                                      // Border and contentPadding inherited from theme
                                    ),
                                  ),
                                ),
                                if (_showPayload) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _payloadController,
                                      style: _inputStyle,
                                      maxLines: 1, 
                                      decoration: InputDecoration(
                                        labelText: 'Payload (JSON)',
                                        labelStyle: _labelStyle,
                                        prefixIcon: const Icon(Icons.data_object_outlined, size: 20), // Outlined icon
                                        // Border and contentPadding inherited from theme
                                      ),
                                    ),
                                  ),
                                ] else Expanded(child: Container()), 
                              ],
                            ),
                            const SizedBox(height: 20), 
                            ElevatedButton.icon(
                              icon: FaIcon(_isTesting ? FontAwesomeIcons.stopCircle : FontAwesomeIcons.playCircle, size: 18), // Updated icons
                              label: Text(_isTesting ? 'Stop Test' : 'Start Test', style: _buttonTextStyle),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTesting ? theme.colorScheme.error.withOpacity(0.85) : theme.colorScheme.primary.withOpacity(0.85),
                                foregroundColor: _isTesting ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24), // Adjusted padding
                                // Shape inherited from theme
                              ),
                              onPressed: _isTesting ? _stopTest : _startTest,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16), // Spacing between columns

              // Right Column: Live Dashboard
              Expanded(
                flex: 3, 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Live Dashboard', style: _dashboardTitleStyle.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Total', _totalRequests, theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        _buildStatCard('Success', _successCount, Colors.green.shade400), // Brighter green
                        const SizedBox(width: 12),
                        _buildStatCard('Fail', _failCount, theme.colorScheme.error),
                      ],
                    ),
                    const SizedBox(height: 16),
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
    return ClipRRect( // Clip for glassmorphism
      borderRadius: BorderRadius.circular(18), // Consistent rounded corners
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8), // Blur for chart card background
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), // More pronounced radius
          elevation: 0, // Glassmorphism handles depth
          color: Theme.of(context).colorScheme.surface.withOpacity(0.6), // Semi-transparent
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Adjusted padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min, 
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.bold)), // Adjusted title
                const SizedBox(height: 12),
                SizedBox(
                  height: 280, // Adjusted height for better proportion
                  child: chartWidget
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
