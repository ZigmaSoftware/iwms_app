import 'package:flutter/material.dart';

import 'operator_login_screen.dart';
import 'operator_qr_scanner.dart';

class OperatorHomePage extends StatelessWidget {
  const OperatorHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(0, 61, 125, 0.8),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => _openScanner(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner,
                    color: Colors.black, size: 200),
                onPressed: () => _openScanner(context),
              ),
              const Text("Tap here to scan!"),
            ],
          ),
        ),
      ),
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperatorQRScanner()),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          title: const Text(
            "Are you sure want to logout?",
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Logout"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OperatorLoginScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}
