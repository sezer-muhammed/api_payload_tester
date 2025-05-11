import 'dart:ui'; // Required for ImageFilter

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
      surface: const Color(0xFF1E1E1E).withOpacity(0.85), // Slightly lighter dark surface with opacity for glassmorphism
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
        scaffoldBackgroundColor: colorScheme.background, // Use background for scaffold
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.surface.withOpacity(0.5), // AppBar with semi-transparent surface
          foregroundColor: colorScheme.onSurface, // Text on surface
          elevation: 0, // Remove elevation for a flatter, modern look with glassmorphism
          iconTheme: IconThemeData(color: colorScheme.onSurface),
          shadowColor: Colors.black.withOpacity(0.7), // Darker shadow
          titleTextStyle: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        cardTheme: CardTheme( // Define CardTheme for consistent card styling
          elevation: 0, // Remove elevation, rely on blur and border for depth
          color: colorScheme.surface.withOpacity(0.65), // Semi-transparent card color
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // More pronounced rounded corners
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18), // Rounded buttons
            ),
            elevation: 5, // Subtle elevation for buttons
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Rounded input fields
            borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surface.withOpacity(0.5), // Semi-transparent fill for inputs
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    final horizontalMargin = screenWidth * 0.08; // Adjusted margin
    final verticalMargin = screenHeight * 0.05;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            FaIcon(FontAwesomeIcons.bolt, color: Theme.of(context).colorScheme.primary, size: 32), // Use primary color for icon
            const SizedBox(width: 12),
            Text('API Load Tester'),
          ],
        ),
        actions: [
          IconButton(
            icon: FaIcon(FontAwesomeIcons.bell, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            onPressed: () {
              // TODO: Implement notification functionality
            },
          ),
          IconButton(
            icon: FaIcon(FontAwesomeIcons.userCircle, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
            onPressed: () {
              // TODO: Implement user profile functionality
            },
          ),
        ],
      ),
      body: Stack( 
        children: [
          // Optional: Add a subtle background pattern or gradient if desired
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //       colors: [
          //         Theme.of(context).colorScheme.background,
          //         Theme.of(context).colorScheme.surface.withOpacity(0.1),
          //       ],
          //     ),
          //   ),
          // ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalMargin, 
              vertical: verticalMargin
            ), 
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 20, // Increased spacing
              crossAxisSpacing: 20, // Increased spacing
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
    return ClipRRect( // Clip for glassmorphism effect
      borderRadius: BorderRadius.circular(24), // Match CardTheme
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Card(
          // elevation, color, shadowColor, shape are inherited from CardTheme
          child: InkWell(
            borderRadius: BorderRadius.circular(24), // Match CardTheme
            onTap: onTap,
            hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            child: Padding(
              padding: const EdgeInsets.all(20.0), // Adjusted padding
              child: Row( 
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2), // Slightly more vibrant icon background
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(20), 
                    child: FaIcon(icon, size: 36, color: iconColor), // Slightly smaller icon for balance
                  ),
                  const SizedBox(width: 20), 
                  Expanded( 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      mainAxisSize: MainAxisSize.min, 
                      children: [
                        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          description, 
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
