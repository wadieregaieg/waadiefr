import 'package:freshk/extensions/localized_context.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/utils/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:freshk/constants.dart';
import 'package:freshk/models/retailer_profile.dart';
import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/utils/freshk_utils.dart';

class CreateEditRetailerProfileScreen extends StatefulWidget {
  final RetailerProfile? profile;

  const CreateEditRetailerProfileScreen({super.key, this.profile});

  bool get isEditing => profile != null;

  // Also check if we're editing based on loaded profile
  bool get isEditingMode => profile != null;

  @override
  State<CreateEditRetailerProfileScreen> createState() =>
      _CreateEditRetailerProfileScreenState();
}

class _CreateEditRetailerProfileScreenState
    extends State<CreateEditRetailerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNumberController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingProfile = false;
  RetailerProfile? _currentProfile;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _populateFieldsFromProfile(widget.profile!);
    } else {
      // If no profile is passed, try to load the user's existing profile
      _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoadingProfile = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final profiles = await userProvider.getRetailerProfiles();

      if (profiles.isNotEmpty) {
        // If user has an existing profile, use it for editing
        _currentProfile = profiles.first;
        _populateFieldsFromProfile(_currentProfile!);
      }
    } catch (e) {
      // If there's an error loading profiles, continue with empty form
      debugPrint('Error loading user profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  void _populateFieldsFromProfile(RetailerProfile profile) {
    _companyNameController.text = profile.companyName;
    _addressController.text = profile.address;
    _contactNumberController.text = profile.contactNumber;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _addressController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // Determine which profile to use (passed profile or loaded profile)
      final existingProfile = widget.profile ?? _currentProfile;

      // Ensure contact number starts with +216, but don't duplicate
      String contactNumber = _contactNumberController.text.trim();
      if (contactNumber.startsWith('+216')) {
        // already has +216
      } else if (contactNumber.startsWith('216')) {
        contactNumber = '+$contactNumber';
      } else {
        contactNumber = '+216$contactNumber';
      }

      final profile = RetailerProfile(
        id: existingProfile?.id,
        companyName: _companyNameController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: contactNumber,
        user: existingProfile?.user,
        username: existingProfile?.username,
        companies: existingProfile?.companies ?? [],
      );

      if (existingProfile != null) {
        // Update existing profile
        await userProvider.updateRetailerProfile(existingProfile.id!, profile);
      } else {
        // Create new profile
        await userProvider.createRetailerProfile(profile);
      }

      if (mounted) {
        FreshkUtils.showSuccessSnackbar(
          context,
          existingProfile != null
              ? context.loc.retailerProfileUpdatedSuccessfully
              : context.loc.retailerProfileCreatedSuccessfully,
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          // If we can't pop, navigate to the home screen
          NavigationService.pushNamedAndRemoveUntil(
            AppRoutes.main,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        FreshkUtils.showErrorSnackbar(
          context,
          '${context.loc.error} $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're editing (either passed profile or loaded profile)
    final isEditingMode = widget.profile != null || _currentProfile != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          isEditingMode
              ? context.loc.editRetailerProfile
              : context.loc.createRetailerProfile,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProfile) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Determine if we're editing (either passed profile or loaded profile)
    final isEditingMode = widget.profile != null || _currentProfile != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditingMode
                              ? context.loc.updateProfileTitle
                              : context.loc.newProfileTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isEditingMode
                              ? context
                                  .loc.modifyYourRetailerBusinessInformation
                              : context
                                  .loc.enterYourRetailerBusinessInformation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24), // Form Fields
            _buildTextField(
              controller: _companyNameController,
              label: context.loc.companyNameLabel,
              icon: Icons.business,
              hint: context.loc.enterYourCompanyNameLabel,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.loc.companyNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: context.loc.addressLabel,
              icon: Icons.location_on,
              hint: context.loc.enterYourBusinessAddressLabel,
              minLines: 1,
              maxLines: null,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.loc.addressRequiredLabel;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _contactNumberController,
              label: context.loc.contactNumberLabel,
              icon: Icons.phone,
              hint: context.loc.enterYourContactNumberLabel,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return context.loc.contactNumberRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: AppColors.primary,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditingMode
                          ? context.loc.updateProfile
                          : context.loc.createProfile,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    int? minLines,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      minLines: minLines,
      maxLines: maxLines,
      validator: validator,
    );
  }
}
