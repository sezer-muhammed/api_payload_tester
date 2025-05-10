import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'parallel_api_test_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0A3D91), // Darker seed color
      brightness: Brightness.dark, // Dark theme
      primary: const Color(0xFF1E88E5), // Vibrant blue for primary
      secondary: const Color(0xFF00ACC1), // Teal for secondary
      background: const Color(0xFF121212), // Dark background
      surface: const Color(0xFF1E1E1E), // Slightly lighter dark surface
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onBackground: Colors.white,
      onSurface: Colors.white,
      error: const Color(0xFFCF6679), // Material dark theme error color
      onError: Colors.black,
    );
    return MaterialApp(
      title: 'API Load Tester',
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: colorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface, // AppBar with surface color
          foregroundColor: colorScheme.onSurface, // Text on surface
          elevation: 6, // Increased elevation
          iconTheme: IconThemeData(color: colorScheme.onSurface),
          shadowColor: Colors.black.withOpacity(0.7), // Darker shadow
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        cardTheme: CardTheme( // Define CardTheme for consistent card styling
          elevation: 8,
          color: colorScheme.surface,
          shadowColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colorScheme.onSurface.withOpacity(0.2), width: 1),
          ),
        ),
        textTheme: TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: colorScheme.onSurface),
          titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.onSurface),
          bodyMedium: TextStyle(color: colorScheme.onSurface.withOpacity(0.85)),
          labelSmall: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)), // For attribution text
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'API Load Tester'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final horizontalMargin = screenWidth * 0.10;
    final verticalMargin = screenHeight * 0.05; // 5% vertical margin

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.bolt, color: Theme.of(context).colorScheme.onSurface, size: 32),
            const SizedBox(width: 12),
            Text('API Load Tester'),
          ],
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.bell, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            onPressed: () {},
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.userCircle, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            onPressed: () {},
          ),
        ],
        // elevation and shadowColor are now part of appBarTheme
      ),
      body: Stack( // Use Stack to overlay attribution text
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalMargin, 
              vertical: verticalMargin // Apply vertical margin
            ), 
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              itemCount: _cardData.length,
              itemBuilder: (context, index) {
                final card = _cardData[index];
                return _buildAppCard(
                  context,
                  icon: card['icon'],
                  iconColor: card['iconColor'],
                  title: card['title'],
                  description: card['description'],
                  onTap: card['onTap'],
                );
              },
            ),
          ),
          Align( // Align attribution text to bottom right
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Developed by IM Sezer & Şevval Dikkaya',
                style: Theme.of(context).textTheme.labelSmall, // Use themed text style
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _cardData => [
        {
          'icon': FontAwesomeIcons.bolt,
          'iconColor': const Color(0xFF2563eb),
          'title': 'Parallel API Test',
          'description': 'Run parallel load tests on your API.',
          'onTap': () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ParallelApiTestPage(),
              ),
            );
          },
        },
        {
          'icon': FontAwesomeIcons.cogs,
          'iconColor': const Color(0xFF6366f1),
          'title': 'Coming Soon',
          'description': 'More tools will be added.',
          'onTap': () {},
        },
        {
          'icon': FontAwesomeIcons.chartBar,
          'iconColor': const Color(0xFF10b981),
          'title': 'Coming Soon',
          'description': 'More analytics features.',
          'onTap': () {},
        },
        {
          'icon': FontAwesomeIcons.slidersH,
          'iconColor': const Color(0xFFf59e42),
          'title': 'Coming Soon',
          'description': 'Settings and configuration.',
          'onTap': () {},
        },
      ];

  Widget _buildAppCard(BuildContext context, {required IconData icon, required Color iconColor, required String title, required String description, required VoidCallback onTap}) {
    // Card styling is now primarily handled by CardTheme
    return Card(
      // elevation, color, shadowColor, shape are inherited from CardTheme
      // We can still override specific properties if needed, e.g., a unique shadow for this card type
      // shadowColor: iconColor.withOpacity(0.6), // Example of specific override
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Adjusted padding for new layout
          child: Row( // Use Row for side-by-side layout
            children: [
              // Icon on the left
              Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(20), // Increased padding for larger icon background
                child: FaIcon(icon, size: 40, color: iconColor), // Increased icon size
              ),
              const SizedBox(width: 16), // Spacing between icon and text
              // Title and Description on the right
              Expanded( // Use Expanded to allow text to take available space and wrap
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                  mainAxisSize: MainAxisSize.min, // Column takes minimum vertical space
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      description, 
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      // textAlign: TextAlign.start, // Ensure description text also aligns left if needed
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
