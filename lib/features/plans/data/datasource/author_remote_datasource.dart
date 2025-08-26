import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/author_model.dart';

class AuthorRemoteDatasource {
  final http.Client client;
  final String baseUrl =
      'https://your-api-base-url.com'; // Replace with your actual API URL

  AuthorRemoteDatasource({required this.client});

  Future<List<AuthorModel>> getAuthors() async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/authors'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => AuthorModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load authors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load authors: $e');
    }
  }

  Future<AuthorModel> getAuthorById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/authors/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AuthorModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load author: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load author: $e');
    }
  }

  Future<AuthorModel> createAuthor(AuthorModel author) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/authors'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(author.toJson()),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return AuthorModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to create author: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create author: $e');
    }
  }

  Future<AuthorModel> updateAuthor(String id, AuthorModel author) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/authors/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(author.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return AuthorModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to update author: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update author: $e');
    }
  }

  Future<void> deleteAuthor(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/authors/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete author: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete author: $e');
    }
  }
}
