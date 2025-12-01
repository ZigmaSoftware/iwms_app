
// import 'package:flutter/material.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:path/path.dart' as path;
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:provider/provider.dart';
// import 'package:intl/intl.dart';
// import 'package:go_router/go_router.dart';


// class Profile extends StatefulWidget {
//   final String empid;
//   const Profile({super.key, required this.empid});

//   @override
//   State<Profile> createState() => _ProfileState();
// }

// class _ProfileState extends State<Profile> {
//   XFile? _image;
//   Map<String, dynamic>? employeeDetails;
//   bool isSubmitting = false;
//   String? imageName;
//   String baseUrl = 'http://125.17.238.158:5000';
//   bool isDataLoaded = false;
//   bool isLoading = true;
//   final FlutterTts _flutterTts = FlutterTts();
//   Map<String, dynamic>? headDetails;

//   @override
//   void initState() {
//     super.initState();
//     fetchEmployeeDetails();
//     fetchAndSetImage();
//     fetchHeadDetails();
//   }



//   String formatDate(String? dob) {
//     if (dob == null || dob.isEmpty) return "Not Available";
//     try {
//       DateTime parsedDate;
//       if (dob.contains('GMT')) {
//         parsedDate = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(dob, true);
//       } else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dob)) {
//         parsedDate = DateFormat("yyyy-MM-dd").parse(dob);
//       } else {
//         return dob;
//       }
//       return DateFormat("dd MMM yyyy").format(parsedDate);
//     } catch (e) {
//       return "Not Available";
//     }
//   }

//   String calculateYearsWorked(String? dateStr) {
//     if (dateStr == null || dateStr.isEmpty) return "-";
//     try {
//       final joiningDate = DateTime.parse(dateStr);
//       final now = DateTime.now();
//       final years = now.difference(joiningDate).inDays ~/ 365;
//       final months = (now.difference(joiningDate).inDays % 365) ~/ 30;
//       if (years == 0 && months == 0) return "Less than a month";
//       if (years == 0) return "$months month${months > 1 ? 's' : ''}";
//       if (months == 0) return "$years year${years > 1 ? 's' : ''}";
//       return "$years year${years > 1 ? 's' : ''}, $months month${months > 1 ? 's' : ''}";
//     } catch (_) {
//       return "-";
//     }
//   }

//   Future<void> _captureImage() async {
//     final picker = ImagePicker();
//     final pickedFile = await picker.pickImage(source: ImageSource.camera);
//     if (pickedFile == null) return;

//     final imageBytes = await pickedFile.readAsBytes();
//     final compressed = await FlutterImageCompress.compressWithList(
//       imageBytes,
//       minWidth: 640,
//       minHeight: 480,
//       quality: 70,
//     );
//     final compressedPath = path.join(
//       path.dirname(pickedFile.path),
//       'compressed_${path.basename(pickedFile.path)}',
//     );
//     await File(compressedPath).writeAsBytes(compressed);

//     setState(() {
//       _image = XFile(compressedPath);
//       imageName = null;
//     });
//   }

//   void _confirmLogout(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text("Logout Confirmation"),
//         content: const Text("Are you sure you want to logout?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(ctx);
//               context.go('/login');
//             },
//             child: const Text("Logout", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget buildProfileSection() {
//     final name = employeeDetails?['employee_name'] ?? 'N/A';
//     final designation = employeeDetails?['designation_name'] ?? 'N/A';
//     final empId = employeeDetails?['zigma_id'] ?? '-';
//     final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).cardColor,
//         borderRadius: BorderRadius.circular(24),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.15),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Stack(
//             alignment: Alignment.bottomRight,
//             children: [
//               CircleAvatar(
//                 radius: 55,
//                 backgroundColor: Colors.green[100],
//                 backgroundImage: _image != null
//                     ? FileImage(File(_image!.path))
//                     : imageName != null
//                     ? NetworkImage('$baseUrl/uploads/$imageName') as ImageProvider
//                     : null,
//                 child: _image == null && imageName == null
//                     ? Text(firstLetter,
//                     style: const TextStyle(
//                         fontSize: 38,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white))
//                     : null,
//               ),
//               GestureDetector(
//                 onTap: _captureImage,
//                 child: CircleAvatar(
//                   radius: 18,
//                   backgroundColor: Colors.green.shade700,
//                   child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(name,
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//           Text(designation,
//               style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
//           Text("ID: $empId", style: const TextStyle(fontSize: 12)),
//           const SizedBox(height: 18),
//           const Divider(),
//           profileItem("Date of Birth", formatDate(employeeDetails?['dob'])),
//           profileItem("Blood Group", employeeDetails?['blood_group']),
//           if (headDetails != null) ...[
//             profileItem("Date of Joining", formatDate(headDetails!['date_of_joining'])),
//             profileItem("Years Worked",
//                 calculateYearsWorked(headDetails!['date_of_joining'])),
//             profileItem("L1 Head", headDetails!['l1_head_name']),
//             profileItem("L2 Head", headDetails!['l2_head_name']),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget profileItem(String title, String? value) => Padding(
//     padding: const EdgeInsets.symmetric(vertical: 6),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Text(title,
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
//         Text(value ?? "N/A",
//             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
//       ],
//     ),
//   );

//   @override
//   Widget build(BuildContext context) {
//     final isDarkMode = Theme.of(context).brightness == Brightness.dark;
//     final Color iconColor = isDarkMode ? Colors.white70 : Colors.black87;

//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text('Profile',
//             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Color(0xFFDFFFE0), Color(0xFF8FCF97)],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : !isDataLoaded
//           ? const Center(child: CircularProgressIndicator())
//           : employeeDetails == null
//           ? const Center(
//           child: Text("No Employee Data Found",
//               style: TextStyle(fontSize: 16)))
//           : SingleChildScrollView(
//         padding: const EdgeInsets.only(bottom: 80),
//         child: Column(
//           children: [buildProfileSection()],
//         ),
//       ),

//       // ✅ Bottom Navigation Bar with adaptive colors
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: isDarkMode
//                 ? [Colors.grey.shade900, Colors.black]
//                 : [const Color(0xFFDFFFE0), const Color(0xFF8FCF97)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 6,
//               offset: const Offset(0, -2),
//             ),
//           ],
//         ),
//         child: BottomAppBar(
//           color: Colors.transparent,
//           elevation: 0,
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 // 🌙 Dark Mode toggle
//                 IconButton(
//                   icon: Icon(
//                     isDarkMode ? Icons.dark_mode : Icons.light_mode,
//                     color: iconColor,
//                     size: 26,
//                   ),
//                   onPressed: () {
//                     context.read<ThemeProvider>().toggleTheme(!isDarkMode);
//                   },
//                   tooltip: isDarkMode ? "Light Mode" : "Dark Mode",
//                 ),

//                 // 🚪 Logout
//                 IconButton(
//                   icon: Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 26),
//                   tooltip: "Logout",
//                   onPressed: () => _confirmLogout(context),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
