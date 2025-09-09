// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // For ImageSource
import 'package:qr_flutter/qr_flutter.dart'; // For QrImageView/QrVersions
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../models/user.dart'; // For User model
import '../../../constants.dart';
import '../../../routes.dart';
import '../../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  PreferredSizeWidget _buildPorifleAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Profile', style: TextStyles.sectionHeader),
      centerTitle: true,
      actions: const [
        // IconButton(
        //   icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
        //   onPressed: () => _showQrDialog(context),
        // ),
      ],
      backgroundColor: Colors.white,
      elevation: 1,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final user = userProvider.currentUser;
        final formattedId =
            user?.id.toString().padLeft(13, '0').substring(0, 13) ??
                '0000000000000';

        return ListView(
          padding: const EdgeInsets.all(AppDimensions.padding),
          children: [
            _buildProfileSection(context, user, formattedId),
            const SizedBox(height: AppDimensions.spacingLarge),
            _buildSectionTitle(AppLocalizations.of(context)!.myAccount),
            _buildMenuItem(
              context,
              Icons.location_on,
              AppLocalizations.of(context)!.shippingAddress,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.addressScreen),
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              Icons.store,
              AppLocalizations.of(context)!.retailerProfiles,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.retailerProfiles),
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              Icons.settings,
              AppLocalizations.of(context)!.settings,
              onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
            _buildSectionTitle(AppLocalizations.of(context)!.other),
            _buildMenuItem(
              context,
              Icons.help_outline,
              AppLocalizations.of(context)!.supportCenter,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.supportCenter),
            ),
            _buildDivider(),
            _buildMenuItem(
              context,
              Icons.info_outline,
              AppLocalizations.of(context)!.termsAndConditions,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.termsConditions),
            ),
            _buildDivider(),
            _buildMenuItem(
                context, Icons.logout, AppLocalizations.of(context)!.logOut,
                isLogout: true),
          ],
        );
      },
    );
  }

  Widget _buildProfileSection(
      BuildContext context, User? user, String formattedId) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : const AssetImage('assets/profile_placeholder.png')
                      as ImageProvider,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.username ?? 'Guest', style: TextStyles.sectionHeader),
              const SizedBox(height: 4),
              Text(user?.phoneNumber ?? '', style: TextStyles.secondaryText),
              const SizedBox(height: 4),
              Text("ID: #$formattedId", style: TextStyles.secondaryText),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingSmall),
      child: Text(title, style: TextStyles.sectionHeader),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String text,
      {bool isLogout = false, VoidCallback? onTap}) {
    return ListTile(
      leading:
          Icon(icon, color: isLogout ? AppColors.error : AppColors.primary),
      title: Text(text,
          style: TextStyle(
            color: isLogout ? AppColors.error : AppColors.textPrimary,
          )),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap ??
          () {
            if (isLogout) _confirmLogout(context);
          },
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.shade200);
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.logOut),
        content: Text(AppLocalizations.of(context)!.areYouSureLogOut),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Provider.of<UserProvider>(context, listen: false).logout();
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (route) => false,
              );
            },
            child: Text(AppLocalizations.of(context)!.logOut,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // These methods are not going to be used, maybe in the future
  void _showQrDialog(BuildContext context) {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user == null) return;

    final formattedId = user.id.toString().padLeft(13, '0').substring(0, 13);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('My QR Code',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  data: formattedId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  errorStateBuilder: (cxt, err) {
                    return const Center(
                      child: Text('Failed to generate QR code',
                          style: TextStyle(color: Colors.red)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "ID: #$formattedId",
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child:
                const Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showImageSourceSelector(BuildContext context) {
    showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.selectImageSource,
              style: TextStyles.sectionHeader.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(AppLocalizations.of(context)!.chooseFromGallery),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(AppLocalizations.of(context)!.takeAPhoto),
              onTap: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
                _pickImage(ImageSource.camera);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
      // Optionally, update the user's profile picture in your UserProvider here.
    }
  }
}
