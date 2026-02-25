// lib/screens/proveedores.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../utils/comunas.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class ProveedoresPage extends StatefulWidget {
  const ProveedoresPage({super.key});

  @override
  State<ProveedoresPage> createState() => _ProveedoresPageState();
}

class _ProveedoresPageState extends State<ProveedoresPage> {
  List proveedores = [];
  List proveedoresFiltrados = [];
  bool loading = true;

  final String apiUrl = "$apiBaseUrl/proveedores";
  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final rutCtrl = TextEditingController();
  final buscarCtrl = TextEditingController();
  String? comunaSeleccionada;

  @override
  void initState() { super.initState(); fetchProveedores(); }

  Future<void> fetchProveedores() async {
    setState(() => loading = true);
    try {
      final resp = await http.get(Uri.parse(apiUrl));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() { proveedores = data; proveedoresFiltrados = data; });
      }
    } catch (e) { debugPrint("Error al cargar proveedores: $e"); }
    finally { setState(() => loading = false); }
  }

  void filtrarProveedores(String q) {
    final t = q.toLowerCase();
    setState(() { proveedoresFiltrados = proveedores.where((p) =>
      (p["nombre"] ?? "").toLowerCase().contains(t) ||
      (p["rut"] ?? "").toLowerCase().contains(t) ||
      (p["comuna"] ?? "").toLowerCase().contains(t)).toList(); });
  }

  Future<void> createProveedor() async {
    final data = {"nombre": nombreCtrl.text, "telefono": telefonoCtrl.text,
      "direccion": direccionCtrl.text, "rut": rutCtrl.text,
      "comuna": comunaSeleccionada ?? "Fuera de Santiago"};
    final resp = await http.post(Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"}, body: json.encode(data));
    if (resp.statusCode == 200 || resp.statusCode == 201) {
      await fetchProveedores(); if (mounted) Navigator.pop(context);
    }
  }

  Future<void> updateProveedor(int id) async {
    final data = {"nombre": nombreCtrl.text, "telefono": telefonoCtrl.text,
      "direccion": direccionCtrl.text, "rut": rutCtrl.text,
      "comuna": comunaSeleccionada ?? "Fuera de Santiago"};
    final resp = await http.put(Uri.parse("$apiUrl/$id"),
      headers: {"Content-Type": "application/json"}, body: json.encode(data));
    if (resp.statusCode == 200) {
      await fetchProveedores(); if (mounted) Navigator.pop(context);
    }
  }

  Future<void> deleteProveedor(int id) async {
    final resp = await http.delete(Uri.parse("$apiUrl/$id"));
    if (resp.statusCode == 200) fetchProveedores();
  }

  void openFormDialog({Map? proveedor}) {
    if (proveedor != null) {
      nombreCtrl.text = proveedor["nombre"] ?? ""; telefonoCtrl.text = proveedor["telefono"] ?? "";
      direccionCtrl.text = proveedor["direccion"] ?? ""; rutCtrl.text = proveedor["rut"] ?? "";
      comunaSeleccionada = proveedor["comuna"];
    } else {
      nombreCtrl.clear(); telefonoCtrl.clear(); direccionCtrl.clear(); rutCtrl.clear();
      comunaSeleccionada = null;
    }
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        title: Text(proveedor != null ? "Editar Proveedor" : "Agregar Proveedor"),
        content: SizedBox(width: 400, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder())),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: rutCtrl, decoration: const InputDecoration(labelText: "RUT", border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: "Teléfono", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 8),
            TextField(controller: direccionCtrl, decoration: const InputDecoration(labelText: "Dirección", border: OutlineInputBorder())),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: comunaSeleccionada,
              decoration: const InputDecoration(labelText: "Comuna", border: OutlineInputBorder()),
              items: comunasRM.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setS(() => comunaSeleccionada = v),
            ),
          ],
        ))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: proveedor != null ? () => updateProveedor(proveedor["id_proveedor"]) : createProveedor,
            child: Text(proveedor != null ? "Actualizar" : "Guardar"),
          ),
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Scaffold(
      appBar: AppHeader(parentContext: context),
      drawer: mobile ? AppDrawer(parentContext: context) : null,
      floatingActionButton: FloatingActionButton(
        onPressed: () => openFormDialog(), backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(mobile ? 10 : 16),
        child: Column(children: [
          TextField(
            controller: buscarCtrl,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search),
              hintText: "Buscar por nombre, RUT o comuna...",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onChanged: filtrarProveedores,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading ? const Center(child: CircularProgressIndicator())
              : proveedoresFiltrados.isEmpty
                ? const Center(child: Text("No hay proveedores 😕", style: TextStyle(fontSize: 16)))
                : mobile ? _buildMobileList() : _buildDesktopTable(),
          ),
        ]),
      ),
    );
  }

  Widget _buildMobileList() => ListView.builder(
    itemCount: proveedoresFiltrados.length,
    itemBuilder: (context, i) {
      final p = proveedoresFiltrados[i];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(p["nombre"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("RUT: ${p["rut"] ?? "-"}  |  Tel: ${p["telefono"] ?? "-"}\nComuna: ${p["comuna"] ?? "-"}"),
          isThreeLine: true,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => openFormDialog(proveedor: p)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteProveedor(p["id_proveedor"])),
          ]),
        ),
      );
    },
  );

  Widget _buildDesktopTable() => SingleChildScrollView(
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
        columns: const [
          DataColumn(label: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("RUT", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Teléfono", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Dirección", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Comuna", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: proveedoresFiltrados.map<DataRow>((p) => DataRow(cells: [
          DataCell(Text(p["nombre"] ?? "")),
          DataCell(Text(p["rut"] ?? "-")),
          DataCell(Text(p["telefono"] ?? "-")),
          DataCell(Text(p["direccion"] ?? "-")),
          DataCell(Text(p["comuna"] ?? "-")),
          DataCell(Row(children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => openFormDialog(proveedor: p)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => deleteProveedor(p["id_proveedor"])),
          ])),
        ])).toList(),
      ),
    ),
  );
}
