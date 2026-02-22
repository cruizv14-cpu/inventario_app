// lib/screens/ventas.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../widgets/app_header.dart';

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

  final String baseUrl = "http://127.0.0.1:8000";

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
      {"product_id": null, "quantity": 1, "unit_price": 0.0}
    ];
    int? selectedClienteLocal;
    final descuentoCtrl = TextEditingController(text: "0");

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(builder: (contextSB, setStateSB) {
          void addRow() {
            setStateSB(() =>
                items.add({"product_id": null, "quantity": 1, "unit_price": 0.0}));
          }

          void removeRow(int idx) {
            setStateSB(() => items.removeAt(idx));
          }

          double calcularSubtotal() {
            double total = 0;
            for (var i in items) {
              total += (i["unit_price"] ?? 0) * (i["quantity"] ?? 0);
            }
            return total;
          }

          return AlertDialog(
            title: const Text("Nueva Venta"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  // CLIENTE
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
                            "Cliente *",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownButton<int?>(
                          isExpanded: true,
                          value: selectedClienteLocal,
                          hint: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text("Selecciona un cliente"),
                          ),
                          items: [
                            const DropdownMenuItem<int?>(
                              value: null,
                              child: Text("Sin cliente"),
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
                            debugPrint("Cliente seleccionado: $val");
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
                                    (producto["precio_venta"] ?? 0).toDouble();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: item["quantity"].toString(),
                            decoration: const InputDecoration(labelText: "Cant.*"),
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
                  TextField(
                    controller: descuentoCtrl,
                    decoration:
                    const InputDecoration(labelText: "Descuento (\$)"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (_) {
                    final subtotal = calcularSubtotal();
                    final descuento = double.tryParse(descuentoCtrl.text) ?? 0.0;
                    final iva =
                    double.parse(((subtotal - descuento) * 0.19).toStringAsFixed(2));
                    final total = subtotal - descuento + iva;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Subtotal: \$${subtotal.toStringAsFixed(0)}"),
                        Text("Descuento: \$${descuento.toStringAsFixed(0)}"),
                        Text("IVA (19%): \$${iva.toStringAsFixed(0)}"),
                        const SizedBox(height: 6),
                        Text("Total: \$${total.toStringAsFixed(0)}",
                            style: const TextStyle(fontSize: 16)),
                      ],
                    );
                  }),
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

                  final descuento = double.tryParse(descuentoCtrl.text) ?? 0.0;

                  debugPrint("=== CREANDO VENTA ===");
                  debugPrint("Cliente ID: $selectedClienteLocal");
                  debugPrint("Descuento: $descuento");

                  createVenta(
                      idCliente: selectedClienteLocal,
                      items: items,
                      descuento: descuento);
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
    return Scaffold(
      appBar: AppHeader(parentContext: context),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // filtros
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
                  // FILTRO POR NOMBRE - NUEVA VERSIÓN
                  child: DropdownButtonFormField<String?>(
                    value: clienteSeleccionado,
                    hint: const Text("Cliente"),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text("Todos")),
                      const DropdownMenuItem<String?>(
                          value: "Sin cliente", child: Text("Sin cliente")),
                      ...clientes.map((c) {
                        return DropdownMenuItem<String?>(
                          value: c["nombre"],
                          child: Text(c["nombre"] ?? "-"),
                        );
                      }).toList(),
                    ],
                    onChanged: (v) {
                      setState(() => clienteSeleccionado = v);
                      debugPrint("Cliente seleccionado: $v");
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
                  : ListView.builder(
                itemCount: ventasFiltradas.length,
                itemBuilder: (context, index) {
                  final v = ventasFiltradas[index];
                  final fechaStr = v['fecha']?.toString() ?? '';
                  final fechaParsed = DateTime.tryParse(fechaStr);
                  final fechaDisplay = fechaParsed != null
                      ? _formatearFecha(fechaParsed.toString())
                      : fechaStr;
                  return Card(
                    child: ListTile(
                      title: Text(
                          "Venta #${v["id_venta"]} - $fechaDisplay"),
                      subtitle: Text(
                          "Cliente: ${v["cliente"] ?? "Sin cliente"}\nTotal: \$${v["total"]}"),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => showVentaDetalle(
                                  v["id_venta"])),
                          IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () =>
                                  deleteVenta(v["id_venta"])),
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