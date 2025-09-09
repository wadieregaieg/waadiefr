# API Error Handling Guide

## Overview

This guide explains the enhanced API error handling system implemented in the Freshk app, specifically designed to handle 500-series server errors gracefully and provide better user experience.

## Key Improvements

### 1. Enhanced Exception Types

The system now includes more specific exception types for better error categorization:

- **`TransientServerException`**: For temporary server issues (500, 502, 503, 504) that can be retried
- **`PersistentServerException`**: For persistent server issues that shouldn't be retried
- **`ServerException`**: Base class with retry logic support
- **`NetworkException`**: For network connectivity issues
- **`AuthenticationException`**: For authentication-related errors
- **`ValidationException`**: For input validation errors

### 2. Automatic Retry Logic

The system automatically retries transient server errors:

```dart
// Old way
return ExceptionHandler.execute(() async {
  // API call
});

// New way with retry logic
return ExceptionHandler.executeWithRetry(() async {
  // API call
}, onError: (exception) {
  // Custom error handling
});
```

### 3. Enhanced UI Feedback

Different error types now show appropriate UI feedback:

- **Transient errors**: Orange color with retry button
- **Persistent errors**: Red color with dismiss option
- **Network errors**: Blue color with connectivity suggestions

## Usage Examples

### 1. Service Layer Implementation

```dart
class ProductService {
  static Future<List<Product>> fetchProducts() async {
    return ExceptionHandler.executeWithRetry<List<Product>>(
      () async {
        final res = await DioInstance.dio.get("/api/products");
        return (res.data['results'] as List)
            .map((e) => Product.fromJson(e))
            .toList();
      },
      onError: (exception) {
        debugPrint("Product fetch failed: $exception");
        // Custom error handling if needed
      },
    );
  }
}
```

### 2. UI Layer Implementation

```dart
class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> products = [];
  Exception? error;

  Future<void> _loadProducts() async {
    try {
      products = await ProductService.fetchProducts();
      setState(() {
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e as Exception;
      });
      
      // Show appropriate error UI
      if (e is TransientServerException) {
        FreshkUtils.showServerErrorDialog(
          context,
          e.message,
          onRetry: _loadProducts,
        );
      } else if (e is PersistentServerException) {
        FreshkUtils.showServerErrorDialog(
          context,
          e.message,
          onDismiss: () => Navigator.pop(context),
        );
      } else if (e is NetworkException) {
        FreshkUtils.showNetworkErrorDialog(
          context,
          e.message,
          onRetry: _loadProducts,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorHandlingWidget(
        error: error!,
        onRetry: _loadProducts,
        onDismiss: () => Navigator.pop(context),
      );
    }
    
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ProductCard(product: products[index]),
    );
  }
}
```

### 3. Using Error Handling Widget

```dart
// For transient server errors
ErrorHandlingWidget(
  error: TransientServerException('Temporary server issue'),
  onRetry: () => _retryOperation(),
  showRetryButton: true,
)

// For persistent server errors
ErrorHandlingWidget(
  error: PersistentServerException('Server unavailable'),
  onDismiss: () => Navigator.pop(context),
  showRetryButton: false,
)

// For network errors
ErrorHandlingWidget(
  error: NetworkException('No internet connection'),
  onRetry: () => _retryOperation(),
  showRetryButton: true,
)
```

## Error Type Classification

### Transient Errors (Auto-retry enabled)
- **500 Internal Server Error**: Most 500 errors are considered transient
- **502 Bad Gateway**: Usually transient
- **503 Service Unavailable**: Usually transient
- **504 Gateway Timeout**: Usually transient

### Persistent Errors (No auto-retry)
- **500 Internal Server Error**: With specific error messages indicating permanent issues
- **Database connection failures**
- **Configuration errors**
- **Server configuration issues**

### Network Errors
- **Connection timeouts**
- **DNS resolution failures**
- **SSL certificate errors**
- **No internet connectivity**

## Configuration

### Retry Settings

The retry logic is configurable:

