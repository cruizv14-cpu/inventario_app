import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static const String _tokenKey = "jwt_token";

  // Login y obtención de token
  static Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username,
          "password": password
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        
        // Guardar en shared_preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        return true;
      }
      return false;
    } catch (e) {
      print("Error en login: $e");
      return false;
    }
  }

  // Comprobar si existe un token
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  // Cerrar sesión
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
