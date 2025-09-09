import 'package:freshk/models/apiResponses/checkout_response.dart';
import 'package:flutter/material.dart';
import '../constants.dart';
import '../routes.dart';
import '../extensions/localized_context.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final CheckoutResponse order;

  const PaymentSuccessScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/successfully_created.png', width: 150),
                const SizedBox(height: 30),
                Text(
                  context.loc.congratulations,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                Text(
                  context.loc.orderReceivedMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                _buildDetailTable(context, order),
                const SizedBox(height: 30),
                // Action buttons
                // Navigate to track order
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.main,
                        arguments: 1), // Navigate to Orders tab
                    child: Text(context.loc.trackOrderButton),
                  ),
                ),
                // Back to home button
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.main,
                    (route) => false,
                  ),
                  child: Text(
                    context.loc.backToHome,
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTable(BuildContext context, CheckoutResponse order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[100],
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
        },
        children: [
          _buildTableRow(context.loc.orderNumber, order.id.toString()),
          _buildTableRow(
            context.loc.orderDate,
            DateTime.parse(order.orderDate)
                .toLocal()
                .toString()
                .split(' ')[0]
                .split('-')
                .reversed
                .join('/'),
          ),
          _buildTableRow(context.loc.totalAmount,
              "${double.parse((order.formattedTotal).split(" ")[0]).toStringAsFixed(2)} TND"),
          _buildTableRow(context.loc.status, order.statusDisplay),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value),
        ),
      ],
    );
  }
}
