import 'package:flutter/material.dart';
import 'package:freshk/constants.dart';

class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final bool isLoading;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final Function(int)? onPageSelected;
  final VoidCallback? onLoadMore;
  final bool showLoadMore;
  final String? loadMoreText;

  const PaginationWidget({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    this.isLoading = false,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelected,
    this.onLoadMore,
    this.showLoadMore = false,
    this.loadMoreText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1 && !showLoadMore) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLoadMore && hasNext) ...[
            _buildLoadMoreSection(),
            if (totalPages > 1) const SizedBox(height: 16),
          ],
          if (totalPages > 1) _buildPaginationControls(context),
        ],
      ),
    );
  }

  Widget _buildLoadMoreSection() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onLoadMore,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                loadMoreText ?? 'Load More',
                style: const TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Previous button
        _buildPaginationButton(
          icon: Icons.arrow_back_ios,
          label: 'Previous',
          onPressed: hasPrevious && !isLoading ? onPreviousPage : null,
        ),

        // Page numbers
        Expanded(
          child: _buildPageNumbers(context),
        ),

        // Next button
        _buildPaginationButton(
          icon: Icons.arrow_forward_ios,
          label: 'Next',
          onPressed: hasNext && !isLoading ? onNextPage : null,
          isNext: true,
        ),
      ],
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isNext = false,
  }) {
    return SizedBox(
      width: 80,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: onPressed != null ? AppColors.primary : Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isNext) Icon(icon, size: 16),
            if (!isNext) const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isNext) const SizedBox(width: 4),
            if (isNext) Icon(icon, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNumbers(BuildContext context) {
    final List<Widget> pageWidgets = [];

    // Calculate which pages to show
    int startPage = 1;
    int endPage = totalPages;

    if (totalPages > 5) {
      if (currentPage <= 3) {
        endPage = 5;
      } else if (currentPage >= totalPages - 2) {
        startPage = totalPages - 4;
      } else {
        startPage = currentPage - 2;
        endPage = currentPage + 2;
      }
    }

    // Add first page and ellipsis if needed
    if (startPage > 1) {
      pageWidgets.add(_buildPageButton(1));
      if (startPage > 2) {
        pageWidgets.add(_buildEllipsis());
      }
    }

    // Add page numbers
    for (int i = startPage; i <= endPage; i++) {
      pageWidgets.add(_buildPageButton(i));
    }

    // Add ellipsis and last page if needed
    if (endPage < totalPages) {
      if (endPage < totalPages - 1) {
        pageWidgets.add(_buildEllipsis());
      }
      pageWidgets.add(_buildPageButton(totalPages));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: pageWidgets,
    );
  }

  Widget _buildPageButton(int page) {
    final isCurrentPage = page == currentPage;

    return GestureDetector(
      onTap:
          isLoading || isCurrentPage ? null : () => onPageSelected?.call(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isCurrentPage ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isCurrentPage ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          page.toString(),
          style: TextStyle(
            color: isCurrentPage ? Colors.white : Colors.black87,
            fontWeight: isCurrentPage ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: const Text(
        '...',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}

class PaginationInfo extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int itemsPerPage;
  final int currentItemsCount;

  const PaginationInfo({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.itemsPerPage,
    required this.currentItemsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final endItem = startItem + currentItemsCount - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $startItem-$endItem of $totalCount',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            'Page $currentPage of $totalPages',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
