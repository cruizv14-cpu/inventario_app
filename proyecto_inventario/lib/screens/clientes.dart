// lib/screens/clientes.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../utils/comunas.dart';
import '../utils/constants.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  List clientes = [];
  List clientesFiltrados = [];
  bool loading = true;

  final String apiUrl = "$apiBaseUrl/clientes";

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController rutCtrl = TextEditingController();

  String? comunaSeleccionada;
  final TextEditingController buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchClientes();
  }

  Future<void> fetchClientes() async {
    setState(() => loading = true);
    try {
      final resp = await http.get(Uri.parse(apiUrl));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          clientes = data;
          clientesFiltrados = data;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar clientes: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void filtrarClientes(String query) {
    final texto = query.toLowerCase();
    setState(() {
      clientesFiltrados = clientes.where((c) {
        final nombre = (c["nombre"] ?? "").toLowerCase();
        final rut = (c["rut"] ?? "").toLowerCase();
        final comuna = (c["comuna"] ?? "").toLowerCase();
        return nombre.contains(texto) || rut.contains(texto) || comuna.contains(texto);
      }).toList();
    });
  }

  Future<void> createCliente() async {
    final data = {
      "nombre": nombreCtrl.text,
      "telefono": telefonoCtrl.text,
      "direccion": direccionCtrl.text,
      "rut": rutCtrl.text,
      "comuna": comunaSeleccionada ?? "Fuera de Santiago",
    };
    try {
      final resp = await http.post(Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data));
      if (resp.statusCode == 201) {
        await fetchClientes();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al crear cliente: $e");
    }
  }

  Future<void> updateCliente(int id) async {
    final data = {
      "nombre": nombreCtrl.text,
      "telefono": telefonoCtrl.text,
      "direccion": direccionCtrl.text,
      "rut": rutCtrl.text,
      "comuna": comunaSeleccionada ?? "Fuera de Santiago",
    };
    try {
      final resp = await http.put(Uri.parse("$apiUrl/$id"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data));
      if (resp.statusCode == 200) {
        await fetchClientes();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al actualizar cliente: $e");
    }
  }

  Future<void> deleteCliente(int id) async {
    try {
      final resp = await http.delete(Uri.parse("$apiUrl/$id"));
      if (resp.statusCode == 200) {
        fetchClientes();
      }
    } catch (e) {
      debugPrint("Error al eliminar cliente: $e");
    }
  }

  void openCreateDialog() {
    nombreCtrl.clear();
    telefonoCtrl.clear();
    direccionCtrl.clear();
    rutCtrl.clear();
    comunaSeleccionada = null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar Cliente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: "Teléfono")),
              TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: "Dirección")),
              TextField(controller: rutCtrl, decoration: const InputDecoration(labelText: "RUT")),
              DropdownButtonFormField<String>(
                value: comunaSeleccionada,
                items: comunasRM.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => comunaSeleccionada = v),
                decoration: const InputDecoration(labelText: "Comuna"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: createCliente, child: const Text("Guardar")),
        ],
      ),
    );
  }

  void openEditDialog(Map cliente) {
    nombreCtrl.text = cliente["nombre"] ?? "";
    telefonoCtrl.text = cliente["telefono"] ?? "";
    direccionCtrl.text = cliente["direccion"] ?? "";
    rutCtrl.text = cliente["rut"] ?? "";
    comunaSeleccionada = cliente["comuna"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Cliente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: "Teléfono")),
              TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: "Dirección")),
              TextField(controller: rutCtrl, decoration: const InputDecoration(labelText: "RUT")),
              DropdownButtonFormField<String>(
                value: comunaSeleccionada,
                items: comunasRM.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => comunaSeleccionada = v),
                decoration: const InputDecoration(labelText: "Comuna"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: () => updateCliente(cliente["id_cliente"]), child: const Text("Actualizar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(parentContext: context),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 Barra de búsqueda
            TextField(
              controller: buscarCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Buscar por nombre o RUT...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: filtrarClientes,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : clientesFiltrados.isEmpty
                  ? const Center(child: Text("No hay clientes 😕"))
                  : ListView.builder(
                itemCount: clientesFiltrados.length,
                itemBuilder: (context, index) {
                  final cliente = clientesFiltrados[index];
                  return Card(
                    child: ListTile(
                      title: Text(cliente["nombre"] ?? ""),
                      subtitle: Text(
                        "RUT: ${cliente["rut"] ?? "-"}\n"
                            "Comuna: ${cliente["comuna"] ?? "-"}\n"
                            "Tel: ${cliente["telefono"] ?? "-"}\n"
                            "Dirección: ${cliente["direccion"] ?? "-"}",
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openEditDialog(cliente),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCliente(cliente["id_cliente"]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
