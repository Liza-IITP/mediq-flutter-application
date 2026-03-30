import 'package:flutter/material.dart';

/// Constrains UI to a max width of 850 px so the app looks great
/// on both mobile and wide desktop / web viewports.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  const ResponsiveContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: child,
        ),
      ),
    );
  }
}
