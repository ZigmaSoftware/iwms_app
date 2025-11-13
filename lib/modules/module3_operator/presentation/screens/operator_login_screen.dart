import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/logic/auth/auth_event.dart';
import 'operator_home_page.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  Center(
                    child: Image.asset(
                      'asset/images/logo.png',
                      height: MediaQuery.of(context).size.height * 0.2,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                  const _FieldLabel('Username'),
                  TextField(
                    controller: _usernameController,
                    decoration: _inputDecoration,
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Password'),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    decoration: _inputDecoration.copyWith(
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _obscureText = !_obscureText),
                        child: Icon(
                          _obscureText ? Icons.visibility : Icons.visibility_off,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.07,
                    child: ElevatedButton(
                    
                      onPressed:(){ _handleLogin();
        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration get _inputDecoration => const InputDecoration(
        fillColor: Color.fromRGBO(240, 240, 240, 1),
        filled: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
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
