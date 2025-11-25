import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://125.17.238.158:5000'; // Replace with your Flask server URL

  Future<Map<String, dynamic>?> getEmployeeDetails(String empId) async {
    try {
      // Check if the empId is purely numeric and longer than 3 digits
      if (empId.isNotEmpty && empId.length > 3 && int.tryParse(empId) != null) {
        // Directly use empId if it's a valid numeric ID with more than 3 digits
      } else {
        // Ensure empId is 3 digits long, padding with leading zeros if necessary
        empId = empId.padLeft(3, '0');
        // Prepend "ZGESPL/" if it's not already present

      }

      // Construct the request URL
      final requestUrl = '$baseUrl/get_user_server1/$empId';

      // Print the request URL
      print('Request URL: $requestUrl');

      // Perform the HTTP GET request
      final response = await http.get(Uri.parse(requestUrl));

      print('Response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        print('User not found');
        return null;
      } else {
        print('Error fetching employee details: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error fetching employee details: $e');
      return null;
    }
  }
}
