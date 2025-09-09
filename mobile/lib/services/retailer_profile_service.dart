import 'package:freshk/models/retailer_profile.dart';
import 'package:freshk/utils/dio_instance.dart';
import 'package:freshk/utils/exception_handler.dart';

class RetailerProfileService {
  /// Get all retailer profiles for the current user
  static Future<List<RetailerProfile>> getRetailerProfiles() async {
    return ExceptionHandler.execute<List<RetailerProfile>>(
      () async {
        final res = await DioInstance.dio.get("/api/retailers/");
        // Handle paginated response structure
        final data = res.data["results"] as List<dynamic>;
        return data
            .map((profile) =>
                RetailerProfile.fromJson(profile as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Get a specific retailer profile by ID
  static Future<RetailerProfile> getRetailerProfileById(int id) async {
    return ExceptionHandler.execute<RetailerProfile>(
      () async {
        final res = await DioInstance.dio.get("/api/retailers/$id/");
        final data = res.data as Map<String, dynamic>;
        return RetailerProfile.fromJson(data);
      },
    );
  }

  /// Create a new retailer profile
  static Future<RetailerProfile> createRetailerProfile(
      RetailerProfile profile) async {
    return ExceptionHandler.execute<RetailerProfile>(
      () async {
        final res = await DioInstance.dio.post(
          "/api/retailers/",
          data: profile.toCreateJson(),
        );
        final data = res.data as Map<String, dynamic>;
        return RetailerProfile.fromJson(data);
      },
    );
  }

  /// Update an existing retailer profile
  static Future<RetailerProfile> updateRetailerProfile(
      int id, RetailerProfile profile) async {
    return ExceptionHandler.execute<RetailerProfile>(
      () async {
        final res = await DioInstance.dio.put(
          "/api/retailers/$id/",
          data: profile.toCreateJson(),
        );
        final data = res.data as Map<String, dynamic>;
        return RetailerProfile.fromJson(data);
      },
    );
  }

  /// Delete a retailer profile
  static Future<String> deleteRetailerProfile(int id) async {
    return ExceptionHandler.execute<String>(
      () async {
        final res = await DioInstance.dio.delete("/api/retailers/$id/");

        // Check if response has a message
        if (res.data is Map<String, dynamic>) {
          final data = res.data as Map<String, dynamic>;
          return data["message"] as String? ??
              "Retailer profile deleted successfully";
        }

        return "Retailer profile deleted successfully";
      },
    );
  }
}
