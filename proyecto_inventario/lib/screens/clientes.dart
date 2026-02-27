// lib/screens/clientes.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../utils/comunas.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

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
  final nombreCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();
  final rutCtrl = TextEditingController();
  final buscarCtrl = TextEditingController();
  String? comunaSeleccionada;

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
        setState(() { clientes = data; clientesFiltrados = data; });
      }
    } catch (e) {
      debugPrint("Error al cargar clientes: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void filtrarClientes(String query) {
    final t = query.toLowerCase();
    setState(() {
      clientesFiltrados = clientes.where((c) =>
        (c["nombre"] ?? "").toLowerCase().contains(t) ||
        (c["rut"] ?? "").toLowerCase().contains(t) ||
        (c["comuna"] ?? "").toLowerCase().contains(t)).toList();
    });
  }

  Future<void> createCliente() async {
    final data = {"nombre": nombreCtrl.text, "telefono": telefonoCtrl.text,
      "direccion": direccionCtrl.text, "rut": rutCtrl.text,
      "comuna": comunaSeleccionada ?? "Fuera de Santiago"};
    final resp = await http.post(Uri.parse(apiUrl),
      headers: {"Content-Type": "application/json"}, body: json.encode(data));
    if (resp.statusCode == 201) { await fetchClientes(); if (mounted) Navigator.pop(context); }
  }

  Future<void> updateCliente(int id) async {
    final data = {"nombre": nombreCtrl.text, "telefono": telefonoCtrl.text,
      "direccion": direccionCtrl.text, "rut": rutCtrl.text,
      "comuna": comunaSeleccionada ?? "Fuera de Santiago"};
    final resp = await http.put(Uri.parse("$apiUrl/$id"),
      headers: {"Content-Type": "application/json"}, body: json.encode(data));
    if (resp.statusCode == 200) { await fetchClientes(); if (mounted) Navigator.pop(context); }
  }

  Future<void> deleteCliente(int id) async {
    final resp = await http.delete(Uri.parse("$apiUrl/$id"));
    if (resp.statusCode == 200) fetchClientes();
  }

  void openFormDialog({Map? cliente}) {
    if (cliente != null) {
      nombreCtrl.text = cliente["nombre"] ?? ""; telefonoCtrl.text = cliente["telefono"] ?? "";
      direccionCtrl.text = cliente["direccion"] ?? ""; rutCtrl.text = cliente["rut"] ?? "";
      comunaSeleccionada = cliente["comuna"];
    } else {
      nombreCtrl.clear(); telefonoCtrl.clear(); direccionCtrl.clear(); rutCtrl.clear();
      comunaSeleccionada = null;
    }
    
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
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
              Icon(cliente != null ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                cliente != null ? "Editar Cliente" : "Agregar Cliente",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
                        labelText: "Nombre Completo *",
                        prefixIcon: const Icon(Icons.person_outline),
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
            icon: Icon(cliente != null ? Icons.save : Icons.add_circle_outline),
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                cliente != null ? updateCliente(cliente["id_cliente"]) : createCliente();
              }
            },
            label: Text(cliente != null ? "Actualizar" : "Guardar"),
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
        onPressed: () => openFormDialog(),
        backgroundColor: Colors.deepPurple,
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
            onChanged: filtrarClientes,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loading
              ? const Center(child: CircularProgressIndicator())
              : clientesFiltrados.isEmpty
                ? const Center(child: Text("No hay clientes 😕", style: TextStyle(fontSize: 16)))
                : mobile ? _buildMobileList() : _buildDesktopTable(),
          ),
        ]),
      ),
    );
  }

  Widget _buildMobileList() => ListView.builder(
    itemCount: clientesFiltrados.length,
    itemBuilder: (context, i) {
      final c = clientesFiltrados[i];
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(c["nombre"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("RUT: ${c["rut"] ?? "-"}  |  Tel: ${c["telefono"] ?? "-"}\nComuna: ${c["comuna"] ?? "-"}"),
          isThreeLine: true,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => openFormDialog(cliente: c)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteCliente(c["id_cliente"])),
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
        rows: clientesFiltrados.map<DataRow>((c) => DataRow(cells: [
          DataCell(Text(c["nombre"] ?? "")),
          DataCell(Text(c["rut"] ?? "-")),
          DataCell(Text(c["telefono"] ?? "-")),
          DataCell(Text(c["direccion"] ?? "-")),
          DataCell(Text(c["comuna"] ?? "-")),
          DataCell(Row(children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => openFormDialog(cliente: c)),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => deleteCliente(c["id_cliente"])),
          ])),
        ])).toList(),
      ),
    ),
  );
}
