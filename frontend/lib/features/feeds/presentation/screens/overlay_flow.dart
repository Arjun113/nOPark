import 'package:flutter/material.dart';

class OverlayFlowController {
  final VoidCallback next;
  final VoidCallback back;
  final void Function(int index) jumpTo;

  OverlayFlowController({
    required this.next,
    required this.back,
    required this.jumpTo,
  });
}

class OverlayFlow extends StatefulWidget {
  final List<Widget> Function(OverlayFlowController) stepsBuilder;
  final VoidCallback onClose;
  final int startIndex;

  const OverlayFlow({
    super.key,
    required this.stepsBuilder,
    required this.onClose,
    this.startIndex = 0,
  });

  @override
  State<OverlayFlow> createState() => _OverlayFlowState();
}

class _OverlayFlowState extends State<OverlayFlow> {
  late final PageController _pageController;
  late final OverlayFlowController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.startIndex;
    _pageController = PageController(initialPage: widget.startIndex);
    _controller = OverlayFlowController(
      next: _next,
      back: _back,
      jumpTo: _jumpTo,
    );
  }

  void _next() {
    if (_currentPage < widget.stepsBuilder(_controller).length - 1) {
      setState(() => _currentPage++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _back() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onClose();
    }
  }

  void _jumpTo(int index) {
    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _onWillPop() async {
    if (_currentPage != 0) {
      _back();
      return false;
    }
    widget.onClose();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.stepsBuilder(_controller);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Material(
        color: Colors.transparent,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: steps,
        ),
      ),
    );
  }
}
