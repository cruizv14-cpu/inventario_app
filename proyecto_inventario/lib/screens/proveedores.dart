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
    
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: const BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(proveedor != null ? Icons.business_outlined : Icons.add_business_outlined, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                proveedor != null ? "Editar Proveedor" : "Nuevo Proveedor",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nombreCtrl, 
                      decoration: InputDecoration(
                        labelText: "Nombre del Proveedor *",
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: rutCtrl,
                          decoration: InputDecoration(
                            labelText: "RUT",
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: telefonoCtrl,
                          decoration: InputDecoration(
                            labelText: "Teléfono",
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: direccionCtrl,
                      decoration: InputDecoration(
                        labelText: "Dirección",
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: comunaSeleccionada,
                      decoration: InputDecoration(
                        labelText: "Comuna",
                        prefixIcon: const Icon(Icons.map_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      items: comunasRM.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setS(() => comunaSeleccionada = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: Icon(proveedor != null ? Icons.save : Icons.add_circle_outline),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                proveedor != null ? updateProveedor(proveedor["id_proveedor"]) : createProveedor();
              }
            },
            label: Text(proveedor != null ? "Actualizar" : "Guardar"),
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

  Widget _buildDesktopTable() => SizedBox(
    width: double.infinity,
    child: SingleChildScrollView(
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
        columnSpacing: 32,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Expanded(child: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("RUT", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Teléfono", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Dirección", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Comuna", style: TextStyle(fontWeight: FontWeight.bold)))),
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
