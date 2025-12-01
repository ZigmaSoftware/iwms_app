import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ProfilePage extends StatefulWidget {
  final String empId;

  const ProfilePage({super.key, required this.empId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  bool isRegistered = false;
  Map<String, dynamic>? profileData;

  XFile? _image;
  String? imageName;
  bool isSubmitting = false;

  final String baseUrl = "http://10.64.151.226:8000";

  // Editable fields
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController deptCtrl = TextEditingController();
  final TextEditingController desigCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();
  final TextEditingController bloodCtrl = TextEditingController();
  final TextEditingController dojCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  // ------------------------------------------------------------------
  // FETCH PROFILE
  // ------------------------------------------------------------------
  Future<void> _fetchProfile() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/api/mobile/staff-profile/?staff_id_id=${widget.empId}"),
      );

      final jsonRes = jsonDecode(res.body);

      if (jsonRes["status"] == "success") {
        final data = jsonRes["data"];

        setState(() {
          isRegistered = true;
          profileData = data;

          nameCtrl.text = data["employee_name"] ?? "";
          deptCtrl.text = data["department"] ?? "";
          desigCtrl.text = data["designation"] ?? "";
          dobCtrl.text = data["personal"]?["dob"] ?? "";
          bloodCtrl.text = data["personal"]?["blood_group"] ?? "";
          dojCtrl.text = data["doj"] ?? "";

          // Photo name from Django
          imageName = data["photo"];
        });
      } else {
        setState(() => isRegistered = false);
      }
    } catch (e) {
      setState(() => isRegistered = false);
    }

    setState(() => isLoading = false);
  }

  // ------------------------------------------------------------------
  // REGISTER EMPLOYEE
  // ------------------------------------------------------------------
  // Future<void> registerEmployee() async {
  //   if (_image == null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Please capture an image to register.")),
  //     );
  //     return;
  //   }

  //   setState(() => isSubmitting = true);

  //   final url = Uri.parse("$baseUrl/api/mobile/register/");
  //   final req = http.MultipartRequest("POST", url);

  //   req.fields["emp_id"] = widget.empId;
  //   req.fields["name"] = nameCtrl.text.isEmpty ? "Unknown" : nameCtrl.text;
  //   req.fields["department"] = deptCtrl.text;
  //   req.fields["designation"] = desigCtrl.text;

  //   req.files.add(await http.MultipartFile.fromPath("image", _image!.path));

  //   final response = await req.send();
  //   final data = jsonDecode(await response.stream.bytesToString());

  //   if (data["message"] == "Employee registered successfully") {
  //     setState(() {
  //       isRegistered = true;
  //       imageName = data["image"];
  //     });

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Registration successful")),
  //     );
  //     _fetchProfile();
  //   }

  //   setState(() => isSubmitting = false);
  // }
Future<void> registerEmployee() async {
  if (_image == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please capture an image to register.")),
    );
    return;
  }

  setState(() => isSubmitting = true);

  try {
    final url = Uri.parse("$baseUrl/api/mobile/register/");
    final req = http.MultipartRequest("POST", url);

    req.fields["emp_id"] = widget.empId;
    req.fields["name"] = nameCtrl.text.isEmpty ? "Unknown" : nameCtrl.text;
    req.fields["department"] = deptCtrl.text.isEmpty ? "Unknown" : deptCtrl.text;
    req.fields["dob"] = dobCtrl.text;
    req.fields["bllod_group"] = bloodCtrl.text;

    // File attachment
    req.files.add(await http.MultipartFile.fromPath(
      "source_image",
      _image!.path,
      filename: path.basename(_image!.path),
    ));

    final response = await req.send();
    final responseBody = await response.stream.bytesToString();

    print("REGISTER STATUS: ${response.statusCode}");
    print("REGISTER RESPONSE: $responseBody");

    final data = jsonDecode(responseBody);

    if (response.statusCode == 200 &&
        data["message"] == "Employee registered successfully") {
      setState(() {
        isRegistered = true;
        imageName = data["image"];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration successful")),
      );

      _fetchProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration failed: ${data["message"]}")),
      );
    }
  } catch (e) {
    print("REGISTER ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }

  setState(() => isSubmitting = false);
}

  // ------------------------------------------------------------------
  // CAPTURE IMAGE
  // ------------------------------------------------------------------
  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 640,
      minHeight: 480,
      quality: 70,
    );

    final compressedPath = path.join(
      path.dirname(picked.path),
      "cmp_${path.basename(picked.path)}",
    );

    await File(compressedPath).writeAsBytes(compressed);

    setState(() {
      _image = XFile(compressedPath);
      imageName = null; // force UI to refresh
    });
  }

  // ------------------------------------------------------------------
  // UPDATE PROFILE
  // ------------------------------------------------------------------
  Future<void> updateProfile() async {
  final url = Uri.parse(
      "$baseUrl/api/mobile/staff-profile/${widget.empId}/");

  final req = http.MultipartRequest("PUT", url);

  req.fields["employee_name"] = nameCtrl.text;
  req.fields["department"] = deptCtrl.text;
  req.fields["designation"] = desigCtrl.text;
  req.fields["dob"] = dobCtrl.text;
  req.fields["blood_group"] = bloodCtrl.text;

  if (_image != null) {
    req.files.add(await http.MultipartFile.fromPath("photo", _image!.path));
  }

  final res = await req.send();
  final responseData = jsonDecode(await res.stream.bytesToString());

  if (responseData["status"] == "success") {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile updated successfully")),
    );
    _fetchProfile();
  } else {
    print("Update failed: $responseData");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Update failed: ${responseData["message"]}")),
    );
  }
}

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Image provider logic
    ImageProvider<Object>? profileImage;

    if (isRegistered) {
      if (_image != null) {
        profileImage = FileImage(File(_image!.path));
      } else if (imageName != null) {
        profileImage = NetworkImage("$baseUrl/media/$imageName");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold)),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            //----------------------------
            // PROFILE IMAGE
            //----------------------------
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (!isRegistered) registerEmployee();
                    },
                    child: CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.green[100],
                      backgroundImage: profileImage,
                      child: profileImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, size: 40, color: Colors.green),
                                SizedBox(height: 6),
                                Text(
                                  isRegistered ? "No Image" : "Register",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            )
                          : null,
                    ),
                  ),

                  if (isRegistered)
                    GestureDetector(
                      onTap: _captureImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    )
                ],
              ),
            ),

            SizedBox(height: 20),

            //----------------------------
            // FIELDS
            //----------------------------
            _field("Name", nameCtrl),
            _field("Department", deptCtrl),
            _field("Designation", desigCtrl),
            // _field("Date of Birth", dobCtrl),
            _dateField("Date of Birth", dobCtrl),

            _field("Blood Group", bloodCtrl),
            _field("Date of Joining", dojCtrl, enabled: false),

            SizedBox(height: 20),

            //----------------------------
            // UPDATE BUTTON
            //----------------------------
            ElevatedButton(
              onPressed: registerEmployee,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("Update Profile",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
Widget _dateField(String label, TextEditingController ctrl) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: ctrl,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_month),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1970),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          ctrl.text = DateFormat('yyyy-MM-dd').format(picked); // FIXED FORMAT
        }
      },
    ),
  );
}

  Widget _field(String label, TextEditingController ctrl,
      {bool enabled = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
