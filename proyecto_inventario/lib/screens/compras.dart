// lib/screens/compras.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import '../widgets/app_header.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class ComprasPage extends StatefulWidget {
  const ComprasPage({super.key});

  @override
  State<ComprasPage> createState() => _ComprasPageState();
}

class _ComprasPageState extends State<ComprasPage> {
  List<Map<String, dynamic>> compras = [];
  List<Map<String, dynamic>> comprasFiltradas = [];
  List<Map<String, dynamic>> proveedores = [];
  List<Map<String, dynamic>> productos = [];
  bool loading = true;

  final String baseUrl = apiBaseUrl;

  // filtros
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  String? proveedorSeleccionado; // Ahora es String (nombre) en lugar de int (id)

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    await Future.wait([fetchCompras(), fetchProveedores(), fetchProductos()]);
    setState(() {
      comprasFiltradas = List<Map<String, dynamic>>.from(compras);
      loading = false;
    });
  }

  Future<void> fetchCompras() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/compras"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        compras = data.map((e) {
          final Map<String, dynamic> m = Map<String, dynamic>.from(e);
          if (m['fecha'] == null) {
            m['fecha'] = DateTime.now().toString();
          }
          return m;
        }).toList();

        debugPrint("=== COMPRAS CARGADAS ===");
        for (var c in compras) {
          debugPrint("Compra ID: ${c['id_compra']}, Fecha: ${c['fecha']}, Proveedor: ${c['proveedor']}");
        }
      }
    } catch (e) {
      debugPrint("Error cargando compras: $e");
    }
  }

  Future<void> fetchProveedores() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/proveedores"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        proveedores = data.map((e) => Map<String, dynamic>.from(e)).toList();

        debugPrint("=== PROVEEDORES CARGADOS ===");
        for (var p in proveedores) {
          debugPrint("Proveedor ID: ${p['id_proveedor']}, Nombre: ${p['nombre']}");
        }
      }
    } catch (e) {
      debugPrint("Error cargando proveedores: $e");
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

  Future<void> createCompra({
    int? idProveedor,
    required List<Map<String, dynamic>> items,
  }) async {
    final body = {
      "id_proveedor": idProveedor,
      "productos": items
          .map((it) => {
        "id_producto": it["product_id"],
        "cantidad": it["quantity"],
        "precio_unitario": it["unit_price"]
      })
          .toList(),
    };

    try {
      final resp = await http.post(
        Uri.parse("$baseUrl/compras"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compra registrada con éxito")),
        );
        await fetchAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al crear compra: ${resp.body}")),
        );
      }
    } catch (e) {
      debugPrint("Error creando compra: $e");
    }
  }

  Future<void> deleteCompra(int idCompra) async {
    try {
      final resp = await http.delete(Uri.parse("$baseUrl/compras/$idCompra"));
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Compra eliminada")),
        );
        await fetchAll();
      }
    } catch (e) {
      debugPrint("Error eliminando compra: $e");
    }
  }

  Future<void> showCompraDetalle(int idCompra) async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/compras/$idCompra"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final compra = data["compra"];
        final detalle = data["detalle"] as List;

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Compra #${compra['id_compra']} - ${_formatearFecha(compra['fecha'])}"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (compra['proveedor'] != null)
                    Text("Proveedor: ${compra['proveedor']}"),
                  const SizedBox(height: 8),
                  const Divider(),
                  const Text("Detalle:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...detalle.map<Widget>((d) => Text(
                      "${d['producto']} — ${d['cantidad']} x ${d['precio_unitario']} = ${d['subtotal']}")),
                  const SizedBox(height: 10),
                  Text("Total: \$${compra['total']}"),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"))
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error detalle compra: $e");
    }
  }

  void aplicarFiltros() {
    debugPrint("=== APLICANDO FILTROS COMPRAS ===");
    debugPrint("Fecha desde: $fechaDesde");
    debugPrint("Fecha hasta: $fechaHasta");
    debugPrint("Proveedor seleccionado: $proveedorSeleccionado");

    setState(() {
      comprasFiltradas = compras.where((c) {
        bool pasaFiltro = true;

        // Filtro por fecha
        final fechaStr = c['fecha']?.toString();
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
              debugPrint("Compra ${c['id_compra']} filtrada por fecha desde");
              pasaFiltro = false;
            }

            if (pasaFiltro && fechaHastaNormalizada != null && fechaRegistroNormalizada.isAfter(fechaHastaNormalizada)) {
              debugPrint("Compra ${c['id_compra']} filtrada por fecha hasta");
              pasaFiltro = false;
            }
          } else {
            pasaFiltro = false;
          }
        } else {
          pasaFiltro = false;
        }

        // FILTRO POR NOMBRE DE PROVEEDOR - NUEVA VERSIÓN
        if (pasaFiltro && proveedorSeleccionado != null) {
          final nombreProveedorCompra = c['proveedor']?.toString() ?? "";

          if (proveedorSeleccionado == "Sin proveedor") {
            // Buscar compras SIN proveedor
            if (nombreProveedorCompra.isNotEmpty && nombreProveedorCompra != "Sin proveedor") {
              debugPrint("Compra ${c['id_compra']} filtrada - tiene proveedor '$nombreProveedorCompra' (se esperaba sin proveedor)");
              pasaFiltro = false;
            }
          } else {
            // Buscar compras CON proveedor específico
            if (nombreProveedorCompra.isEmpty || nombreProveedorCompra == "Sin proveedor") {
              debugPrint("Compra ${c['id_compra']} filtrada - sin proveedor (se esperaba: $proveedorSeleccionado)");
              pasaFiltro = false;
            } else {
              // Comparar nombres (case insensitive)
              if (!nombreProveedorCompra.toLowerCase().contains(proveedorSeleccionado!.toLowerCase())) {
                debugPrint("Compra ${c['id_compra']} filtrada - proveedor no coincide ('$nombreProveedorCompra' != '$proveedorSeleccionado')");
                pasaFiltro = false;
              }
            }
          }
        }

        if (pasaFiltro) {
          debugPrint("Compra ${c['id_compra']} PASÓ todos los filtros - Proveedor: '${c['proveedor']}'");
        }

        return pasaFiltro;
      }).toList();
    });

    debugPrint("=== RESULTADO FILTRADO COMPRAS ===");
    debugPrint("Compras filtradas: ${comprasFiltradas.length}");
    for (var c in comprasFiltradas) {
      debugPrint("Compra ID: ${c['id_compra']}, Fecha: ${c['fecha']}, Proveedor: ${c['proveedor']}");
    }
  }

  void limpiarFiltros() {
    setState(() {
      fechaDesde = null;
      fechaHasta = null;
      proveedorSeleccionado = null;
      comprasFiltradas = List<Map<String, dynamic>>.from(compras);
    });
    debugPrint("=== FILTROS COMPRAS LIMPIADOS ===");
  }

  // ✅ Formatear fecha como dd/MM/yyyy
  String _formatearFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      return DateFormat('dd/MM/yyyy').format(fecha);
    } catch (_) {
      return fechaStr;
    }
  }

  // ✅ Nuevo formato visual de la fecha
  String formatDate(DateTime d) {
    return DateFormat('dd/MM/yyyy').format(d);
  }

  Future<void> pickDesde() async {
    final now = DateTime.now();
    final initial = fechaDesde ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('es', 'ES'), // 👈 idioma español
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

  // DIALOGO para crear compra - MEJORADO
  void openCreateDialog() {
    List<Map<String, dynamic>> items = [
      {"product_id": null, "quantity": 1, "unit_price": 0.0}
    ];
    int? selectedProveedorLocal;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (contextSB, setStateSB) {
          void addRow() {
            setStateSB(() => items.add(
                {"product_id": null, "quantity": 1, "unit_price": 0.0}));
          }

          void removeRow(int idx) {
            setStateSB(() => items.removeAt(idx));
          }

          double calcularTotal() {
            double total = 0;
            for (var i in items) {
              total += (i["unit_price"] ?? 0) * (i["quantity"] ?? 0);
            }
            return total;
          }

          return AlertDialog(
            title: const Text("Nueva Compra"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // PROVEEDOR - MEJORADO
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            "Proveedor *",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownButton<int?>(
                          isExpanded: true,
                          value: selectedProveedorLocal,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("Selecciona un proveedor"),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text("Sin proveedor"),
                            ),
                            ...proveedores.map((p) {
                              return DropdownMenuItem<int?>(
                                value: p["id_proveedor"],
                                child: Text(p["nombre"] ?? "-"),
                              );
                            }).toList(),
                          ],
                          onChanged: (val) {
                            setStateSB(() => selectedProveedorLocal = val);
                            debugPrint("Proveedor seleccionado: $val");
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PRODUCTOS
                  ...items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<int>(
                            value: item["product_id"],
                            hint: const Text("Producto *"),
                            items: productos.map((p) {
                              return DropdownMenuItem<int>(
                                value: p["id_producto"],
                                child: Text(p["nombre"] ?? "-"),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateSB(() {
                                item["product_id"] = val;
                                final producto = productos.firstWhere(
                                        (prod) => prod["id_producto"] == val);
                                item["unit_price"] =
                                    (producto["precio_compra"] ?? 0).toDouble();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item["quantity"].toString(),
                            decoration:
                            const InputDecoration(labelText: "Cant.*"),
                            keyboardType: TextInputType.number,
                            onChanged: (val) {
                              setStateSB(() {
                                item["quantity"] =
                                    int.tryParse(val) ?? item["quantity"];
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                              "\$${(item["unit_price"] * item["quantity"]).toStringAsFixed(0)}"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => removeRow(idx),
                        ),
                      ],
                    );
                  }).toList(),
                  TextButton.icon(
                      onPressed: addRow,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar producto")),
                  const SizedBox(height: 12),
                  Text("Total: \$${calcularTotal().toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () {
                  if (items.any((i) => i["product_id"] == null)) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content:
                        Text("Selecciona todos los productos primero")));
                    return;
                  }

                  debugPrint("=== CREANDO COMPRA ===");
                  debugPrint("Proveedor ID: $selectedProveedorLocal");

                  createCompra(
                      idProveedor: selectedProveedorLocal, items: items);
                  Navigator.pop(context);
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        });
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // filtros: Fecha Desde / Hasta y Proveedor
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
                const SizedBox(width: 8),
                Expanded(
                  // FILTRO POR NOMBRE DE PROVEEDOR - NUEVA VERSIÓN
                  child: DropdownButtonFormField<String?>(
                    value: proveedorSeleccionado,
                    hint: const Text("Proveedor"),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Todos")),
                      const DropdownMenuItem<String?>(
                          value: "Sin proveedor", child: Text("Sin proveedor")),
                      ...proveedores.map((p) {
                        return DropdownMenuItem<String?>(
                          value: p["nombre"],
                          child: Text(p["nombre"] ?? "-"),
                        );
                      }).toList(),
                    ],
                    onChanged: (v) {
                      setState(() => proveedorSeleccionado = v);
                      debugPrint("Proveedor seleccionado: $v");
                    },
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
                    child: const Text("Limpiar")),
              ],
            ),
            const SizedBox(height: 12),
            // Información de filtros aplicados
            if (fechaDesde != null || fechaHasta != null || proveedorSeleccionado != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Mostrando ${comprasFiltradas.length} de ${compras.length} compras",
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            Expanded(
              child: comprasFiltradas.isEmpty
                  ? const Center(child: Text("No hay compras que mostrar"))
                  : ListView.builder(
                itemCount: comprasFiltradas.length,
                itemBuilder: (context, index) {
                  final c = comprasFiltradas[index];
                  final fechaStr = c['fecha']?.toString() ?? '';
                  final fechaParsed = DateTime.tryParse(fechaStr);
                  final fechaDisplay = fechaParsed != null
                      ? _formatearFecha(fechaParsed.toString())
                      : fechaStr;
                  return Card(
                    child: ListTile(
                      title: Text(
                          "Compra #${c["id_compra"]} - $fechaDisplay"),
                      subtitle: Text(
                          "Proveedor: ${c["proveedor"] ?? "Sin proveedor"}\nTotal: \$${c["total"]}"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => showCompraDetalle(
                                  c["id_compra"])),
                          IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  deleteCompra(c["id_compra"])),
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