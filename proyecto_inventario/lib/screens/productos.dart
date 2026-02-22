import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_header.dart';

class ProductosPage extends StatefulWidget {
  const ProductosPage({super.key});

  @override
  State<ProductosPage> createState() => _ProductosPageState();
}

class _ProductosPageState extends State<ProductosPage> {
  List productos = [];
  List productosFiltrados = [];
  bool loading = true;

  final String apiUrl = "http://127.0.0.1:8000/productos";

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
        Navigator.pop(context);
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
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error al actualizar producto: $e");
    }
  }

  Future<void> deleteProducto(int id) async {
    try {
      final resp = await http.delete(Uri.parse("$apiUrl/$id"));
      if (resp.statusCode == 200) {
        fetchProductos();
      }
    } catch (e) {
      debugPrint("Error al eliminar producto: $e");
    }
  }

  void openCreateDialog() {
    nombreCtrl.clear();
    descripcionCtrl.clear();
    precioCompraCtrl.clear();
    precioVentaCtrl.clear();
    stockCtrl.clear();
    stockMinimoCtrl.clear();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar Producto"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: "Descripción")),
              TextField(controller: precioCompraCtrl, decoration: const InputDecoration(labelText: "Precio de compra"), keyboardType: TextInputType.number),
              TextField(controller: precioVentaCtrl, decoration: const InputDecoration(labelText: "Precio de venta"), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Cantidad"), keyboardType: TextInputType.number),
              TextField(controller: stockMinimoCtrl, decoration: const InputDecoration(labelText: "Stock mínimo"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(onPressed: createProducto, child: const Text("Guardar")),
        ],
      ),
    );
  }

  void openEditDialog(Map producto) {
    nombreCtrl.text = producto["nombre"] ?? "";
    descripcionCtrl.text = producto["descripcion"] ?? "";
    precioCompraCtrl.text = producto["precio_compra"].toString();
    precioVentaCtrl.text = producto["precio_venta"].toString();
    stockCtrl.text = producto["stock"].toString();
    stockMinimoCtrl.text = producto["stock_minimo"].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Producto"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre")),
              TextField(controller: descripcionCtrl, decoration: const InputDecoration(labelText: "Descripción")),
              TextField(controller: precioCompraCtrl, decoration: const InputDecoration(labelText: "Precio de compra"), keyboardType: TextInputType.number),
              TextField(controller: precioVentaCtrl, decoration: const InputDecoration(labelText: "Precio de venta"), keyboardType: TextInputType.number),
              TextField(controller: stockCtrl, decoration: const InputDecoration(labelText: "Cantidad"), keyboardType: TextInputType.number),
              TextField(controller: stockMinimoCtrl, decoration: const InputDecoration(labelText: "Stock mínimo"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => updateProducto(producto["id_producto"]),
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
                  ? const Center(child: Text("No hay productos 😕"))
                  : ListView.builder(
                itemCount: productosFiltrados.length,
                itemBuilder: (context, index) {
                  final p = productosFiltrados[index];
                  return Card(
                    child: ListTile(
                      title: Text(p["nombre"] ?? ""),
                      subtitle: Text(
                        "Descripción: ${p["descripcion"] ?? "-"}\n"
                            "Precio Compra: \$${p["precio_compra"]}\n"
                            "Precio Venta: \$${p["precio_venta"]}\n"
                            "Cantidad: ${p["stock"]} (mínimo ${p["stock_minimo"]})",
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => openEditDialog(p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteProducto(p["id_producto"]),
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
