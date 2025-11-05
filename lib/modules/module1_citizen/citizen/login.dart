// lib/modules/module1_citizen/citizen/login.dart
import '../../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final List<String> _countryCodes = ['+91', '+1', '+44', '+86', '+49'];
  String _selectedCountryCode = '+91';
  final TextEditingController _mobileController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  void _login(BuildContext context) {
    final mobileNumber = _mobileController.text.trim();
    if (mobileNumber.length != 10) {
      _showSnack('Please enter a valid 10-digit mobile number.', Colors.red);
      return;
    }

    context
        .read<AuthBloc>()
        .add(AuthCitizenLoginRequested(phone: mobileNumber));
  }

  void _openRegistration(BuildContext context) {
    final phone = _mobileController.text.trim();
    context.push(
      AppRoutePaths.citizenRegister,
      extra: {
        if (phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _appLogoAsset() {
    return Container(
      height: 100,
      width: 100,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Image.asset('assets/images/logo.png', width: 80, height: 80),
    );
  }

  Widget _buildCountryCodeDropdown() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        border: Border.all(color: kBorderColor, width: 1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8.0),
          bottomLeft: Radius.circular(8.0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountryCode,
          icon: Icon(Icons.arrow_drop_down, color: textColor),
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          dropdownColor: Colors.white,
          items: _countryCodes.map((String code) {
            return DropdownMenuItem<String>(
              value: code,
              child: Text(
                code,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedCountryCode = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;
    final textColor = colorScheme.onSurface;
    final placeholderColor = colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthStateFailure) {
              _showSnack(state.message, Colors.red);
            }
            if (state is AuthStateAuthenticatedCitizen) {
              _showSnack('Welcome back, ${state.userName ?? 'citizen'}!', primaryColor);
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthStateLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      _appLogoAsset(),
                      const SizedBox(height: 32),
                      Text(
                        "Welcome to IWMS",
                        style: theme.textTheme.titleLarge!.copyWith(color: textColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Log in with your registered mobile number or register your household.",
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium!.copyWith(
                          color: placeholderColor,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              "Mobile Number",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _buildCountryCodeDropdown(),
                              Expanded(
                                child: TextFormField(
                                  controller: _mobileController,
                                  keyboardType: TextInputType.phone,
                                  maxLength: 10,
                                  enabled: !isLoading,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding:
                                        const EdgeInsets.symmetric(horizontal: 16.0),
                                    hintText: "Mobile Number (10 digits)",
                                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                      color: placeholderColor,
                                      fontSize: 16,
                                    ),
                                    filled: true,
                                    fillColor: theme.inputDecorationTheme.fillColor,
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8.0),
                                        bottomRight: Radius.circular(8.0),
                                      ),
                                      borderSide:
                                          BorderSide(color: kBorderColor, width: 1),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8.0),
                                        bottomRight: Radius.circular(8.0),
                                      ),
                                      borderSide:
                                          BorderSide(color: kBorderColor, width: 1),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(8.0),
                                        bottomRight: Radius.circular(8.0),
                                      ),
                                      borderSide:
                                          BorderSide(color: primaryColor, width: 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _login(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            'Log In',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: isLoading ? null : () => _openRegistration(context),
                        child: Text(
                          "New user? Register your household",
                          style: TextStyle(
                            fontSize: 14,
                            color: isLoading
                                ? textColor.withOpacity(0.5)
                                : primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
