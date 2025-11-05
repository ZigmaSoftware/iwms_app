import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';

// Dropdown items for property type
enum PropertyType { house, apartment, office, commercial, other }

class RegisterScreen extends StatefulWidget {
  final String? phone;

  const RegisterScreen({super.key, this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _zoneController = TextEditingController();
  final TextEditingController _wardController = TextEditingController();

  PropertyType? _selectedPropertyType;

  @override
  void initState() {
    super.initState();
    if (widget.phone != null) {
      _contactController.text = widget.phone!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _zoneController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final phone = _contactController.text.trim();

    if (phone.isEmpty) {
      _showSnack('Enter your phone number.', Colors.red);
      return;
    }

    if (_selectedPropertyType == null) {
      _showSnack('Select your property type.', Colors.red);
      return;
    }

    if (_formKey.currentState?.validate() != true) {
      return;
    }

    context.read<AuthBloc>().add(AuthCitizenRegisterRequested(
          phone: phone,
          ownerName: _nameController.text.trim(),
          contactNo: _contactController.text.trim(),
          buildingNo: _buildingController.text.trim(),
          street: _streetController.text.trim(),
          area: _areaController.text.trim(),
          pincode: _pincodeController.text.trim(),
          city: _cityController.text.trim(),
          district: _districtController.text.trim(),
          state: _stateController.text.trim(),
          zone: _zoneController.text.trim(),
          ward: _wardController.text.trim(),
          propertyName: _selectedPropertyType!.name.toUpperCase(),
        ));
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Required field'
              : null,
        ),
        const SizedBox(height: 20),
      ],
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
      appBar: AppBar(
        title: Text(
          'Citizen Registration',
          style: theme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthStateFailure) {
              _showSnack(state.message, Colors.red);
            } else if (state is AuthStateAuthenticatedCitizen) {
              _showSnack('Registration complete!', primaryColor);
            }
          },
          builder: (context, state) {
            final bool isLoading = state is AuthStateLoading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Complete your home profile',
                          style: theme.textTheme.titleLarge!.copyWith(
                            color: textColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The details help us create your unique collection QR and service schedule.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: placeholderColor,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(
                          context,
                          label: 'Owner Name',
                          controller: _nameController,
                        ),
                        _buildTextField(
                          context,
                          label: 'Contact Number',
                          controller: _contactController,
                          keyboardType: TextInputType.phone,
                          readOnly: widget.phone != null,
                        ),
                        _buildTextField(
                          context,
                          label: 'Building / Door Number',
                          controller: _buildingController,
                        ),
                        _buildTextField(
                          context,
                          label: 'Street',
                          controller: _streetController,
                        ),
                        _buildTextField(
                          context,
                          label: 'Area / Locality',
                          controller: _areaController,
                        ),
                        _buildTextField(
                          context,
                          label: 'Pincode',
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField(
                          context,
                          label: 'City',
                          controller: _cityController,
                        ),
                        _buildTextField(
                          context,
                          label: 'District',
                          controller: _districtController,
                        ),
                        _buildTextField(
                          context,
                          label: 'State',
                          controller: _stateController,
                        ),
                        _buildTextField(
                          context,
                          label: 'Zone',
                          controller: _zoneController,
                        ),
                        _buildTextField(
                          context,
                          label: 'Ward',
                          controller: _wardController,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Property Type',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        DropdownButtonFormField<PropertyType>(
                          initialValue: _selectedPropertyType,
                          decoration: const InputDecoration(),
                          items: PropertyType.values
                              .map(
                                (type) => DropdownMenuItem<PropertyType>(
                                  value: type,
                                  child: Text(type.name.toUpperCase()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPropertyType = value;
                            });
                          },
                          validator: (value) => value == null ? 'Select one' : null,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: Text(
                              'Complete Registration',
                              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
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
