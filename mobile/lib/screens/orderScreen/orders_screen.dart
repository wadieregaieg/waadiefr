import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    if (provider.shouldLoadMore(_scrollController)) {
      provider.loadMoreOrders(context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.orders),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading && orderProvider.orders.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    //TODO FIX THIS
                    'Error: ${orderProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => orderProvider.fetchOrders(),
                    child: Text(
                      context.loc.retry,
                    ),
                  ),
                ],
              ),
            );
          }

          final allOrders = orderProvider.orders;

          return allOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        context.loc.noOrdersFound,
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Simplified info for endless scroll
                    if (orderProvider.totalCount > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          context.loc.showingAllOrdersCount(
                              allOrders.length, orderProvider.totalCount),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => orderProvider.fetchOrders(),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: allOrders.length +
                              (orderProvider.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == allOrders.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final order = allOrders[index];
                            return _buildOrderCard(context, order);
                          },
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Consumer<UserProvider>(
        builder: (context, value, child) {
          return ListTile(
            leading: const CircleAvatar(
              backgroundImage: AssetImage('assets/profile_placeholder.png'),
            ),
            title: Text(
                context.loc.customerLabel(value.currentUser?.username ?? '')),
            subtitle: Text(
                context.loc.phoneLabel(value.currentUser?.phoneNumber ?? '')),
            trailing: Text(order.status.name),
            onTap: () {
              // Navigate to detail or GPN matched screen
            },
          );
        },
      ),
    );
  }
}
