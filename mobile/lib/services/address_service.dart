import 'package:freshk/models/address.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/exception_handler.dart';
import 'package:flutter/foundation.dart';

class AddressService {
  /// Get all addresses for the authenticated user
  static Future<List<Address>> getUserAddresses() async {
    return ExceptionHandler.execute<List<Address>>(
      () async {
        final response = await DioInstance.dio.get("/api/addresses/");

        // Debug: Log the response structure
        if (kDebugMode) {
          print('Address API Response: ${response.data}');
          print('Response type: ${response.data.runtimeType}');
        }

        // Handle different response structures
        List<dynamic> addressList;

        if (response.data is List) {
          // Direct array response
          addressList = response.data as List<dynamic>;
        } else if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;

          if (responseData.containsKey('results')) {
            // Paginated response
            addressList = responseData['results'] as List<dynamic>;
          } else if (responseData.containsKey('addresses')) {
            // Wrapped in addresses key
            addressList = responseData['addresses'] as List<dynamic>;
          } else {
            // No addresses found
            addressList = [];
          }
        } else {
          // Unexpected response format
          addressList = [];
        }

        if (kDebugMode) {
          print('Parsed address list length: ${addressList.length}');
        }

        return addressList
            .map((json) => Address.fromJson(json as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Get a specific address by ID
  static Future<Address> getAddressById(int id) async {
    return ExceptionHandler.execute<Address>(
      () async {
        final response = await DioInstance.dio.get("/api/addresses/$id/");
        final data = response.data as Map<String, dynamic>;
        return Address.fromJson(data);
      },
    );
  }

  /// Create a new address
  static Future<Address> createAddress(Address address) async {
    return ExceptionHandler.execute<Address>(
      () async {
        final response = await DioInstance.dio.post(
          "/api/addresses/",
          data: address.toJson(),
        );
        final data = response.data as Map<String, dynamic>;
        return Address.fromJson(data);
      },
    );
  }

  /// Update an existing address
  static Future<Address> updateAddress(int id, Address address) async {
    return ExceptionHandler.execute<Address>(
      () async {
        final response = await DioInstance.dio.put(
          "/api/addresses/$id/",
          data: address.toJson(),
        );
        final data = response.data as Map<String, dynamic>;
        return Address.fromJson(data);
      },
    );
  }

  /// Delete an address
  static Future<void> deleteAddress(int id) async {
    return ExceptionHandler.execute<void>(
      () async {
        await DioInstance.dio.delete("/api/addresses/$id/");
      },
    );
  }

  /// Set an address as default
  static Future<Address> setDefaultAddress(int id) async {
    return ExceptionHandler.execute<Address>(
      () async {
        final response =
            await DioInstance.dio.post("/api/addresses/$id/set_default/");
        final data = response.data as Map<String, dynamic>;
        return Address.fromJson(data);
      },
    );
  }

  /// Get the default address
  static Future<Address?> getDefaultAddress() async {
    return ExceptionHandler.execute<Address?>(
      () async {
        try {
          final response = await DioInstance.dio.get("/api/addresses/default/");
          final data = response.data as Map<String, dynamic>;
          return Address.fromJson(data);
        } catch (e) {
          // If no default address exists, return null
          return null;
        }
      },
    );
  }
}