```dart
ExceptionHandler.executeWithRetry(
  () async { /* API call */ },
  maxRetries: 3,           // Default: 3
  retryDelay: Duration(seconds: 2), // Default: 2 seconds
  onError: (exception) { /* Custom handling */ },
);
```

### Localization

Error messages are automatically localized based on the app's language setting. New localization keys have been added:

- `serverTemporaryError`
- `serverDownMessage`
- `temporaryServerIssue`
- `serverUnavailable`
- `retrySuggestion`
- `checkConnectionSuggestion`

## Best Practices

### 1. Always Use Retry Logic for API Calls

```dart
// ✅ Good
return ExceptionHandler.executeWithRetry(() async {
  return await apiCall();
});

// ❌ Avoid
return ExceptionHandler.execute(() async {
  return await apiCall();
});
```

### 2. Handle Different Error Types Appropriately

```dart
try {
  await apiCall();
} catch (e) {
  if (e is TransientServerException) {
    // Show retry option
    FreshkUtils.showServerErrorDialog(context, e.message, onRetry: retry);
  } else if (e is PersistentServerException) {
    // Show dismiss option
    FreshkUtils.showServerErrorDialog(context, e.message, onDismiss: dismiss);
  } else if (e is NetworkException) {
    // Show network error dialog
    FreshkUtils.showNetworkErrorDialog(context, e.message, onRetry: retry);
  }
}
```

### 3. Use Error Handling Widget for Full-Screen Errors

```dart
if (error != null) {
  return ErrorHandlingWidget(
    error: error!,
    onRetry: _retryOperation,
    onDismiss: _dismissError,
  );
}
```

### 4. Log Errors for Debugging

```dart
onError: (exception) {
  debugPrint("API call failed: $exception");
  debugPrint("Error type: ${exception.runtimeType}");
  // Additional logging as needed
}
```

## Migration Guide

### From Old Error Handling

**Before:**
```dart
try {
  final result = await apiCall();
  return result;
} catch (e) {
  if (e is DioException) {
    if (e.response?.statusCode == 500) {
      throw ServerException('Server error');
    }
  }
  throw e;
}
```

**After:**
```dart
return ExceptionHandler.executeWithRetry(() async {
  return await apiCall();
}, onError: (exception) {
  debugPrint("API call failed: $exception");
});
```

### Benefits of New System

1. **Automatic retry**: Transient errors are automatically retried
2. **Better UX**: Different error types show appropriate UI
3. **Consistent handling**: Centralized error handling logic
4. **Localization**: Automatic message localization
5. **Debugging**: Better error logging and categorization

## Testing

### Testing Retry Logic

```dart
test('should retry transient server errors', () async {
  int callCount = 0;
  
  final result = await ExceptionHandler.executeWithRetry(() async {
    callCount++;
    if (callCount < 3) {
      throw TransientServerException('Temporary error');
    }
    return 'success';
  });
  
  expect(result, 'success');
  expect(callCount, 3);
});
```

### Testing Error UI

```dart
testWidgets('should show retry button for transient errors', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ErrorHandlingWidget(
        error: TransientServerException('Test error'),
        onRetry: () {},
      ),
    ),
  );
  
  expect(find.text('Retry'), findsOneWidget);
  expect(find.text('Temporary Server Issue'), findsOneWidget);
});
```

## Troubleshooting

### Common Issues

1. **Retry not working**: Ensure you're using `executeWithRetry` instead of `execute`
2. **Wrong error type**: Check that the exception is properly categorized
3. **UI not updating**: Ensure error state is properly managed in setState
4. **Localization missing**: Add missing keys to localization files

### Debug Tips

1. Enable debug logging to see retry attempts
2. Check error categorization in ExceptionHandler
3. Verify UI state management
4. Test with different network conditions

## Conclusion

The new error handling system provides:

- **Robust 500-series error handling**
- **Automatic retry for transient errors**
- **Better user experience with appropriate UI feedback**
- **Consistent error handling across the app**
- **Easy migration from existing code**

This system ensures that users have a smooth experience even when encountering server issues, with clear feedback and appropriate recovery options. 