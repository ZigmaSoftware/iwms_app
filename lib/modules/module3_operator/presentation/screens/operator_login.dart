
// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'dart:ui';
// import 'package:geolocator/geolocator.dart';
// import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_home_page.dart';
// import 'package:http/http.dart' as http;

// class login extends StatefulWidget {
//   const login({super.key});

//   @override
//   State<login> createState() => _loginState();
// }

// class _loginState extends State<login> {

//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   bool _isLoading = false;


//   Future<Map<String, dynamic>> login(String userName, String password) async {
//     final response = await http.post(
//       Uri.parse('http://zigma.in:80/d2d_app/login.php'),
//       body: {
//         'action': 'login',
//         'user_name': userName,
//         'password': password,
//       },
//     );

//     if (response.statusCode == 200) {
//       return json.decode(response.body);
//     } else {
//       throw Exception('Failed to login');
//     }
//   }

//   void _login() async {
//     setState(() {
//       _isLoading = true; // Show the progress indicator
//     });

//     try {
//       final result = await login(
//         _usernameController.text,
//         _passwordController.text,
//       );
//       if (result['status'] == 1) {
//         if (result['msg'] == "success_login") {
//           final staff = result['data']['staff']; // Extract staff name
//           final staffid = result['data']['staffid'];
//           final department_name = result['data']['department_name'];
//           final site_name = result['data']['site_name'];
//           // Navigator.pushReplacement(
//           //   context,
//           //   MaterialPageRoute(builder: (context) => (
//           //     staff: staff,
//           //     site_name: site_name,
//           //     department_name: department_name,
//           //     staffid: staffid,
//           //   )),
//           // );

//           Navigator.pushReplacementNamed(context, '/home');
//         }
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: ${result['error']}')),
//         );
//       }
//     } catch (e) {
//       print('Error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('An unexpected error occurred.')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false; // Hide the progress indicator
//       });
//     }
//   }

//   // void _login() {
//   //   // Basic login validation logic
//   //   if (_usernameController.text == "admin" && _passwordController.text == "123") {
//   //     Navigator.pushReplacementNamed(context, '/home');
//   //   } else {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //
//   //       SnackBar(content: Text('Invalid Credentials'),backgroundColor: Colors.red,behavior: SnackBarBehavior.floating,margin: EdgeInsets.only(top: 5.0,),),
//   //     );
//   //   }
//   // }

//   Future<void> _checkLocationServices() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Test if location services are enabled.
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       // Location services are not enabled, display a popup.
//       _showLocationDialog();
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         // Permissions are denied, display a popup.
//         _showLocationDialog();
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       // Permissions are denied forever, display a popup.
//       _showLocationDialog();
//       return;
//     }
//   }

//   Future<Position> _determinePosition() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied.');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//           'Location permissions are permanently denied, we cannot request permissions.');
//     }

//     return await Geolocator.getCurrentPosition();
//   }

//   void _showLocationDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Enable Location Services'),
//           content: Text(
//               'Location services are required for this app. Please enable location services.'),
//           actions: <Widget>[
//             TextButton(
//               child: Text('OK'),
//               onPressed: () {
//                 Geolocator.openLocationSettings();
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _checkLocationServices();
//     _determinePosition();
//   }

//   @override
//   bool _obscureText = true;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             SingleChildScrollView(
//               child: Container(
//                 padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: <Widget>[
//                     SizedBox(height: MediaQuery
//                         .of(context)
//                         .size
//                         .height * 0.1), // Adjust spacing

//                     // Logo Image
//                     Center(
//                       child: Image.asset(
//                         'asset/images/logo.png',
//                         height: MediaQuery
//                             .of(context)
//                             .size
//                             .height * 0.2,
//                       ),
//                     ),

//                     SizedBox(height: MediaQuery
//                         .of(context)
//                         .size
//                         .height * 0.02),

//                     // Username Field
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Username",
//                             style: TextStyle(fontSize: 12, color: Color
//                                 .fromRGBO(102, 102, 102, 1))),
//                         SizedBox(height: 5),
//                         TextField(
//                           controller: _usernameController,
//                           decoration: InputDecoration(
//                             fillColor: Color.fromRGBO(240, 240, 240, 1),
//                             filled: true,
//                             enabledBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                             focusedBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                             border: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                             disabledBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 20.0),

//                     // Password Field
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.start,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text("Password",
//                             style: TextStyle(fontSize: 12, color: Color
//                                 .fromRGBO(102, 102, 102, 1))),
//                         SizedBox(height: 5),
//                         TextField(
//                           obscureText: _obscureText,
//                           controller: _passwordController,
//                           decoration: InputDecoration(
//                             suffixIcon: GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   _obscureText = !_obscureText;
//                                 });
//                               },
//                               child: Icon(
//                                 _obscureText ? Icons.visibility : Icons
//                                     .visibility_off,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             fillColor: Color.fromRGBO(240, 240, 240, 1),
//                             filled: true,
//                             enabledBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                             focusedBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                             border: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                             disabledBorder: const OutlineInputBorder(
//                               borderSide: BorderSide(color: Color.fromRGBO(186, 186, 186, 1)),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),

//                     SizedBox(height: 40.0),

//                     // Login Button
//                     Container(
//                       height: MediaQuery
//                           .of(context)
//                           .size
//                           .height * 0.07,
//                       width: MediaQuery
//                           .of(context)
//                           .size
//                           .width * 1,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.rectangle,
//                         borderRadius: BorderRadius.all(Radius.circular(0)),
//                       ),
//                       child: ElevatedButton(
//                         onPressed: _login,
//                         child: const Text(
//                           'LOGIN',
//                           style: TextStyle(fontSize: 12, color: Colors.white),
//                         ),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(2),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Loading Indicator (if _isLoading is true)
//             if (_isLoading)
//               Center(
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }