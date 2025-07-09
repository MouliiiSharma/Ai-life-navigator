import 'dart:convert';
import 'package:http/http.dart' as http;

class YouTubeService {
  final String apiKey;
  final String _baseUrl = "https://www.googleapis.com/youtube/v3/search";

  YouTubeService({required this.apiKey});

  Future<List<Map<String, String>>> searchVideos(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?part=snippet&q=$query&type=video&key=$apiKey&maxResults=3'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, String>> videos = [];
        for (var item in data['items']) {
          videos.add({
            'title': item['snippet']['title'],
            'url': 'https://www.youtube.com/watch?v=${item['id']['videoId']}',
          });
        }
        return videos;
      } else {
        print("Failed to load YouTube videos: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error searching YouTube videos: $e");
      return [];
    }
  }
}
