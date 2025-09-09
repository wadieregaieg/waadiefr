import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../extensions/localized_context.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final double scale;

  const SectionTitle({
    Key? key,
    required this.title,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18 * scale,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  final List<Widget> children;

  const DetailCard({
    Key? key,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }
}

class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;
  final bool isCopied;

  const DetailRow({
    Key? key,
    required this.label,
    required this.value,
    this.onCopy,
    this.isCopied = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onCopy,
                  child: Icon(
                    Icons.content_copy,
                    size: 16,
                    color: isCopied ? AppColors.primary : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class NotesSection extends StatelessWidget {
  final String notes;
  final double scale;

  const NotesSection({
    Key? key,
    required this.notes,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.notes,
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              notes,
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 