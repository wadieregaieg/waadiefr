import 'package:freshk/providers/order_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/widgets/modern_order_card.dart';
import 'package:freshk/widgets/order_filter_chip.dart';
import 'package:freshk/widgets/modern_loading_animation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/models/order_status.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  OrderStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Fetch orders when screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<OrderProvider>(context, listen: false);
      provider.fetchOrders(showLoading: true, context: context);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    // Only load more if we have next page and are not already loading
    if (provider.hasNext &&
        !provider.isLoadingMore &&
        provider.shouldLoadMore(_scrollController)) {
      provider.loadMoreOrders(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
          return _buildLoadingState();
        }

        final orders = orderProvider.orders;
        return orders.isEmpty
            ? _buildEmptyState()
            : _buildOrderList(orderProvider);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: ModernLoadingAnimation(
          message: AppLocalizations.of(context)!.loadingYourOrders,
          size: 80,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Modern empty state illustration
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(60),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 60,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context)!.noHistoryAvailable,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.startShopping,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Call to action button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to home or products
                      Navigator.of(context).pushNamed('/main');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.shopping_basket_outlined),
                    label: Text(
                      AppLocalizations.of(context)!.startShopping,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderList(OrderProvider orderProvider) {
    final filteredOrders = _getFilteredOrders(orderProvider.orders);

    return Column(
      children: [
        const SizedBox(height: 16), // Filter chips
        OrderFilterChip(
          selectedStatus: _selectedStatus,
          onStatusChanged: (status) {
            setState(() {
              _selectedStatus = status;
            });
          },
          isLoading: orderProvider.isLoading,
        ),

        const SizedBox(height: 8),

        // Order list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await orderProvider.fetchOrders();
            },
            color: AppColors.primary,
            backgroundColor: Colors.white,
            child: filteredOrders.isEmpty && !orderProvider.isLoading
                ? _buildNoResultsState()
                : ListView.builder(
                    controller: _scrollController,
                    physics: orderProvider.hasNext
                        ? const AlwaysScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredOrders.length +
                        (orderProvider.hasNext && orderProvider.isLoadingMore
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredOrders.length) {
                        return _buildLoadingMoreIndicator();
                      }

                      final order = filteredOrders[index];
                      return AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: ModernOrderCard(
                                  order: order,
                                  onTap: () {
                                    Navigator.pushNamed(
                                        context, AppRoutes.orderDetails,
                                        arguments: order);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(OrderProvider orderProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.orderHistory,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.trackYourPastOrders,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ],
          ),
          if (orderProvider.totalCount > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.showingOrdersCountNoFilter(
                        orderProvider.orders.length,
                        orderProvider.totalCount,
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ModernLoadingDots(
          message: AppLocalizations.of(context)!.loadingMoreOrders,
        ),
      ),
    );
  }

  List<dynamic> _getFilteredOrders(List<dynamic> orders) {
    return orders.where((order) {
      // Filter by status
      if (_selectedStatus != null && order.status != _selectedStatus) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final orderId = order.id.toString().toLowerCase();
        final status = order.status.name.toLowerCase();

        return orderId.contains(query) || status.contains(query);
      }

      return true;
    }).toList();
  }

  Widget _buildNoResultsState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noOrdersFound,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.tryAdjustingSearchFilter,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
