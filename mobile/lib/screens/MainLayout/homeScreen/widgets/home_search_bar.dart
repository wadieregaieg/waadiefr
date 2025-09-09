import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';

class HomeSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onClear;
  final ValueChanged<String> onSubmitted;
  final String hintText;
  final VoidCallback? onTap;
  final bool enabled;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.onClear,
    required this.onSubmitted,
    required this.hintText,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<HomeSearchBar> createState() => _HomeSearchBarState();
}

class _HomeSearchBarState extends State<HomeSearchBar>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Animation<Color?>? _borderColorAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });

    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final theme = Theme.of(context);
      _borderColorAnimation = ColorTween(
        begin: Colors.transparent,
        end: theme.primaryColor.withOpacity(0.3),
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
                if (_focusNode.hasFocus)
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              onTap: widget.onTap,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark 
                    ? Colors.grey.shade800 
                    : Colors.grey.shade50,
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search_rounded,
                    color: _focusNode.hasFocus 
                        ? theme.primaryColor 
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          key: ValueKey(widget.controller.text),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: theme.primaryColor,
                              size: 18,
                            ),
                            onPressed: () {
                              widget.onClear();
                              _focusNode.unfocus();
                            },
                            style: IconButton.styleFrom(
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      )
                    : null,
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: BorderSide(
                    color: _borderColorAnimation?.value ?? Colors.transparent,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: BorderSide(
                    color: Colors.transparent,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: BorderSide(
                    color: theme.primaryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
              ),
              onSubmitted: widget.onSubmitted,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              autocorrect: false,
              enableSuggestions: false,
            ),
          ),
        );
      },
    );
  }
}
