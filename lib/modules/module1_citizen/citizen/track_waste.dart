import 'package:flutter/material.dart';
// Layered imports
class TrackWasteScreen extends StatelessWidget {
  const TrackWasteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textColor = colorScheme.onSurface;
    final placeholderColor = colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track My Waste',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pin_drop_outlined, size: 80, color: primaryColor),
              const SizedBox(height: 20),
              Text(
                'Real-Time Tracking (IWMS)',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This screen will display the live location of the assigned collection vehicle using GPS tracking (D2D Collection & Logistics Management).',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: placeholderColor,
                ),
              ),
              const SizedBox(height: 30),
              // Placeholder for a map view
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
                ),
                child: Center(
                  child: Text(
                    'Loading Map...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: placeholderColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Updates will include estimated time of arrival (ETA) and route adherence alerts.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: placeholderColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
