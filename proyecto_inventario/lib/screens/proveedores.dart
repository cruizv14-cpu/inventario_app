// lib/screens/proveedores.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../utils/comunas.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  List proveedores = [];
  List proveedoresFiltrados = [];
  bool loading = true;

  final String apiUrl = "http://127.0.0.1:8000/proveedores";

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();
  final TextEditingController direccionCtrl = TextEditingController();
  final TextEditingController rutCtrl = TextEditingController();
  final TextEditingController buscarCtrl = TextEditingController();

  String? comunaSeleccionada;

  @override
  void initState() {
    super.initState();
    fetchProveedores();
  }

  Future<void> fetchProveedores() async {
    setState(() => loading = true);
    try {
      final resp = await http.get(Uri.parse(apiUrl));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          proveedores = data;
          proveedoresFiltrados = data;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar proveedores: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void filtrarProveedores(String query) {
    final texto = query.toLowerCase();
    setState(() {
      proveedoresFiltrados = proveedores.where((p) {
        final nombre = (p["nombre"] ?? "").toLowerCase();
        final rut = (p["rut"] ?? "").toLowerCase();
        final comuna = (p["comuna"] ?? "").toLowerCase();
        return nombre.contains(texto) || rut.contains(texto) || comuna.contains(texto);
      }).toList();
    });
  }


  Future<void> createProveedor() async {
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
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await fetchProveedores();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al crear proveedor: $e");
    }
  }

  Future<void> updateProveedor(int id) async {
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
        await fetchProveedores();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al actualizar proveedor: $e");
    }
  }

  Future<void> deleteProveedor(int id) async {
    try {
      final resp = await http.delete(Uri.parse("$apiUrl/$id"));
      if (resp.statusCode == 200) {
        fetchProveedores();
      }
    } catch (e) {
      debugPrint("Error al eliminar proveedor: $e");
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
        title: const Text("Agregar Proveedor"),
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
          ElevatedButton(onPressed: createProveedor, child: const Text("Guardar")),
        ],
      ),
    );
  }

  void openEditDialog(Map proveedor) {
    nombreCtrl.text = proveedor["nombre"] ?? "";
    telefonoCtrl.text = proveedor["telefono"] ?? "";
    direccionCtrl.text = proveedor["direccion"] ?? "";
    rutCtrl.text = proveedor["rut"] ?? "";
    comunaSeleccionada = proveedor["comuna"];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Proveedor"),
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
          ElevatedButton(
            onPressed: () => updateProveedor(proveedor["id_proveedor"]),
            child: const Text("Actualizar"),
          ),
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
              onChanged: filtrarProveedores,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : proveedoresFiltrados.isEmpty
                  ? const Center(child: Text("No hay proveedores 😕"))
                  : ListView.builder(
                itemCount: proveedoresFiltrados.length,
                itemBuilder: (context, index) {
                  final proveedor = proveedoresFiltrados[index];
                  return Card(
                    child: ListTile(
                      title: Text(proveedor["nombre"] ?? ""),
                      subtitle: Text(
                        "RUT: ${proveedor["rut"] ?? "-"}\n"
                            "Comuna: ${proveedor["comuna"] ?? "-"}\n"
                            "Tel: ${proveedor["telefono"] ?? "-"}\n"
                            "Dirección: ${proveedor["direccion"] ?? "-"}",
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openEditDialog(proveedor),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteProveedor(proveedor["id_proveedor"]),
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
