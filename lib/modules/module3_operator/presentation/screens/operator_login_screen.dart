import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/logic/auth/auth_event.dart';
import 'package:iwms_citizen_app/router/app_router.dart';

const Color _operatorPrimary = Color(0xFF1B5E20);
const Color _operatorAccent = Color(0xFF66BB6A);
const Color _operatorBackground = Color(0xFFF3F6F2);

class OperatorLoginScreen extends StatefulWidget {
  const OperatorLoginScreen({super.key});

  @override
  State<OperatorLoginScreen> createState() => _OperatorLoginScreenState();
}

class _OperatorLoginScreenState extends State<OperatorLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _checkLocationServices();
    _determinePosition();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _login(String userName, String password) async {
    final response = await http.post(
      Uri.parse('http://zigma.in:80/d2d_app/login.php'),
      body: {
        'action': 'login',
        'user_name': userName,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to login');
  }
Future<void> _handleLogin() async {
  FocusScope.of(context).unfocus();
  setState(() => _isLoading = true);

  try {
    final result = await _login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

   if (result['status'] == 1 && result['msg'] == 'success_login') {
  context.read<AuthBloc>().add(
    AuthOperatorLoginRequested(
      userName: result['name'] ?? _usernameController.text.trim(),
      operatorId: result['empid'].toString(),
    ),
  );

  context.go('/operator-home');
}

     else {
      _showSnack(result['error'] ?? "Invalid username or password");
    }
  } catch (e) {
    _showSnack("Something went wrong. Try again.");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  // Future<void> _handleLogin() async {
  //   setState(() => _isLoading = true);

  //   try {
  //     final result = await _login(
  //       _usernameController.text.trim(),
  //       _passwordController.text,
  //     );
  //     if (result['status'] == 1 && result['msg'] == 'success_login') {
  //       if (!mounted) return;
  //       Navigator.pushReplacement(
  //         context,
  //         MaterialPageRoute(builder: (_) => const OperatorHomePage()),
  //       );
  //     } else {
  //       final message = result['error'] ?? 'Login failed';
  //       _showSnack(message.toString());
  //     }
  //   } catch (e) {
  //     _showSnack('An unexpected error occurred.');
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //     }
  //   }
  // }

  Future<void> _checkLocationServices() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationDialog();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDialog();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationDialog();
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    return Geolocator.getCurrentPosition();
  }

  void _showLocationDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enable Location Services'),
          content: const Text(
            'Location services are required for this app. Please enable location services.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Geolocator.openLocationSettings();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () async {
        // Prevent app close; always return to role selection.
        context.go(AppRoutePaths.selectUser);
        return false;
      },
      child: Scaffold(
        backgroundColor: _operatorBackground,
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(size, theme),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: _buildLoginCard(theme),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: _operatorPrimary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Size size, ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_operatorPrimary, _operatorAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                height: size.height * 0.12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'asset/images/logo.png',
                    height: size.height * 0.1,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              IconButton(onPressed: (){context.push("/select-user");}, icon: Icon(Icons.home,color: Colors.white,))
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Operator Console',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Access secure weighment & scanning tools in one tap.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(ThemeData theme) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sign in to continue',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const _FieldLabel('Username'),
            TextField(
              controller: _usernameController,
              decoration: _inputDecoration.copyWith(
                hintText: 'Enter your operator ID',
              ),
            ),
            const SizedBox(height: 20),
            const _FieldLabel('Password'),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: _inputDecoration.copyWith(
                hintText: 'Enter your password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                  ),
                  color: Colors.grey.shade600,
                  onPressed: () => setState(() {
                    _obscureText = !_obscureText;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact your supervisor to reset password.'),
                    ),
                  );
                },
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _operatorPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'LOGIN',
                  style: TextStyle(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration get _inputDecoration => InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _operatorPrimary, width: 1.4),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color.fromRGBO(102, 102, 102, 1),
        ),
      ),
    );
  }
}
