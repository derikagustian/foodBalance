import 'package:flutter/material.dart';

class EntranceFaded extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const EntranceFaded({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 0),
  });

  @override
  State<EntranceFaded> createState() => _EntranceFadedState();
}

class _EntranceFadedState extends State<EntranceFaded> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) setState(() => _isVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _isVisible ? 1.0 : 0.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isVisible ? 0 : 20, 0),
        child: widget.child,
      ),
    );
  }
}
