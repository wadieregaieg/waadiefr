import 'package:freshk/providers/user_provider.dart';
import 'package:freshk/routes.dart';
import 'package:freshk/utils/freshk_expections.dart';
import 'package:freshk/utils/freshk_utils.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignUpForm extends StatefulWidget {
  final double scale;

  const SignUpForm({super.key, required this.scale});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String _selectedRole = 'retailer';

  final _borderColor = const Color(0xFF9F9F9F);
  final _errorColor = const Color(0xFFD32F2F);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        final message = await userProvider.registerUser(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          firstName: _firstNameController.text.trim().isNotEmpty
              ? _firstNameController.text.trim()
              : null,
          lastName: _lastNameController.text.trim().isNotEmpty
              ? _lastNameController.text.trim()
              : null,
          role: _selectedRole,
          phoneNumber: _phoneController.text.trim().isNotEmpty
              ? "+216${_phoneController.text.trim()}"
              : null,
        );

        if (mounted) {
          FreshkUtils.showSuccessSnackbar(context, message);
          // Navigate back to login screen
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } catch (e) {
        if (e is ValidationException) {
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else if (e is NetworkException) {
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else if (e is ServerException) {
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else if (e is FreshkException) {
          FreshkUtils.showErrorSnackbar(context, e.message);
        } else {
          debugPrint("Error during registration: $e");
          FreshkUtils.showErrorSnackbar(
              context, "An unexpected error occurred");
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _usernameController,
            label: "Username",
            icon: Icons.person_outline,
            validator: _validateUsername,
            scale: scale,
          ),
          SizedBox(height: 16 * scale),
          _buildTextField(
            controller: _emailController,
            label: "Email",
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            scale: scale,
          ),
          SizedBox(height: 16 * scale),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _firstNameController,
                  label: "First Name (Optional)",
                  icon: Icons.person_outline,
                  scale: scale,
                ),
              ),
              SizedBox(width: 12 * scale),
              Expanded(
                child: _buildTextField(
                  controller: _lastNameController,
                  label: "Last Name (Optional)",
                  icon: Icons.person_outline,
                  scale: scale,
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * scale),
          _buildTextField(
            controller: _phoneController,
            label: "Phone Number (Optional)",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            scale: scale,
            prefixText: "+216 ",
          ),
          SizedBox(height: 16 * scale),
          _buildRoleDropdown(scale),
          SizedBox(height: 16 * scale),
          _buildTextField(
            controller: _passwordController,
            label: "Password",
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            validator: _validatePassword,
            scale: scale,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _borderColor,
                size: 24 * scale,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          SizedBox(height: 16 * scale),
          _buildTextField(
            controller: _confirmPasswordController,
            label: "Confirm Password",
            icon: Icons.lock_outline,
            obscureText: _obscureConfirmPassword,
            validator: _validateConfirmPassword,
            scale: scale,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: _borderColor,
                size: 24 * scale,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          SizedBox(height: 32 * scale),
          _buildRegisterButton(scale),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required double scale,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: _borderColor,
          fontSize: 14 * scale,
        ),
        prefixIcon: Icon(
          icon,
          color: _borderColor,
          size: 24 * scale,
        ),
        prefixText: prefixText,
        prefixStyle: TextStyle(
          color: Colors.black,
          fontSize: 16 * scale,
        ),
        suffixIcon: suffixIcon,
        border: _customBorder(scale),
        enabledBorder: _customBorder(scale),
        focusedBorder: _customBorder(scale),
        errorBorder: _customBorder(scale, color: _errorColor),
        focusedErrorBorder: _customBorder(scale, color: _errorColor),
        contentPadding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleDropdown(double scale) {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: "Role",
        labelStyle: TextStyle(
          color: _borderColor,
          fontSize: 14 * scale,
        ),
        prefixIcon: Icon(
          Icons.work_outline,
          color: _borderColor,
          size: 24 * scale,
        ),
        border: _customBorder(scale),
        enabledBorder: _customBorder(scale),
        focusedBorder: _customBorder(scale),
        errorBorder: _customBorder(scale, color: _errorColor),
        focusedErrorBorder: _customBorder(scale, color: _errorColor),
        contentPadding: EdgeInsets.symmetric(
          vertical: 16 * scale,
          horizontal: 12 * scale,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'retailer', child: Text('Retailer')),
        DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
      ],
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedRole = newValue;
          });
        }
      },
    );
  }

  Widget _buildRegisterButton(double scale) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(vertical: 16 * scale),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8 * scale),
        ),
      ),
      child: _isLoading
          ? SizedBox(
              height: 20 * scale,
              width: 20 * scale,
              child: const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              "Create Account",
              style: TextStyle(
                fontSize: 16 * scale,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }

  OutlineInputBorder _customBorder(double scale, {Color? color}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8 * scale),
      borderSide: BorderSide(
        color: color ?? _borderColor,
        width: 1,
      ),
    );
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return "Username is required";
    }
    if (value.length < 3) {
      return "Username must be at least 3 characters";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email is required";
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Please enter a valid email";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }
    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }
    if (value != _passwordController.text) {
      return "Passwords don't match";
    }
    return null;
  }
}
