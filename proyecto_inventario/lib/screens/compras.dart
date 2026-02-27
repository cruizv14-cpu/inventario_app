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
    List<TextEditingController> qtyControllers = [
      TextEditingController(text: "1")
    ];
    int? selectedProveedorLocal;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (contextSB, setStateSB) {
          void addRow() {
            setStateSB(() {
              items.add({"product_id": null, "quantity": 1, "unit_price": 0.0});
              qtyControllers.add(TextEditingController(text: "1"));
            });
          }

          void removeRow(int idx) {
            setStateSB(() {
              items.removeAt(idx);
              qtyControllers[idx].dispose();
              qtyControllers.removeAt(idx);
            });
          }

          final _formKey = GlobalKey<FormState>();

          double calcularTotal() {
            double total = 0;
            for (var i in items) {
              total += (i["unit_price"] ?? 0) * (i["quantity"] ?? 0);
            }
            return total;
          }

          return AlertDialog(
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
              child: const Row(
                children: [
                  Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Nueva Compra",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ],
              ),
            ),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // PROVEEDOR SECTION
                      Text("Información del Proveedor", style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: selectedProveedorLocal,
                        decoration: InputDecoration(
                          labelText: "Proveedor *",
                          prefixIcon: const Icon(Icons.local_shipping_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        hint: const Text("Selecciona un proveedor"),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text("Sin proveedor (Compra Directa)"),
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
                        },
                      ),
                      const Divider(height: 32),
                      
                      // PRODUCTOS SECTION
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Productos", style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold)),
                          TextButton.icon(
                            onPressed: addRow,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text("Agregar"),
                            style: TextButton.styleFrom(foregroundColor: Colors.deepPurple),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: DropdownButtonFormField<int>(
                                  value: item["product_id"],
                                  decoration: const InputDecoration(
                                    labelText: "Producto",
                                    isDense: true,
                                    border: UnderlineInputBorder(),
                                  ),
                                  validator: (val) => val == null ? 'Seleccione' : null,
                                  items: productos.map((p) {
                                    return DropdownMenuItem<int>(
                                      value: p["id_producto"],
                                      child: Text(p["nombre"] ?? "-", style: const TextStyle(fontSize: 13)),
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
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: qtyControllers[idx],
                                  decoration: const InputDecoration(
                                    labelText: "Cant.",
                                    isDense: true,
                                    border: UnderlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Req.';
                                    final num = int.tryParse(val);
                                    if (num == null || num <= 0) return '> 0';
                                    return null;
                                  },
                                  onChanged: (val) {
                                    item["quantity"] = int.tryParse(val) ?? item["quantity"];
                                    setStateSB(() {}); // For subtotal update
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text("Subtotal", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  Text(
                                    "\$${(item["unit_price"] * item["quantity"]).toStringAsFixed(0)}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () => removeRow(idx),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      
                      if (items.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text("No hay productos añadidos", style: TextStyle(color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
                          ),
                        ),

                      const Divider(height: 32),

                      // TOTAL SECTION
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Costo Total de Compra:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text(
                              "\$${calcularTotal().toStringAsFixed(0)}",
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.assignment_turned_in_outlined),
                onPressed: () {
                  if (items.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Agrega al menos un producto")));
                    return;
                  }
                  if (_formKey.currentState!.validate()) {
                    if (items.any((i) => i["product_id"] == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                          Text("Selecciona todos los productos primero")));
                      return;
                    }
                    createCompra(idProveedor: selectedProveedorLocal, items: items);
                    Navigator.pop(context);
                  }
                },
                label: const Text("Registrar Compra", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        padding: EdgeInsets.all(mobile ? 10 : 16),
        child: Column(
          children: [
            // Filtros
            mobile
                ? Column(children: [
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: pickDesde, child: Text(fechaDesde == null ? "Desde" : "Desde: ${formatDate(fechaDesde!)}"))),
                      const SizedBox(width: 8),
                      Expanded(child: OutlinedButton(onPressed: pickHasta, child: Text(fechaHasta == null ? "Hasta" : "Hasta: ${formatDate(fechaHasta!)}"))),
                    ]),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: proveedorSeleccionado,
                      hint: const Text("Proveedor"),
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text("Todos")),
                        const DropdownMenuItem<String?>(value: "Sin proveedor", child: Text("Sin proveedor")),
                        ...proveedores.map((p) => DropdownMenuItem<String?>(value: p["nombre"], child: Text(p["nombre"] ?? "-"))),
                      ],
                      onChanged: (v) => setState(() => proveedorSeleccionado = v),
                    ),
                  ])
                : Row(children: [
                    Expanded(child: OutlinedButton(onPressed: pickDesde, child: Text(fechaDesde == null ? "Desde" : "Desde: ${formatDate(fechaDesde!)}"))),
                    const SizedBox(width: 8),
                    Expanded(child: OutlinedButton(onPressed: pickHasta, child: Text(fechaHasta == null ? "Hasta" : "Hasta: ${formatDate(fechaHasta!)}"))),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String?>(
                        value: proveedorSeleccionado,
                        hint: const Text("Filtrar por proveedor"),
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text("Todos los proveedores")),
                          const DropdownMenuItem<String?>(value: "Sin proveedor", child: Text("Sin proveedor")),
                          ...proveedores.map((p) => DropdownMenuItem<String?>(value: p["nombre"], child: Text(p["nombre"] ?? "-"))),
                        ],
                        onChanged: (v) => setState(() => proveedorSeleccionado = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: aplicarFiltros,
                      icon: const Icon(Icons.filter_list),
                      label: const Text("Filtrar"),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                    ),
                    const SizedBox(width: 4),
                    TextButton(onPressed: limpiarFiltros, child: const Text("Limpiar")),
                  ]),
            if (mobile) ...[
              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(onPressed: aplicarFiltros, child: const Text("Filtrar")),
                const SizedBox(width: 8),
                TextButton(onPressed: limpiarFiltros, child: const Text("Limpiar")),
              ]),
            ],
            const SizedBox(height: 12),
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
                  : mobile
                      ? _buildMobileList()
                      : _buildDesktopTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList() => ListView.builder(
    itemCount: comprasFiltradas.length,
    itemBuilder: (context, index) {
      final c = comprasFiltradas[index];
      final fechaParsed = DateTime.tryParse(c['fecha']?.toString() ?? '');
      final fechaDisplay = fechaParsed != null ? _formatearFecha(fechaParsed.toString()) : (c['fecha']?.toString() ?? '');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text("Compra #${c["id_compra"]} — $fechaDisplay", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Proveedor: ${c["proveedor"] ?? "Sin proveedor"}\nTotal: \$${c["total"]}"),
          isThreeLine: true,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.visibility), onPressed: () => showCompraDetalle(c["id_compra"])),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteCompra(c["id_compra"])),
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
          DataColumn(label: Expanded(child: Text("#", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Proveedor", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: comprasFiltradas.map<DataRow>((c) {
          final fechaParsed = DateTime.tryParse(c['fecha']?.toString() ?? '');
          final fechaDisplay = fechaParsed != null ? _formatearFecha(fechaParsed.toString()) : (c['fecha']?.toString() ?? '');
          return DataRow(cells: [
            DataCell(Text("#${c["id_compra"]}")),
            DataCell(Text(fechaDisplay)),
            DataCell(Text(c["proveedor"] ?? "Sin proveedor")),
            DataCell(Text("\$${c["total"]}")),
            DataCell(Row(children: [
              IconButton(icon: const Icon(Icons.visibility, color: Colors.indigo, size: 20), onPressed: () => showCompraDetalle(c["id_compra"])),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => deleteCompra(c["id_compra"])),
            ])),
          ]);
        }).toList(),
      ),
    ),
  );
}
