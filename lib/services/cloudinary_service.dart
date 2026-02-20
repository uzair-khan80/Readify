import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  final String cloudName = 'dktzyrqss';
  final String uploadPreset = 'readify_preset';

  Future<String?> uploadImage(XFile pickedFile) async {
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    try {
      // Web + Mobile both ke liye support
      Uint8List fileBytes = await pickedFile.readAsBytes();

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            fileBytes,
            filename: pickedFile.name,
          ),
        );

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);
      final Map<String, dynamic> responseData = json.decode(responseBody.body);

      if (response.statusCode == 200 && responseData['secure_url'] != null) {
        return responseData['secure_url'];
      } else {
        print("❌ Upload failed: ${responseData['error']?['message']}");
        return null;
      }
    } catch (e) {
      print("🔥 Error uploading image: $e");
      return null;
    }
  }
}
