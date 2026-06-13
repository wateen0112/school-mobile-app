import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LoadingShimmer extends StatefulWidget {
  const LoadingShimmer({super.key, this.rows = 6});

  final int rows;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Column(
          children: List.generate(widget.rows, (index) {
            return Container(
              height: 76,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment(-1 + _controller.value * 2, 0),
                  end: Alignment(1 + _controller.value * 2, 0),
                  colors: const [
                    AppTheme.cloud,
                    Colors.white,
                    Color(0xfffff3ed),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
