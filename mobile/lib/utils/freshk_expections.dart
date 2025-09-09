class FreshkException implements Exception {
  final String message;
  FreshkException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends FreshkException {
  NetworkException([String message = 'No Internet connection.'])
      : super(message);
}

class ServerException extends FreshkException {
  final int? statusCode;
  final String? serverMessage;
  final bool isRetryable;
  final int retryCount;
  
  ServerException([
    String message = 'Server is down, please try again later.',
    this.statusCode,
    this.serverMessage,
    this.isRetryable = true,
    this.retryCount = 0,
  ]) : super(message);
}

class TransientServerException extends ServerException {
  TransientServerException([
    String message = 'Temporary server issue. Please try again.',
    int? statusCode,
    String? serverMessage,
    int retryCount = 0,
  ]) : super(message, statusCode, serverMessage, true, retryCount);
}

class PersistentServerException extends ServerException {
  PersistentServerException([
    String message = 'Server is currently unavailable. Please try again later.',
    int? statusCode,
    String? serverMessage,
  ]) : super(message, statusCode, serverMessage, false, 0);
}

class AuthenticationException extends FreshkException {
  AuthenticationException([String message = 'Authentication failed.'])
      : super(message);
}

class ValidationException extends FreshkException {
  ValidationException([String message = 'Invalid input.']) : super(message);
}

class NotFoundException extends FreshkException {
  NotFoundException([String message = 'Requested resource not found.'])
      : super(message);
}

class PermissionException extends FreshkException {
  PermissionException([String message = 'Permission denied.']) : super(message);
}

class UnknownException extends FreshkException {
  UnknownException([String message = 'An unknown error occurred.'])
      : super(message);
}

class StorageException extends FreshkException {
  StorageException(
      [String message = 'Error storing or retrieving secure data.'])
      : super(message);
}

// Checkout-specific exceptions
class EmptyCartException extends FreshkException {
  EmptyCartException([String message = 'Cannot checkout with empty cart.'])
      : super(message);
}

class StockException extends FreshkException {
  final String productName;
  final int availableStock;
  final String unit;

  StockException({
    required this.productName,
    required this.availableStock,
    required this.unit,
    String? message,
  }) : super(message ??
            'Not enough stock for $productName. Available: $availableStock $unit');
}

class AddressRequiredException extends FreshkException {
  AddressRequiredException([String message = 'Address is required for checkout.'])
      : super(message);
}

class RetailerOnlyException extends FreshkException {
  RetailerOnlyException([String message = 'This action is only available for retailers.'])
      : super(message);
}
