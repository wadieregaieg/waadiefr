import 'package:freshk/models/address.dart';
import 'package:freshk/models/retailer_profile.dart';
import 'package:freshk/models/user.dart';
import 'package:freshk/services/address_service.dart';
import 'package:freshk/services/retailer_profile_service.dart';
import 'package:freshk/services/user_service.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/freshk_utils.dart';

import 'package:freshk/utils/freshk_expections.dart';
import 'package:flutter/material.dart';

/// Manages the current logged-in user, including addresses.
class UserProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> requestOtp(
    String phoneNumber,
  ) async {
    try {
      return await UserService.authenticateViaPhone(phoneNumber);
    } catch (e) {
      debugPrint("Error requesting OTP: $e");
      rethrow;
    }
  }

  /// Authenticate user via email and password
  Future<void> authenticateViaEmail(String email, String password) async {
    try {
      final authResponse =
          await UserService.authenticateViaEmail(email, password);

      // Set the Dio Headers with the access token
      DioInstance.setDioHeaders(
          {"Authorization": "Bearer ${authResponse.tokens.access}"});

      // Store tokens in secure storage or state management solution
      await FreshkUtils.saveAuthTokens(
          authResponse.tokens.access, authResponse.tokens.refresh);

      // Update user data after successful login
      currentUser = authResponse.user;
      await FreshkUtils.saveUserData(currentUser!);

      notifyListeners();
    } catch (e) {
      debugPrint("Error authenticating via email: $e");
      _currentUser = null; // Reset current user on error
      rethrow; // Let the UI layer handle the error display
    }
  }

  Future<void> verifyOtp(String phoneNumber, String otp,
      {BuildContext? context}) async {
    try {
      final otpResponse = await UserService.verifyOtp(phoneNumber, otp);

      // Set the Dio Headers with the access token
      DioInstance.setDioHeaders(
          {"Authorization": "Bearer ${otpResponse.tokens.access}"});

      // Store tokens in secure storage or state management solution
      await FreshkUtils.saveAuthTokens(
          otpResponse.tokens.access, otpResponse.tokens.refresh);

      // Update user data after successful login
      currentUser = otpResponse.user;
      await FreshkUtils.saveUserData(currentUser!);

      notifyListeners();
    } catch (e) {
      debugPrint("Error verifying OTP: $e");
      _currentUser = null; // Reset current user on error
      rethrow; // Let the UI layer handle the error display
    }
  }

  /// Authenticate user via username and password with JWT
  Future<void> authenticateWithJWT(String username, String password) async {
    try {
      final authResponse =
          await UserService.authenticateWithJWT(username, password);

      // Set the Dio Headers with the access token
      DioInstance.setDioHeaders(
          {"Authorization": "Bearer ${authResponse.tokens.access}"});

      // Store tokens in secure storage or state management solution
      await FreshkUtils.saveAuthTokens(
          authResponse.tokens.access, authResponse.tokens.refresh);

      // Update user data after successful login
      currentUser = authResponse.user;
      await FreshkUtils.saveUserData(currentUser!);

      notifyListeners();
    } catch (e) {
      debugPrint("Error authenticating with JWT: $e");
      _currentUser = null; // Reset current user on error
      rethrow; // Let the UI layer handle the error display
    }
  }

  /// Register a new user account
  Future<String> registerUser({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? firstName,
    String? lastName,
    String? role,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      return await UserService.registerUser(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phoneNumber: phoneNumber,
        preferences: preferences,
      );
    } catch (e) {
      debugPrint("Error registering user: $e");
      rethrow;
    }
  }

  /// Request password reset via email or phone number (new API)
  Future<String> requestPasswordResetNew({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      return await UserService.requestPasswordResetNew(
        email: email,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      debugPrint("Error requesting password reset: $e");
      rethrow;
    }
  }

  /// Confirm password reset with token and new password (new API)
  Future<String> confirmPasswordResetNew(
    String token,
    String password,
    String password2,
  ) async {
    try {
      return await UserService.confirmPasswordResetNew(
        token,
        password,
        password2,
      );
    } catch (e) {
      debugPrint("Error confirming password reset: $e");
      rethrow;
    }
  }

  /// Checks if user is authenticated and refreshes their session.
  /// Returns true if authentication is successful.
  Future<bool> checkUserAuth() async {
    try {
      final isLoggedIn = await FreshkUtils.isUserLoggedIn();
      if (!isLoggedIn) {
        debugPrint("User is not logged in");
        return false;
      }

      final tokens = await FreshkUtils.getTokensFromStorage();
      if (tokens == null) {
        debugPrint("No tokens found in storage");
        await FreshkUtils.deleteAuthTokens();
        await FreshkUtils.deleteUserData();
        return false;
      }

      try {
        // Refresh access token
        final accessToken = await UserService.refreshAccesToken(
          tokens.refresh,
        );
        tokens.access = accessToken;

        DioInstance.setDioAuthorizationHeader(accessToken);
        await FreshkUtils.saveAuthTokens(tokens.access, tokens.refresh);

        // Try to get user data
        final userData = await UserService.getUserData();
        currentUser = userData;
        await FreshkUtils.saveUserData(userData);

        return true;
      } catch (userDataError) {
        debugPrint(
            "Error retrieving user data after token refresh: $userDataError");
        rethrow;
      }
    } catch (serviceError) {
      if (serviceError is AuthenticationException) {
        debugPrint("Authentication token rejected: $serviceError");
        // Handle token rejection, e.g., by logging out the user
        await FreshkUtils.deleteAuthTokens();
        await FreshkUtils.deleteUserData();
        _currentUser = null; // Reset current user
        notifyListeners();
      } else {
        rethrow;
      }
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    await FreshkUtils.deleteAuthTokens(); // Clear tokens from secure storage
    await FreshkUtils.deleteUserData(); // Also clear user data
    notifyListeners();
  }
  // ADDRESS MANAGEMENT

  /// Get all addresses for the current user from the API
  Future<List<Address>> getUserAddresses() async {
    try {
      final addresses = await AddressService.getUserAddresses();
      // Update the local user addresses
      if (_currentUser != null) {
        _currentUser!.addresses = addresses;
        notifyListeners();
      }
      return addresses;
    } catch (e) {
      debugPrint("Error fetching user addresses: $e");
      rethrow;
    }
  }

  /// Create a new address via API and update local state
  Future<Address> createAddress(Address address) async {
    try {
      final createdAddress = await AddressService.createAddress(address);

      // Update local state
      if (_currentUser != null) {
        // If the new address is default, un-set default for all others
        if (createdAddress.isDefault) {
          for (var addr in _currentUser!.addresses) {
            addr.isDefault = false;
          }
        }
        _currentUser!.addresses.add(createdAddress);
        notifyListeners();
      }

      debugPrint("Address created successfully: ${createdAddress.id}");
      return createdAddress;
    } catch (e) {
      debugPrint("Error creating address: $e");
      rethrow;
    }
  }

  /// Update an existing address via API and update local state
  Future<Address> updateAddress(int addressId, Address address) async {
    try {
      final updatedAddress =
          await AddressService.updateAddress(addressId, address);

      // Update local state
      if (_currentUser != null) {
        final index =
            _currentUser!.addresses.indexWhere((addr) => addr.id == addressId);
        if (index != -1) {
          // If the updated address is default, un-set default for all others
          if (updatedAddress.isDefault) {
            for (int i = 0; i < _currentUser!.addresses.length; i++) {
              if (i != index) {
                _currentUser!.addresses[i].isDefault = false;
              }
            }
          }
          _currentUser!.addresses[index] = updatedAddress;
          notifyListeners();
        }
      }

      debugPrint("Address updated successfully: ${updatedAddress.id}");
      return updatedAddress;
    } catch (e) {
      debugPrint("Error updating address: $e");
      rethrow;
    }
  }

  /// Delete an address via API and update local state
  Future<void> deleteAddress(int addressId) async {
    try {
      await AddressService.deleteAddress(addressId);

      // Update local state
      if (_currentUser != null) {
        _currentUser!.addresses.removeWhere((addr) => addr.id == addressId);
        notifyListeners();
      }

      debugPrint("Address deleted successfully: $addressId");
    } catch (e) {
      debugPrint("Error deleting address: $e");
      rethrow;
    }
  }

  /// Set an address as default via API and update local state
  Future<Address> setDefaultAddress(int addressId) async {
    try {
      final defaultAddress = await AddressService.setDefaultAddress(addressId);

      // Update local state
      if (_currentUser != null) {
        // Un-set default for all addresses
        for (var addr in _currentUser!.addresses) {
          addr.isDefault = false;
        }
        // Set the new default
        final index =
            _currentUser!.addresses.indexWhere((addr) => addr.id == addressId);
        if (index != -1) {
          _currentUser!.addresses[index] = defaultAddress;
        }
        notifyListeners();
      }

      debugPrint("Default address set successfully: ${defaultAddress.id}");
      return defaultAddress;
    } catch (e) {
      debugPrint("Error setting default address: $e");
      rethrow;
    }
  }

  /// Get the default address
  Future<Address?> getDefaultAddress() async {
    try {
      return await AddressService.getDefaultAddress();
    } catch (e) {
      debugPrint("Error fetching default address: $e");
      rethrow;
    }
  }

  // Legacy methods for backward compatibility (deprecated)
  @Deprecated('Use createAddress instead')
  void addAddress(Address address) {
    if (_currentUser == null) return;

    // If the new address is default, un-set default for all others
    if (address.isDefault) {
      for (var addr in _currentUser!.addresses) {
        addr.isDefault = false;
      }
    }

    _currentUser!.addresses.add(address);
    notifyListeners();
  }

  @Deprecated('Use updateAddress with API ID instead')
  void updateAddressByIndex(int index, Address updatedAddress) {
    if (_currentUser == null) return;

    // If the updated address is default, un-set default for all others
    if (updatedAddress.isDefault) {
      for (int i = 0; i < _currentUser!.addresses.length; i++) {
        if (i != index) {
          _currentUser!.addresses[i].isDefault = false;
        }
      }
    }

    _currentUser!.addresses[index] = updatedAddress;
    notifyListeners();
  }

  @Deprecated('Use deleteAddress with API ID instead')
  void removeAddress(int index) {
    if (_currentUser == null) return;
    _currentUser!.addresses.removeAt(index);
    notifyListeners();
  }

  /// Request password reset via email or phone number
  Future<String> requestPasswordReset({
    String? email,
    String? phoneNumber,
  }) async {
    try {
      return await UserService.requestPasswordResetNew(
        email: email,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      debugPrint("Error requesting password reset: $e");
      rethrow;
    }
  }

  /// Confirm password reset with token and new password
  Future<String> confirmPasswordReset(
    String token,
    String newPassword,
  ) async {
    try {
      return await UserService.confirmPasswordResetNew(
        token,
        newPassword,
        newPassword, // password2 parameter for confirmation
      );
    } catch (e) {
      debugPrint("Error confirming password reset: $e");
      rethrow;
    }
  }

  // USER PROFILE MANAGEMENT

  /// Update user profile with firstName, lastName, and email
  Future<User> updateUserProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    try {
      final updatedUser = await UserService.updateUserProfile(
        firstName: firstName,
        lastName: lastName,
        email: email,
      );

      // Update local state
      _currentUser = updatedUser;
      await FreshkUtils.saveUserData(updatedUser);
      notifyListeners();

      debugPrint("User profile updated successfully: ${updatedUser.id}");
      return updatedUser;
    } catch (e) {
      debugPrint("Error updating user profile: $e");
      rethrow;
    }
  }

  // RETAILER PROFILE MANAGEMENT

  /// Get all retailer profiles for the current user
  Future<List<RetailerProfile>> getRetailerProfiles() async {
    try {
      return await RetailerProfileService.getRetailerProfiles();
    } catch (e) {
      debugPrint("Error fetching retailer profiles: $e");
      rethrow;
    }
  }

  /// Get a specific retailer profile by ID
  Future<RetailerProfile> getRetailerProfileById(int id) async {
    try {
      return await RetailerProfileService.getRetailerProfileById(id);
    } catch (e) {
      debugPrint("Error fetching retailer profile: $e");
      rethrow;
    }
  }

  /// Create a new retailer profile
  Future<RetailerProfile> createRetailerProfile(RetailerProfile profile) async {
    try {
      final createdProfile =
          await RetailerProfileService.createRetailerProfile(profile);
      debugPrint("Retailer profile created successfully: ${createdProfile.id}");
      return createdProfile;
    } catch (e) {
      debugPrint("Error creating retailer profile: $e");
      rethrow;
    }
  }

  /// Update an existing retailer profile
  Future<RetailerProfile> updateRetailerProfile(
      int id, RetailerProfile profile) async {
    try {
      final updatedProfile =
          await RetailerProfileService.updateRetailerProfile(id, profile);
      debugPrint("Retailer profile updated successfully: ${updatedProfile.id}");
      return updatedProfile;
    } catch (e) {
      debugPrint("Error updating retailer profile: $e");
      rethrow;
    }
  }

  /// Delete a retailer profile
  Future<String> deleteRetailerProfile(int id) async {
    try {
      final message = await RetailerProfileService.deleteRetailerProfile(id);
      debugPrint("Retailer profile deleted successfully: $id");
      return message;
    } catch (e) {
      debugPrint("Error deleting retailer profile: $e");
      rethrow;
    }
  }
}
