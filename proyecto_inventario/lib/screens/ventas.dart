// lib/screens/ventas.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/app_header.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

class VentasPage extends StatefulWidget {
  const VentasPage({super.key});

  @override
  State<VentasPage> createState() => _VentasPageState();
}

class _VentasPageState extends State<VentasPage> {
  List<Map<String, dynamic>> ventas = [];
  List<Map<String, dynamic>> ventasFiltradas = [];
  List<Map<String, dynamic>> clientes = [];
  List<Map<String, dynamic>> productos = [];
  bool loading = true;

  final String baseUrl = apiBaseUrl;

  // Filtros
  DateTime? fechaDesde;
  DateTime? fechaHasta;
  String? clienteSeleccionado; // Ahora es String (nombre) en lugar de int (id)

  @override
  void initState() {
    super.initState();
    fetchAll();
  }

  Future<void> fetchAll() async {
    setState(() => loading = true);
    await Future.wait([fetchVentas(), fetchClientes(), fetchProductos()]);
    setState(() {
      ventasFiltradas = List<Map<String, dynamic>>.from(ventas);
      loading = false;
    });
  }

  Future<void> fetchVentas() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/ventas"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        ventas = data.map((e) {
          final Map<String, dynamic> m = Map<String, dynamic>.from(e);
          if (m['fecha'] == null) {
            m['fecha'] = DateTime.now().toString();
          }
          return m;
        }).toList();

        debugPrint("=== VENTAS CARGADAS ===");
        for (var v in ventas) {
          debugPrint("Venta ID: ${v['id_venta']}, Fecha: ${v['fecha']}, Cliente: ${v['cliente']}");
        }
      }
    } catch (e) {
      debugPrint("Error cargando ventas: $e");
    }
  }

  Future<void> fetchClientes() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/clientes"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as List;
        clientes = data.map((e) => Map<String, dynamic>.from(e)).toList();

        debugPrint("=== CLIENTES CARGADOS ===");
        for (var c in clientes) {
          debugPrint("Cliente ID: ${c['id_cliente']}, Nombre: ${c['nombre']}");
        }
      }
    } catch (e) {
      debugPrint("Error cargando clientes: $e");
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

  Future<void> createVenta({
    int? idCliente,
    required List<Map<String, dynamic>> items,
    double descuento = 0.0,
  }) async {
    final body = {
      "id_cliente": idCliente,
      "productos": items
          .map((it) => {
        "id_producto": it["product_id"],
        "cantidad": it["quantity"],
      })
          .toList(),
      "descuento": descuento,
    };

    try {
      final resp = await http.post(
        Uri.parse("$baseUrl/ventas"),
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Venta registrada con éxito")),
        );
        await fetchAll();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al crear venta: ${resp.body}")),
        );
      }
    } catch (e) {
      debugPrint("Error creando venta: $e");
    }
  }

  Future<void> deleteVenta(int idVenta) async {
    try {
      final resp = await http.delete(Uri.parse("$baseUrl/ventas/$idVenta"));
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Venta eliminada")),
        );
        await fetchAll();
      }
    } catch (e) {
      debugPrint("Error eliminando venta: $e");
    }
  }

  Future<void> showVentaDetalle(int idVenta) async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/ventas/$idVenta"));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        final venta = data["venta"];
        final detalle = data["detalle"] as List;

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text("Venta #${venta['id_venta']} - ${_formatearFecha(venta['fecha'])}"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (venta['cliente'] != null)
                    Text("Cliente: ${venta['cliente']}"),
                  const SizedBox(height: 8),
                  const Divider(),
                  const Text("Detalle:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...detalle.map<Widget>((d) => Text(
                      "${d['producto']} — ${d['cantidad']} x ${d['precio_unitario']} = ${d['subtotal']}")),
                  const SizedBox(height: 10),
                  Text("Subtotal: \$${venta['subtotal']}"),
                  Text("Descuento: \$${venta['descuento']}"),
                  Text("IVA: \$${venta['iva']}"),
                  Text("Total: \$${venta['total']}"),
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
      debugPrint("Error detalle venta: $e");
    }
  }

  void aplicarFiltros() {
    debugPrint("=== APLICANDO FILTROS ===");
    debugPrint("Fecha desde: $fechaDesde");
    debugPrint("Fecha hasta: $fechaHasta");
    debugPrint("Cliente seleccionado: $clienteSeleccionado");

    setState(() {
      ventasFiltradas = ventas.where((v) {
        bool pasaFiltro = true;

        // Filtro por fecha
        final fechaStr = v['fecha']?.toString();
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
              debugPrint("Venta ${v['id_venta']} filtrada por fecha desde");
              pasaFiltro = false;
            }

            if (pasaFiltro && fechaHastaNormalizada != null && fechaRegistroNormalizada.isAfter(fechaHastaNormalizada)) {
              debugPrint("Venta ${v['id_venta']} filtrada por fecha hasta");
              pasaFiltro = false;
            }
          } else {
            pasaFiltro = false;
          }
        } else {
          pasaFiltro = false;
        }

        // FILTRO POR NOMBRE DE CLIENTE - NUEVA VERSIÓN
        if (pasaFiltro && clienteSeleccionado != null) {
          final nombreClienteVenta = v['cliente']?.toString() ?? "";

          if (clienteSeleccionado == "Sin cliente") {
            // Buscar ventas SIN cliente
            if (nombreClienteVenta.isNotEmpty && nombreClienteVenta != "Sin cliente") {
              debugPrint("Venta ${v['id_venta']} filtrada - tiene cliente '$nombreClienteVenta' (se esperaba sin cliente)");
              pasaFiltro = false;
            }
          } else {
            // Buscar ventas CON cliente específico
            if (nombreClienteVenta.isEmpty || nombreClienteVenta == "Sin cliente") {
              debugPrint("Venta ${v['id_venta']} filtrada - sin cliente (se esperaba: $clienteSeleccionado)");
              pasaFiltro = false;
            } else {
              // Comparar nombres (case insensitive)
              if (!nombreClienteVenta.toLowerCase().contains(clienteSeleccionado!.toLowerCase())) {
                debugPrint("Venta ${v['id_venta']} filtrada - cliente no coincide ('$nombreClienteVenta' != '$clienteSeleccionado')");
                pasaFiltro = false;
              }
            }
          }
        }

        if (pasaFiltro) {
          debugPrint("Venta ${v['id_venta']} PASÓ todos los filtros - Cliente: '${v['cliente']}'");
        }

        return pasaFiltro;
      }).toList();
    });

    debugPrint("=== RESULTADO FILTRADO ===");
    debugPrint("Ventas filtradas: ${ventasFiltradas.length}");
    for (var v in ventasFiltradas) {
      debugPrint("Venta ID: ${v['id_venta']}, Fecha: ${v['fecha']}, Cliente: ${v['cliente']}");
    }
  }

  void limpiarFiltros() {
    setState(() {
      fechaDesde = null;
      fechaHasta = null;
      clienteSeleccionado = null;
      ventasFiltradas = List<Map<String, dynamic>>.from(ventas);
    });
    debugPrint("=== FILTROS LIMPIADOS ===");
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

  // Dialogo para crear venta
  void openCreateDialog() {
    List<Map<String, dynamic>> items = [
      {"id": "init", "product_id": null, "quantity": 1, "unit_price": 0.0}
    ];
    final List<TextEditingController> qtyControllers = [
      TextEditingController(text: "1")
    ];
    int? selectedClienteLocal;
    final descuentoCtrl = TextEditingController(text: "0");
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (contextSB, setStateSB) {
          void addRow() {
            setStateSB(() {
              items.add({
                "id": DateTime.now().millisecondsSinceEpoch.toString(),
                "product_id": null, 
                "quantity": 1, 
                "unit_price": 0.0
              });
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

          double calcularSubtotal() {
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
                  Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Nueva Venta",
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
                      // CLIENTE SECTION
                      Text("Información del Cliente", style: TextStyle(color: Colors.deepPurple.shade700, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        isExpanded: true,
                        value: selectedClienteLocal,
                        decoration: InputDecoration(
                          labelText: "Cliente *",
                          prefixIcon: const Icon(Icons.person_pin_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        hint: const Text("Selecciona un cliente"),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text("Sin cliente (Venta General)"),
                          ),
                          ...clientes.map((c) {
                            return DropdownMenuItem<int?>(
                              value: c["id_cliente"],
                              child: Text(c["nombre"] ?? "-"),
                            );
                          }).toList(),
                        ],
                        onChanged: (val) {
                          setStateSB(() => selectedClienteLocal = val);
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
                          key: ValueKey("venta_item_${idx}"), // Clave para mantener el foco
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
                                          (producto["precio_venta"] ?? 0).toDouble();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  key: ValueKey("qty_field_${item['id']}"),
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
                                    setStateSB(() {});
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

                      // TOTALS SECTION
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: descuentoCtrl,
                              decoration: InputDecoration(
                                labelText: "Descuento Aplicado (\$)",
                                prefixIcon: const Icon(Icons.loyalty_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                isDense: true,
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setStateSB(() {}),
                            ),
                            const SizedBox(height: 16),
                            Builder(builder: (_) {
                              final subtotal = calcularSubtotal();
                              final descuento = double.tryParse(descuentoCtrl.text) ?? 0.0;
                              final iva = double.parse(((subtotal - descuento) * 0.19).toStringAsFixed(2));
                              final total = subtotal - descuento + iva;
                              
                              return Column(
                                children: [
                                  _buildSummaryRow("Subtotal:", "\$${subtotal.toStringAsFixed(0)}"),
                                  _buildSummaryRow("Descuento:", "-\$${descuento.toStringAsFixed(0)}"),
                                  _buildSummaryRow("IVA (19%):", "+\$${iva.toStringAsFixed(0)}"),
                                  const Divider(),
                                  _buildSummaryRow(
                                    "Total a Pagar:", 
                                    "\$${total.toStringAsFixed(0)}", 
                                    isTotal: true
                                  ),
                                ],
                              );
                            }),
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
                icon: const Icon(Icons.check_circle_outline),
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
                    final descuento = double.tryParse(descuentoCtrl.text) ?? 0.0;
                    createVenta(
                        idCliente: selectedClienteLocal,
                        items: items,
                        descuento: descuento);
                    Navigator.pop(context);
                  }
                },
                label: const Text("Finalizar Venta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? Colors.deepPurple.shade900 : Colors.grey.shade700,
          )),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.bold,
            color: isTotal ? Colors.deepPurple.shade900 : Colors.black87,
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Scaffold(
      appBar: AppHeader(parentContext: context, activePage: 'Ventas'),
      drawer: isMobile(context)
          ? AppDrawer(parentContext: context, activePage: 'Ventas')
          : null,
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
                      value: clienteSeleccionado,
                      hint: const Text("Cliente"),
                      decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text("Todos")),
                        const DropdownMenuItem<String?>(value: "Sin cliente", child: Text("Sin cliente")),
                        ...clientes.map((c) => DropdownMenuItem<String?>(value: c["nombre"], child: Text(c["nombre"] ?? "-"))),
                      ],
                      onChanged: (v) => setState(() => clienteSeleccionado = v),
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
                        value: clienteSeleccionado,
                        hint: const Text("Filtrar por cliente"),
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text("Todos los clientes")),
                          const DropdownMenuItem<String?>(value: "Sin cliente", child: Text("Sin cliente")),
                          ...clientes.map((c) => DropdownMenuItem<String?>(value: c["nombre"], child: Text(c["nombre"] ?? "-"))),
                        ],
                        onChanged: (v) => setState(() => clienteSeleccionado = v),
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
            if (fechaDesde != null || fechaHasta != null || clienteSeleccionado != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Mostrando ${ventasFiltradas.length} de ${ventas.length} ventas",
                  style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            Expanded(
              child: ventasFiltradas.isEmpty
                  ? const Center(child: Text("No hay ventas que mostrar"))
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
    itemCount: ventasFiltradas.length,
    itemBuilder: (context, index) {
      final v = ventasFiltradas[index];
      final fechaParsed = DateTime.tryParse(v['fecha']?.toString() ?? '');
      final fechaDisplay = fechaParsed != null ? _formatearFecha(fechaParsed.toString()) : (v['fecha']?.toString() ?? '');
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text("Venta #${v["id_venta"]} — $fechaDisplay", style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Cliente: ${v["cliente"] ?? "Sin cliente"}\nTotal: \$${v["total"]}"),
          isThreeLine: true,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.visibility), onPressed: () => showVentaDetalle(v["id_venta"])),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => deleteVenta(v["id_venta"])),
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
          DataColumn(label: Expanded(child: Text("Cliente", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Expanded(child: Text("Total", style: TextStyle(fontWeight: FontWeight.bold)))),
          DataColumn(label: Text("Acciones", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: ventasFiltradas.map<DataRow>((v) {
          final fechaParsed = DateTime.tryParse(v['fecha']?.toString() ?? '');
          final fechaDisplay = fechaParsed != null ? _formatearFecha(fechaParsed.toString()) : (v['fecha']?.toString() ?? '');
          return DataRow(cells: [
            DataCell(Text("#${v["id_venta"]}")),
            DataCell(Text(fechaDisplay)),
            DataCell(Text(v["cliente"] ?? "Sin cliente")),
            DataCell(Text("\$${v["total"]}")),
            DataCell(Row(children: [
              IconButton(icon: const Icon(Icons.visibility, color: Colors.indigo, size: 20), onPressed: () => showVentaDetalle(v["id_venta"])),
              IconButton(icon: const Icon(Icons.delete, color: Colors.red, size: 20), onPressed: () => deleteVenta(v["id_venta"])),
            ])),
          ]);
        }).toList(),
      ),
    ),
  );
}
