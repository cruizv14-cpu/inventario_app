import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List productos = [];
  List productosFiltrados = [];
  bool loading = true;

  final String apiUrl = "$apiBaseUrl/productos";

  final TextEditingController nombreCtrl = TextEditingController();
  final TextEditingController descripcionCtrl = TextEditingController();
  final TextEditingController precioCompraCtrl = TextEditingController();
  final TextEditingController precioVentaCtrl = TextEditingController();
  final TextEditingController stockCtrl = TextEditingController();
  final TextEditingController stockMinimoCtrl = TextEditingController();
  final TextEditingController buscarCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProductos();
  }

  Future<void> fetchProductos() async {
    setState(() => loading = true);
    try {
      final resp = await http.get(Uri.parse(apiUrl));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          productos = data;
          productosFiltrados = data;
        });
      }
    } catch (e) {
      debugPrint("Error al cargar productos: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void filtrarProductos(String query) {
    final texto = query.toLowerCase();
    setState(() {
      productosFiltrados = productos.where((p) {
        final nombre = (p["nombre"] ?? "").toLowerCase();
        final descripcion = (p["descripcion"] ?? "").toLowerCase();
        return nombre.contains(texto) || descripcion.contains(texto);
      }).toList();
    });
  }

  Future<void> createProducto() async {
    final data = {
      "nombre": nombreCtrl.text,
      "descripcion": descripcionCtrl.text,
      "precio_compra": double.tryParse(precioCompraCtrl.text) ?? 0.0,
      "precio_venta": double.tryParse(precioVentaCtrl.text) ?? 0.0,
      "stock": int.tryParse(stockCtrl.text) ?? 0,
      "stock_minimo": int.tryParse(stockMinimoCtrl.text) ?? 0,
    };
    try {
      final resp = await http.post(Uri.parse(apiUrl),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data));
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await fetchProductos();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al crear producto: $e");
    }
  }

  Future<void> updateProducto(int id) async {
    final data = {
      "nombre": nombreCtrl.text,
      "descripcion": descripcionCtrl.text,
      "precio_compra": double.tryParse(precioCompraCtrl.text) ?? 0.0,
      "precio_venta": double.tryParse(precioVentaCtrl.text) ?? 0.0,
      "stock": int.tryParse(stockCtrl.text) ?? 0,
      "stock_minimo": int.tryParse(stockMinimoCtrl.text) ?? 0,
    };
    try {
      final resp = await http.put(Uri.parse("$apiUrl/$id"),
          headers: {"Content-Type": "application/json"},
          body: json.encode(data));
      if (resp.statusCode == 200) {
        await fetchProductos();
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al actualizar producto: $e");
    }
  }

  Future<void> deleteProducto(int id) async {
    try {
      final resp = await http.delete(Uri.parse("$apiUrl/$id"));
      if (resp.statusCode == 200) fetchProductos();
    } catch (e) {
      debugPrint("Error al eliminar producto: $e");
    }
  }

  void openFormDialog({Map? producto}) {
    if (producto != null) {
      nombreCtrl.text = producto["nombre"] ?? "";
      descripcionCtrl.text = producto["descripcion"] ?? "";
      precioCompraCtrl.text = producto["precio_compra"].toString();
      precioVentaCtrl.text = producto["precio_venta"].toString();
      stockCtrl.text = producto["stock"].toString();
      stockMinimoCtrl.text = producto["stock_minimo"].toString();
    } else {
      nombreCtrl.clear(); descripcionCtrl.clear();
      precioCompraCtrl.clear(); precioVentaCtrl.clear();
      stockCtrl.clear(); stockMinimoCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(producto != null ? "Editar Producto" : "Agregar Producto"),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: "Descripción", border: OutlineInputBorder())),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: precioCompraCtrl, decoration: const InputDecoration(labelText: "P. Compra", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: precioVentaCtrl, decoration: const InputDecoration(labelText: "P. Venta", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Stock", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: stockMinimoCtrl, decoration: const InputDecoration(labelText: "Stock Mínimo", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: producto != null
                ? () => updateProducto(producto["id_producto"])
                : createProducto,
            child: Text(producto != null ? "Actualizar" : "Guardar"),
          ),
        ],
      ),
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
        child: Column(
          children: [
            TextField(
              controller: buscarCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: "Buscar por nombre o descripción...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: filtrarProductos,
            ),
            const SizedBox(height: 10),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : productosFiltrados.isEmpty
                      ? const Center(child: Text("No hay productos 😕", style: TextStyle(fontSize: 16)))
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
      itemCount: productosFiltrados.length,
      itemBuilder: (context, index) {
        final p = productosFiltrados[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(p["nombre"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              "PC: \$${p["precio_compra"]}  PV: \$${p["precio_venta"]}\n"
              "Stock: ${p["stock"]} (mín. ${p["stock_minimo"]})",
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => openFormDialog(producto: p)),
                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteProducto(p["id_producto"])),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.deepPurple.shade50),
          columnSpacing: 32,
          dataRowMinHeight: 48,
          dataRowMaxHeight: 56,
          columns: const [
            DataColumn(label: Expanded(child: Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Descripción", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("P. Compra", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("P. Venta", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Stock", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Expanded(child: Text("Stock Min.", style: TextStyle(fontWeight: FontWeight.bold)))),
            DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: productosFiltrados.map<DataRow>((p) => DataRow(cells: [
            DataCell(Text(p["nombre"] ?? "")),
            DataCell(Text(p["descripcion"] ?? "-")),
            DataCell(Text("\$${p["precio_compra"]}")),
            DataCell(Text("\$${p["precio_venta"]}")),
            DataCell(Text("${p["stock"]}")),
            DataCell(Text("${p["stock_minimo"]}")),
            DataCell(Row(children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue, size: 20), onPressed: () => openFormDialog(producto: p)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => deleteProducto(p["id_producto"])),
            ])),
          ])).toList(),
        ),
      ),
    );
  }
}
