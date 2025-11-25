import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fetchImageName(String empId) async {
  try {
    final response = await http.get(
      Uri.parse('http://zigfly.in:5000/get_image?emp_id=$empId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image_name']; // Return the image name
    } else if (response.statusCode == 404) {
      throw Exception('No image found for emp_id $empId');
    } else {
      throw Exception('Failed to fetch image. Status: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error: $e');
  }
}
