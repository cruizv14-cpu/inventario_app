// lib/screens/mermas.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/app_header.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class MermasPage extends StatefulWidget {
  const MermasPage({super.key});

  @override
  State<MermasPage> createState() => _MermasPageState();
}

class _MermasPageState extends State<MermasPage> {
  final String baseUrl = apiBaseUrl;
  List<Map<String, dynamic>> mermas = [];
  List<Map<String, dynamic>> mermasFiltradas = [];
  List<Map<String, dynamic>> productos = [];
  bool loading = true;

  // Filtros
  DateTime? fechaDesde;
  DateTime? fechaHasta;

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    await Future.wait([fetchMermas(), fetchProductos()]);
    setState(() {
      mermasFiltradas = List<Map<String, dynamic>>.from(mermas);
      loading = false;
    });
  }

  Future<void> fetchMermas() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/mermas"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        setState(() {
          mermas = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });

        debugPrint("=== MERMAS CARGADAS ===");
        for (var m in mermas) {
          debugPrint("Merma ID: ${m['id_merma']}, Fecha: ${m['fecha']}, Producto: ${m['producto']}");
        }

        // Aplicar filtros automáticamente después de cargar
        aplicarFiltros();
      }
    } catch (e) {
      debugPrint("Error cargando mermas: $e");
    }
  }

  Future<void> fetchProductos() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/productos"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        productos = data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint("Error cargando productos: $e");
    }
  }

  void aplicarFiltros() {
    debugPrint("=== APLICANDO FILTROS MERMAS ===");
    debugPrint("Fecha desde: $fechaDesde");
    debugPrint("Fecha hasta: $fechaHasta");

    setState(() {
      mermasFiltradas = mermas.where((m) {
        bool pasaFiltro = true;

        // Filtro por fecha
        final fechaStr = m['fecha']?.toString();
        if (fechaStr != null) {
          final DateTime? fechaRegistro = DateTime.tryParse(fechaStr);
          if (fechaRegistro != null) {
            final fechaRegistroNormalizada = DateTime(fechaRegistro.year, fechaRegistro.month, fechaRegistro.day);
            final fechaDesdeNormalizada = fechaDesde != null
                ? DateTime(fechaDesde!.year, fechaDesde!.month, fechaDesde!.day)
                : null;
            final fechaHastaNormalizada = fechaHasta != null
                ? DateTime(fechaHasta!.year, fechaHasta!.month, fechaHasta!.day)
                : null;

            if (fechaDesdeNormalizada != null && fechaRegistroNormalizada.isBefore(fechaDesdeNormalizada)) {
              debugPrint("Merma ${m['id_merma']} filtrada por fecha desde");
              pasaFiltro = false;
            }

            if (pasaFiltro && fechaHastaNormalizada != null && fechaRegistroNormalizada.isAfter(fechaHastaNormalizada)) {
              debugPrint("Merma ${m['id_merma']} filtrada por fecha hasta");
              pasaFiltro = false;
            }
          } else {
            pasaFiltro = false;
          }
        } else {
          pasaFiltro = false;
        }

        if (pasaFiltro) {
          debugPrint("Merma ${m['id_merma']} PASÓ todos los filtros - Fecha: '${m['fecha']}'");
        }

        return pasaFiltro;
      }).toList();
    });

    debugPrint("=== RESULTADO FILTRADO MERMAS ===");
    debugPrint("Mermas filtradas: ${mermasFiltradas.length}");
    for (var m in mermasFiltradas) {
      debugPrint("Merma ID: ${m['id_merma']}, Fecha: ${m['fecha']}, Producto: ${m['producto']}");
    }
  }

  void limpiarFiltros() {
    setState(() {
      fechaDesde = null;
      fechaHasta = null;
      mermasFiltradas = List<Map<String, dynamic>>.from(mermas);
    });
    debugPrint("=== FILTROS MERMAS LIMPIADOS ===");
  }

  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (_) {
      return fechaStr;
    }
  }

  String formatDate(DateTime d) {
    return DateFormat('dd/MM/yyyy').format(d);
  }

  Future<void> pickDesde() async {
    final now = DateTime.now();
    final initial = fechaDesde ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => fechaDesde = picked);
      debugPrint("Fecha desde seleccionada: $fechaDesde");
    }
  }

  Future<void> pickHasta() async {
    final now = DateTime.now();
    final initial = fechaHasta ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'),
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => fechaHasta = picked);
      debugPrint("Fecha hasta seleccionada: $fechaHasta");
    }
  }

  Future<void> crearMerma({
    required int idProducto,
    required int cantidad,
    required String motivo,
    String observacion = "",
  }) async {
    final body = {
      "id_producto": idProducto,
      "cantidad": cantidad,
      "motivo": motivo,
      "observacion": observacion,
    };

    try {
      final resp = await http.post(
        Uri.parse("$baseUrl/mermas"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Merma registrada con éxito")),
        );
        // CORREGIDO: Llamar a fetchMermas que actualizará automáticamente la lista
        await fetchMermas();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al registrar merma: ${resp.body}")),
        );
      }
    } catch (e) {
      debugPrint("Error creando merma: $e");
    }
  }

  Future<void> eliminarMerma(int idMerma) async {
    try {
      final resp = await http.delete(Uri.parse("$baseUrl/mermas/$idMerma"));
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Merma eliminada")),
        );
        // CORREGIDO: Llamar a fetchMermas que actualizará automáticamente la lista
        await fetchMermas();
      }
    } catch (e) {
      debugPrint("Error eliminando merma: $e");
    }
  }

  void openCreateDialog() {
    int? selectedProduct;
    final TextEditingController cantidadCtrl = TextEditingController();
    final TextEditingController motivoCtrl = TextEditingController(text: "Producto defectuoso");
    final TextEditingController obsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Registrar Merma"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: selectedProduct,
                  hint: const Text("Producto *"),
                  items: productos.map((p) {
                    return DropdownMenuItem<int>(
                      value: p["id_producto"],
                      child: Text(p["nombre"] ?? "-"),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedProduct = val),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cantidadCtrl,
                  decoration: const InputDecoration(labelText: "Cantidad *"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: motivoCtrl,
                  decoration: const InputDecoration(labelText: "Motivo *"),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(labelText: "Observación"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null || cantidadCtrl.text.isEmpty || motivoCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Completa todos los campos obligatorios (*)"),
                    ),
                  );
                  return;
                }
                crearMerma(
                  idProducto: selectedProduct!,
                  cantidad: int.tryParse(cantidadCtrl.text) ?? 0,
                  motivo: motivoCtrl.text,
                  observacion: obsCtrl.text,
                );
                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Scaffold(
      appBar: AppHeader(parentContext: context),
      drawer: mobile ? AppDrawer(parentContext: context) : null,
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateDialog,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(mobile ? 10 : 12),
        child: Column(
          children: [
            // Filtros por fecha
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickDesde,
                    child: Text(fechaDesde == null
                        ? "Desde"
                        : "Desde: ${formatDate(fechaDesde!)}"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: pickHasta,
                    child: Text(fechaHasta == null
                        ? "Hasta"
                        : "Hasta: ${formatDate(fechaHasta!)}"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: aplicarFiltros,
                  child: const Text("Filtrar"),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: limpiarFiltros,
                  child: const Text("Limpiar"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (fechaDesde != null || fechaHasta != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Mostrando ${mermasFiltradas.length} de ${mermas.length} mermas",
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            Expanded(
              child: mermasFiltradas.isEmpty
                  ? const Center(child: Text("No hay mermas registradas"))
                  : mobile
                      ? _buildMobileList()
                      : _buildDesktopTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: mermasFiltradas.length,
      itemBuilder: (context, index) {
        final m = mermasFiltradas[index];
        final fechaParsed = DateTime.tryParse(m['fecha']?.toString() ?? '');
        final fechaDisplay = fechaParsed != null ? _formatearFecha(fechaParsed.toString()) : (m['fecha']?.toString() ?? '');
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text("${m['producto']} — ${m['motivo']}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("Cantidad: ${m['cantidad']}  |  Fecha: $fechaDisplay\nObs: ${m['observacion'] ?? '-'}"),
            isThreeLine: true,
            trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => eliminarMerma(m["id_merma"])),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
          columnSpacing: 32,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Expanded(child: Text("Producto", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Cantidad", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Motivo", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Observación", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Text("Acción", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: mermasFiltradas.map<DataRow>((m) {
            final fechaParsed = DateTime.tryParse(m['fecha']?.toString() ?? '');
            final fechaDisplay = fechaParsed != null ? _formatearFecha(fechaParsed.toString()) : (m['fecha']?.toString() ?? '');
            return DataRow(cells: [
              DataCell(Text(m["producto"] ?? "")),
              DataCell(Text("${m['cantidad']}")),
              DataCell(Text(m["motivo"] ?? "")),
              DataCell(Text(m["observacion"] ?? "-")),
              DataCell(Text(fechaDisplay)),
              DataCell(IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => eliminarMerma(m["id_merma"]))),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
