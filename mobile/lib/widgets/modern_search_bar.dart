import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';

class ModernSearchBar extends StatefulWidget {
  final String? hintText;
  final Function(String) onSearchChanged;
  final VoidCallback? onClear;
  final bool isLoading;

  const ModernSearchBar({
    super.key,
    this.hintText,
    required this.onSearchChanged,
    this.onClear,
    this.isLoading = false,
  });

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onSearchChanged(value);
  }

  void _onClear() {
    _controller.clear();
    widget.onSearchChanged('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isFocused 
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: _isFocused ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _isFocused ? AppColors.primary : Colors.grey[200]!,
                width: _isFocused ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: _isFocused ? AppColors.primary : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onChanged,
                      enabled: !widget.isLoading,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hintText ?? 'Search orders...',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_controller.text.isNotEmpty)
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: GestureDetector(
                        onTap: _onClear,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  if (widget.isLoading) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 