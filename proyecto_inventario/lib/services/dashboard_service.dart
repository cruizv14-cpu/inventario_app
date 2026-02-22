import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  final String baseUrl = "http://127.0.0.1:8000";

  Future<List<dynamic>> fetchProductosMasVendidos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/productos-mas-vendidos'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching productos mas vendidos: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchClientesTop() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/clientes-top'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching clientes top: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchProveedoresTop() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/proveedores-top'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching proveedores top: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchVentasPorComuna() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/ventas-por-comuna'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching ventas por comuna: $e');
      return [];
    }
  }

  Future<List<dynamic>> fetchMargenesProductos() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/dashboard/margenes-productos'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return [];
    } catch (e) {
      print('Error fetching margenes productos: $e');
      return [];
    }
  }
}