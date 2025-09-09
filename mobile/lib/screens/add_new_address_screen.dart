import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../constants.dart';
import '../models/address.dart';
import '../providers/user_provider.dart';
import '../utils/freshk_utils.dart';

class AddNewAddressScreen extends StatefulWidget {
  const AddNewAddressScreen({Key? key}) : super(key: key);

  @override
  State<AddNewAddressScreen> createState() => _AddNewAddressScreenState();
}

class _AddNewAddressScreenState extends State<AddNewAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _streetAddressController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;

  bool _isEditMode = false;
  int? _editingAddressId;

  final _postCodeRegex = RegExp(r'^[a-zA-Z0-9\-]+$');

  @override
  void initState() {
    super.initState();
    _countryController.text = 'Tunisia';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _isEditMode = true;
        _editingAddressId = args['id'] as int?;

        _streetAddressController.text = args['streetAddress'] ??
            args['addressLine1'] ??
            args['street'] ??
            '';
        _cityController.text = args['city'] ?? '';
        _stateController.text = args['state'] ?? '';
        _postalCodeController.text = args['postalCode'] ?? '';
        _countryController.text = args['country'] ?? 'Tunisia';
        _isDefault = args['isDefault'] ?? false;

        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _streetAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final address = Address(
          id: _isEditMode ? _editingAddressId : null,
          streetAddress: _streetAddressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim().isEmpty
              ? null
              : _stateController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          country: _countryController.text.trim(),
          isDefault: _isDefault,
        );

        if (_isEditMode && _editingAddressId != null) {
          await userProvider.updateAddress(_editingAddressId!, address);
          if (mounted) {
            FreshkUtils.showSuccessSnackbar(context,
                AppLocalizations.of(context)!.addressUpdatedSuccessfully);
          }
        } else {
          await userProvider.createAddress(address);
          if (mounted) {
            FreshkUtils.showSuccessSnackbar(context,
                AppLocalizations.of(context)!.addressCreatedSuccessfully);
          }
        }

        if (mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          FreshkUtils.showErrorSnackbar(context,
              '${AppLocalizations.of(context)!.error}: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditMode
            ? AppLocalizations.of(context)!.editAddress
            : AppLocalizations.of(context)!.addNewAddress),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _streetAddressController,
                  label: '${AppLocalizations.of(context)!.streetAddress}*',
                  icon: Icons.location_on_outlined,
                  validator: (val) => val == null || val.isEmpty
                      ? AppLocalizations.of(context)!.pleaseEnterStreetAddress
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _cityController,
                  label: '${AppLocalizations.of(context)!.city}*',
                  icon: Icons.location_city,
                  validator: (val) => val == null || val.isEmpty
                      ? AppLocalizations.of(context)!.pleaseEnterCity
                      : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _stateController,
                  label: AppLocalizations.of(context)!.stateProvinceOptional,
                  icon: Icons.map_outlined,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _postalCodeController,
                  label: '${AppLocalizations.of(context)!.postalCode}*',
                  icon: Icons.markunread_mailbox_outlined,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return AppLocalizations.of(context)!
                          .pleaseEnterPostalCode;
                    } else if (!_postCodeRegex.hasMatch(val)) {
                      return AppLocalizations.of(context)!.enterValidPostalCode;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.setAsDefaultAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Switch(
                      value: _isDefault,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isDefault = val),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isEditMode
                        ? AppLocalizations.of(context)!.updateAddress
                        : AppLocalizations.of(context)!.saveAddress,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
