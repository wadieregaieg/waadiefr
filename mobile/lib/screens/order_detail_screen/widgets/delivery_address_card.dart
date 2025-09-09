import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants.dart';
import '../../../models/order.dart';
import '../../../extensions/localized_context.dart';
import 'package:freshk/utils/freshk_utils.dart';

class DeliveryAddressCard extends StatelessWidget {
  final Order order;
  final double scale;

  const DeliveryAddressCard({
    Key? key,
    required this.order,
    required this.scale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Prefer deliveryAddress over shippingAddress
    final String? address = order.deliveryAddress ?? order.shippingAddress;
    final bool hasAddress = address != null && address.isNotEmpty;

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
            _buildAddressHeader(context, hasAddress),
            SizedBox(height: 12 * scale),
            if (hasAddress) ...[
              _buildAddressContent(context, address),
              SizedBox(height: 12 * scale),
              _buildAddressInfo(context),
            ] else ...[
              _buildNoAddressContent(context),
              SizedBox(height: 12 * scale),
              _buildNoAddressWarning(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddressHeader(BuildContext context, bool hasAddress) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8 * scale),
          decoration: BoxDecoration(
            color: hasAddress
                ? AppColors.primaryLight
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8 * scale),
          ),
          child: Icon(
            hasAddress ? Icons.location_on : Icons.location_off,
            color: hasAddress ? AppColors.primary : Colors.orange,
            size: 20 * scale,
          ),
        ),
        SizedBox(width: 12 * scale),
        Expanded(
          child: Text(
            context.loc.deliveryAddress,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        if (hasAddress)
          GestureDetector(
            onTap: () => _copyAddressToClipboard(context),
            child: Icon(
              Icons.content_copy,
              size: 16 * scale,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildAddressContent(BuildContext context, String address) {
    return Text(
      address,
      style: TextStyle(
        fontSize: 14 * scale,
        color: Colors.grey[700],
        height: 1.4,
      ),
    );
  }

  Widget _buildAddressInfo(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 14 * scale,
          color: Colors.blue,
        ),
        SizedBox(width: 6 * scale),
        Text(
          context.loc.deliveryWillBeMadeToThisAddress, // TODO: Add to loc alization
          style: TextStyle(
            fontSize: 12 * scale,
            color: Colors.blue[700],
          ),
        ),
      ],
    );
  }

  Widget _buildNoAddressContent(BuildContext context) {
    return Text(
      context.loc.noAddressProvided,
      style: TextStyle(
        fontSize: 14 * scale,
        color: Colors.grey[700],
        fontStyle: FontStyle.italic,
        height: 1.4,
      ),
    );
  }

  Widget _buildNoAddressWarning(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.warning_outlined,
          size: 14 * scale,
          color: Colors.orange,
        ),
        SizedBox(width: 6 * scale),
        Expanded(
          child: Text(
            context.loc.addressInfoNotAvailable, // TODO: Add to localization
            style: TextStyle(
              fontSize: 12 * scale,
              color: Colors.orange[700],
            ),
          ),
        ),
      ],
    );
  }

  void _copyAddressToClipboard(BuildContext context) {
    final String? address = order.deliveryAddress ?? order.shippingAddress;
    if (address != null) {
      Clipboard.setData(ClipboardData(text: address));
      FreshkUtils.showInfoSnackbar(context, context.loc.addressCopiedToClipboard);
    }
  }
}
