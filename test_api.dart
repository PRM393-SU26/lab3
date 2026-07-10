import 'dart:convert';
import 'dart:io';

void main() async {
  final urlStr = 'https://api.openalex.org/works?group_by=primary_location.source.id&per_page=10';
  print('Testing: $urlStr');
  final url = Uri.parse(urlStr);
  final request = await HttpClient().getUrl(url);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print('Status: ${response.statusCode}');
  print('Body: ${responseBody.substring(0, responseBody.length > 300 ? 300 : responseBody.length)}...');
}
