import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../constants.dart';
import '../../../models/order.dart';
import '../../../models/order_status.dart';
import '../../../extensions/localized_context.dart';

class ActionButtons extends StatelessWidget {
  final Order order;
  final double scale;
  final VoidCallback onCancel;
  final VoidCallback onReorder;
  final bool isReordering;

  const ActionButtons({
    Key? key,
    required this.order,
    required this.scale,
    required this.onCancel,
    required this.onReorder,
    this.isReordering = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Only show cancel button for pending or processing orders
    final bool canCancel = order.status == OrderStatus.pending;

    return Container(
      margin:
          EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 12 * scale),
      child: Column(
        children: [
          // Main action buttons
          Row(
            children: [
              // Cancel Order Button (only shown for eligible orders)
              if (canCancel) ...[
                Expanded(
                  child: _buildCancelButton(context),
                ),
                SizedBox(width: 12 * scale),
              ],

              // Reorder Button
              Expanded(
                child: _buildReorderButton(context),
              ),
            ],
          ),

          // Additional info for reorder button when disabled
          if (isReordering) ...[
            SizedBox(height: 8 * scale),
            Text(
              context.loc.processing,
              style: TextStyle(
                fontSize: 12 * scale,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCancelButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.red.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onCancel,
        icon: FaIcon(
          FontAwesomeIcons.xmark,
          color: Colors.white,
          size: 18 * scale,
        ),
        label: _buildAdaptiveText(
          context.loc.cancelOrder,
          context,
          maxLines: 2,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 8 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildReorderButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: isReordering ? null : onReorder,
        icon: isReordering
            ? SizedBox(
                width: 20 * scale,
                height: 20 * scale,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : FaIcon(
                FontAwesomeIcons.rotateRight,
                color: Colors.white,
                size: 18 * scale,
              ),
        label: _buildAdaptiveText(
          context.loc.reorder,
          context,
          maxLines: 2,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: 16 * scale,
            horizontal: 8 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildAdaptiveText(String text, BuildContext context,
      {int maxLines = 1}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate adaptive font size based on text length and available width
        double baseFontSize = 14 * scale;
        double adaptiveFontSize = baseFontSize;

        // Reduce font size for longer text
        if (text.length > 15) {
          adaptiveFontSize = baseFontSize * 0.85;
        }
        if (text.length > 25) {
          adaptiveFontSize = baseFontSize * 0.75;
        }

        // Further reduce if width is constrained
        if (constraints.maxWidth < 120 * scale) {
          adaptiveFontSize *= 0.9;
        }

        return Text(
          text,
          style: TextStyle(
            fontSize: adaptiveFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            height: 1.2,
          ),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        );
      },
    );
  }
}
