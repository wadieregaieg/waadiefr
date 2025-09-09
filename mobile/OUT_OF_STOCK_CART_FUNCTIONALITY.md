# Out of Stock Cart Functionality

## Overview
This document describes the enhanced out-of-stock functionality implemented in the Freshk cart screen to provide users with clear visual indicators and appropriate actions when products are unavailable.

## Features Implemented

### 1. Visual Indicators for Out-of-Stock Items

#### Product Card Styling
- **Background Color**: Out-of-stock items have a light grey background (`Colors.grey.shade50`)
- **Border**: Red border (`Colors.red.shade200`) around out-of-stock items
- **Shadow**: Red-tinted shadow for out-of-stock items
- **Top Banner**: Red "OUT OF STOCK" banner at the top of each out-of-stock item

#### Product Image
- **Overlay**: Semi-transparent red overlay on product images
- **Block Icon**: Red block icon (`Icons.block`) centered on the image
- **Opacity**: 30% red overlay for clear visibility

#### Text Styling
- **Product Name**: Greyed out text for out-of-stock items
- **Price**: Lighter grey color for price display
- **Total Price**: Red color (`Colors.red.shade600`) for total price
- **Out of Stock Badge**: Small red badge next to total price

### 2. Quantity Controls

#### Disabled State
- **Add Button**: Disabled and greyed out for out-of-stock items
- **Remove Button**: Disabled and greyed out for out-of-stock items
- **Quantity Edit**: Disabled tap functionality for out-of-stock items
- **Visual Feedback**: All controls show grey colors when disabled

#### Stock Validation
- **Existing Logic**: Maintains existing stock validation for available items
- **Quantity Limits**: Prevents adding more than available stock
- **User Feedback**: Shows appropriate error messages for stock violations

### 3. Cart-Level Warnings

#### Warning Banner
- **Location**: Displayed above the cart items list
- **Color Scheme**: Orange background with orange border
- **Icon**: Warning icon (`Icons.warning_amber_rounded`)
- **Dynamic Messages**:
  - **Partial Out of Stock**: "Some items in your cart are out of stock. You can still checkout with available items."
  - **All Out of Stock**: "All items in your cart are currently out of stock. Please remove them or wait for restocking."

#### Checkout Button
- **State Management**: Disabled when all items are out of stock
- **Visual Changes**: Grey background when disabled
- **Text Changes**: Shows "Cannot Checkout" when disabled
- **Additional Info**: Shows "No items available for checkout" below total

## Technical Implementation

### 1. State Management

#### Out of Stock Detection
```dart
// Check if product is out of stock
bool get _isOutOfStock => widget.item.product.stockQuantity <= 0;

// Check if there are out-of-stock items in cart
bool get _hasOutOfStockItems => cart.items.any((item) => item.product.stockQuantity <= 0);

// Check if all items are out of stock
bool get _allItemsOutOfStock => cart.items.every((item) => item.product.stockQuantity <= 0);
```

#### Conditional Rendering
- Uses computed properties to determine UI state
- Implements conditional styling based on stock availability
- Maintains existing functionality for available items

### 2. UI Components Modified

#### ShoppingCartItem Widget
- **File**: `mobile/lib/screens/MainLayout/cartScreen/widget/shopping_cart_item.dart`
- **Changes**: Added out-of-stock styling, disabled controls, visual indicators

#### CartContent Widget
- **File**: `mobile/lib/screens/MainLayout/cartScreen/widget/cart_content.dart`
- **Changes**: Added warning banner, checkout button state management

### 3. Color Scheme

#### Primary Colors
- **Red Shades**: `Colors.red.shade50` to `Colors.red.shade700`
- **Orange Shades**: `Colors.orange.shade50` to `Colors.orange.shade700`
- **Grey Shades**: `Colors.grey.shade400` to `Colors.grey.shade600`

#### Usage Guidelines
- **Red**: Used for out-of-stock indicators and warnings
- **Orange**: Used for general cart warnings
- **Grey**: Used for disabled states and muted text

## User Experience Features

### 1. Clear Communication
- **Immediate Recognition**: Users can instantly identify out-of-stock items
- **Actionable Information**: Clear messages about what actions are available
- **Visual Hierarchy**: Important information stands out with appropriate colors

### 2. Graceful Degradation
- **Partial Functionality**: Users can still interact with available items
- **Checkout Options**: Checkout remains available when some items are in stock
- **Item Management**: Users can remove out-of-stock items or wait for restocking

### 3. Accessibility
- **Color Contrast**: High contrast between text and background colors
- **Icon Usage**: Meaningful icons to reinforce text messages
- **Touch Targets**: Maintains appropriate touch target sizes for all controls

## Future Enhancements

### 1. Stock Notifications
- **Restock Alerts**: Notify users when out-of-stock items become available
- **Waitlist Feature**: Allow users to join waitlist for popular items
- **Email Notifications**: Send restock notifications to interested users

### 2. Alternative Suggestions
- **Similar Products**: Suggest alternatives for out-of-stock items
- **Store Locations**: Show nearby stores with available stock
- **Delivery Options**: Offer different delivery timeframes

### 3. Inventory Management
- **Real-time Updates**: Live stock updates during cart session
- **Reserved Items**: Hold items briefly while user completes checkout
- **Stock Forecasting**: Show expected restock dates

## Testing Checklist

### 1. Visual Testing
- [ ] Out-of-stock items display red styling
- [ ] Warning banner appears when appropriate
- [ ] Checkout button changes state correctly
- [ ] All text remains readable with new color scheme

### 2. Functionality Testing
- [ ] Quantity controls are disabled for out-of-stock items
- [ ] Available items remain fully functional
- [ ] Checkout process works with mixed stock availability
- [ ] Error messages display correctly

### 3. Edge Cases
- [ ] Cart with only out-of-stock items
- [ ] Mixed cart with some available items
- [ ] Rapid stock changes during session
- [ ] Empty cart after removing all items

## Code Quality

### 1. Maintainability
- **Separation of Concerns**: UI logic separated from business logic
- **Reusable Components**: Warning banner and styling can be reused
- **Clear Naming**: Descriptive variable and method names

### 2. Performance
- **Efficient Rendering**: Uses computed properties to avoid unnecessary calculations
- **Conditional Building**: Only builds UI elements when needed
- **State Management**: Minimal state changes for smooth performance

### 3. Extensibility
- **Modular Design**: Easy to add new out-of-stock features
- **Configurable Styling**: Color schemes can be easily modified
- **Internationalization Ready**: Text can be localized in the future

## Conclusion

The out-of-stock functionality provides users with clear, actionable information about product availability while maintaining a smooth shopping experience. The implementation follows Flutter best practices and provides a foundation for future enhancements in inventory management and user communication. 