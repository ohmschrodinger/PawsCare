import 'dart:convert';
import 'package:http/http.dart' as http;

class CatFactsService {
  // Cat Facts API
  static const String _catFactsApiUrl = 'https://catfact.ninja/fact';

  // The Cat API for cat images
  static const String _catImageApiUrl =
      'https://api.thecatapi.com/v1/images/search';

  /// Fetch a random cat fact
  static Future<String> getCatFact() async {
    try {
      final response = await http.get(Uri.parse(_catFactsApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['fact'] ?? 'No fact available';
      } else {
        throw Exception('Failed to load cat fact');
      }
    } catch (e) {
      print('Error fetching cat fact: $e');
      throw Exception('Failed to load cat fact');
    }
  }

  /// Fetch a random cat image URL
  static Future<String> getCatImage() async {
    try {
      final response = await http.get(Uri.parse(_catImageApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          return data[0]['url'] ?? 'https://via.placeholder.com/400';
        }
        return 'https://via.placeholder.com/400';
      } else {
        throw Exception('Failed to load cat image');
      }
    } catch (e) {
      print('Error fetching cat image: $e');
      throw Exception('Failed to load cat image');
    }
  }

  /// Fetch both cat fact and image together
  static Future<Map<String, String>> getCatFactAndImage() async {
    // Use Future.wait to fetch both pieces of data concurrently
    final results = await Future.wait([
      getCatFact(),
      getCatImage(),
    ]);

    return {'fact': results[0], 'imageUrl': results[1]};
  }
}