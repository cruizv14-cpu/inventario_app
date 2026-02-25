import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../widgets/app_header.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import '../utils/constants.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List stockBajo = [];
  bool loading = true;
  final String baseUrl = apiBaseUrl;
  Map<String, dynamic> resumen = {};

  // Datos para gráficos
  List<Map<String, dynamic>> productosMasVendidos = [];
  List<Map<String, dynamic>> clientesTop = [];
  List<Map<String, dynamic>> proveedoresTop = [];
  List<Map<String, dynamic>> ventasPorComuna = [];
  List<Map<String, dynamic>> margenesProductos = [];

  // Controladores de carrusel
  final PageController _kpiController = PageController();
  final PageController _graficosController = PageController();
  int _currentKpiIndex = 0;
  int _currentGraficoIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _cargarTodosLosDatos();

    // 🔄 Rotación automática de carruseles
    _autoTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_kpiController.hasClients && _kpis.isNotEmpty) {
        setState(() {
          _currentKpiIndex = (_currentKpiIndex + 1) % _kpis.length;
          _kpiController.animateToPage(
            _currentKpiIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        });
      }

      if (_graficosController.hasClients && _graficosDisponibles.isNotEmpty) {
        setState(() {
          _currentGraficoIndex = (_currentGraficoIndex + 1) % _graficosDisponibles.length;
          _graficosController.animateToPage(
            _currentGraficoIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        });
      }
    });

    // 🔁 Refresco automático de datos
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _cargarTodosLosDatos();
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _kpiController.dispose();
    _graficosController.dispose();
    super.dispose();
  }

  Future<void> _cargarTodosLosDatos() async {
    await Future.wait([
      fetchStockBajo(),
      fetchResumen(),
      fetchProductosMasVendidos(),
      fetchClientesTop(),
      fetchProveedoresTop(),
      fetchVentasPorComuna(),
      fetchMargenesProductos(),
    ]);
  }

  // 📊 Datos de los KPIs
  List<Map<String, String>> get _kpis => [
    {
      "title": "Total Ventas",
      "value": resumen["total_ventas"]?.toString() ?? "0",
      "icon": "💰",
      "color": "0xFF4CAF50"
    },
    {
      "title": "Ingresos",
      "value": "\$${(resumen["suma_ventas"] ?? 0).toStringAsFixed(0)}",
      "icon": "📈",
      "color": "0xFF2196F3"
    },
    {
      "title": "Total Compras",
      "value": resumen["total_compras"]?.toString() ?? "0",
      "icon": "🛒",
      "color": "0xFFFF9800"
    },
    {
      "title": "Gastos",
      "value": "\$${(resumen["suma_compras"] ?? 0).toStringAsFixed(0)}",
      "icon": "💸",
      "color": "0xFFF44336"
    },
    {
      "title": "Clientes",
      "value": resumen["total_clientes"]?.toString() ?? "0",
      "icon": "👥",
      "color": "0xFF9C27B0"
    },
    {
      "title": "Proveedores",
      "value": resumen["total_proveedores"]?.toString() ?? "0",
      "icon": "🏢",
      "color": "0xFF607D8B"
    },
    {
      "title": "Productos",
      "value": resumen["total_productos"]?.toString() ?? "0",
      "icon": "📦",
      "color": "0xFF795548"
    },
  ];

  // Lista de gráficos disponibles — siempre se muestran los 5 gráficos
  List<Map<String, dynamic>> get _graficosDisponibles {
    return [
      {
        'titulo': 'Productos Más Vendidos',
        'tipo': 'productos_vendidos',
        'icon': '🔥'
      },
      {
        'titulo': 'Mejores Clientes',
        'tipo': 'clientes_top',
        'icon': '👑'
      },
      {
        'titulo': 'Proveedores Principales',
        'tipo': 'proveedores_top',
        'icon': '🚚'
      },
      {
        'titulo': 'Ventas por Comuna',
        'tipo': 'ventas_comuna',
        'icon': '🗺️'
      },
      {
        'titulo': 'Margen de Productos',
        'tipo': 'margenes',
        'icon': '💹'
      },
    ];
  }

  // 📈 FUNCIONES PARA CARGAR DATOS
  Future<void> fetchStockBajo() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/productos/stock-bajo"));
      if (resp.statusCode == 200) {
        setState(() {
          stockBajo = json.decode(resp.body);
        });
      }
    } catch (e) {
      debugPrint("Error cargando stock bajo: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchResumen() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/dashboard/resumen"));
      if (resp.statusCode == 200) {
        setState(() {
          resumen = json.decode(resp.body);
        });
      }
    } catch (e) {
      debugPrint("Error cargando resumen: $e");
    }
  }

  Future<void> fetchProductosMasVendidos() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/dashboard/productos-mas-vendidos"));
      if (resp.statusCode == 200) {
        setState(() {
          productosMasVendidos = List<Map<String, dynamic>>.from(json.decode(resp.body));
        });
      }
    } catch (e) {
      debugPrint("Error productos más vendidos: $e");
    }
  }

  Future<void> fetchClientesTop() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/dashboard/clientes-top"));
      if (resp.statusCode == 200) {
        setState(() {
          clientesTop = List<Map<String, dynamic>>.from(json.decode(resp.body));
        });
      }
    } catch (e) {
      debugPrint("Error clientes top: $e");
    }
  }

  Future<void> fetchProveedoresTop() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/dashboard/proveedores-top"));
      if (resp.statusCode == 200) {
        setState(() {
          proveedoresTop = List<Map<String, dynamic>>.from(json.decode(resp.body));
        });
      }
    } catch (e) {
      debugPrint("Error proveedores top: $e");
    }
  }

  Future<void> fetchVentasPorComuna() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/dashboard/ventas-por-comuna"));
      if (resp.statusCode == 200) {
        setState(() {
          ventasPorComuna = List<Map<String, dynamic>>.from(json.decode(resp.body));
        });
      }
    } catch (e) {
      debugPrint("Error ventas por comuna: $e");
    }
  }

  Future<void> fetchMargenesProductos() async {
    try {
      final resp = await http.get(Uri.parse("$baseUrl/dashboard/margenes-productos"));
      if (resp.statusCode == 200) {
        setState(() {
          margenesProductos = List<Map<String, dynamic>>.from(json.decode(resp.body));
        });
      }
    } catch (e) {
      debugPrint("Error márgenes productos: $e");
    }
  }

  // 🟣 CARRUSEL DE KPIs MEJORADO
  Widget _buildKpiCarousel() {
    if (_kpis.isEmpty) {
      return _buildPlaceholder('Cargando métricas...', '📊');
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _kpiController,
            itemCount: _kpis.length,
            onPageChanged: (index) => setState(() => _currentKpiIndex = index),
            itemBuilder: (context, index) {
              final kpi = _kpis[index];
              return _buildKpiCard(kpi, index == _currentKpiIndex);
            },
          ),
        ),
        _buildCarouselIndicators(_kpis.length, _currentKpiIndex),
      ],
    );
  }

  Widget _buildKpiCard(Map<String, String> kpi, bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(int.parse(kpi["color"]!)),
            Color(int.parse(kpi["color"]!)).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive ? [
          BoxShadow(
            color: Color(int.parse(kpi["color"]!)).withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kpi["icon"]!,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 10),
          Text(
            kpi["value"]!,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            kpi["title"]!,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 📊 CARRUSEL DE GRÁFICOS
  Widget _buildGraficosCarousel() {
    if (_graficosDisponibles.isEmpty) {
      return _buildPlaceholder('Cargando gráficos...', '📈');
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _graficosController,
            itemCount: _graficosDisponibles.length,
            onPageChanged: (index) => setState(() => _currentGraficoIndex = index),
            itemBuilder: (context, index) {
              final grafico = _graficosDisponibles[index];
              return _buildGraficoCard(grafico, index == _currentGraficoIndex);
            },
          ),
        ),
        _buildCarouselIndicators(_graficosDisponibles.length, _currentGraficoIndex),
      ],
    );
  }

  Widget _buildGraficoCard(Map<String, dynamic> grafico, bool isActive) {
    return Card(
      elevation: isActive ? 8 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  grafico['icon'],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    grafico['titulo'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildGraficoPorTipo(grafico['tipo']),
            ),
          ],
        ),
      ),
    );
  }

  // 🎨 CONSTRUIR GRÁFICOS POR TIPO
  Widget _buildGraficoPorTipo(String tipo) {
    switch (tipo) {
      case 'productos_vendidos':
        return _buildGraficoProductosVendidos();
      case 'clientes_top':
        return _buildGraficoClientesTop();
      case 'proveedores_top':
        return _buildGraficoProveedoresTop();
      case 'ventas_comuna':
        return _buildGraficoVentasPorComuna();
      case 'margenes':
        return _buildGraficoMargenes();
      default:
        return _buildPlaceholder('Gráfico no disponible', '📊');
    }
  }

  Widget _buildGraficoProductosVendidos() {
    if (productosMasVendidos.isEmpty) {
      return _buildPlaceholder('No hay datos de productos vendidos', '😴');
    }

    final datos = productosMasVendidos.take(8).toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Unidades Vendidas'),
      ),
      series: <CartesianSeries>[
        BarSeries<Map<String, dynamic>, String>(
          dataSource: datos,
          xValueMapper: (data, _) => data['nombre']?.toString() ?? 'Sin nombre',
          yValueMapper: (data, _) => (data['total_vendido'] ?? 0).toDouble(),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          color: Colors.blue,
        )
      ],
    );
  }

  Widget _buildGraficoClientesTop() {
    if (clientesTop.isEmpty) {
      return _buildPlaceholder('No hay datos de clientes', '👥');
    }

    final datos = clientesTop.take(6).toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Monto Gastado (\$)'),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: datos,
          xValueMapper: (data, _) => data['nombre']?.toString() ?? 'Sin nombre',
          yValueMapper: (data, _) => (data['monto_total'] ?? data['total_gastado'] ?? 0).toDouble(),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          color: Colors.green,
        )
      ],
    );
  }

  Widget _buildGraficoVentasPorComuna() {
    if (ventasPorComuna.isEmpty) {
      return _buildPlaceholder('No hay datos por comuna', '🗺️');
    }

    final datos = ventasPorComuna.take(8).toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Monto Total (\$)'),
      ),
      series: <CartesianSeries>[
        BarSeries<Map<String, dynamic>, String>(
          dataSource: datos,
          xValueMapper: (data, _) => data['comuna']?.toString() ?? 'Sin comuna',
          yValueMapper: (data, _) => (data['monto_total'] ?? 0).toDouble(),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          color: Colors.purple,
        )
      ],
    );
  }

  Widget _buildGraficoMargenes() {
    if (margenesProductos.isEmpty) {
      return _buildPlaceholder('No hay datos de márgenes', '💹');
    }

    final datos = margenesProductos.take(8).toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Margen (%)'),
      ),
      series: <CartesianSeries>[
        LineSeries<Map<String, dynamic>, String>(
          dataSource: datos,
          xValueMapper: (data, _) => data['nombre']?.toString() ?? 'Sin nombre',
          yValueMapper: (data, _) => (data['margen_porcentaje'] ?? 0).toDouble(),
          dataLabelSettings: const DataLabelSettings(isVisible: true),
          color: Colors.orange,
          markerSettings: const MarkerSettings(isVisible: true),
        )
      ],
    );
  }

  Widget _buildGraficoProveedoresTop() {
    if (proveedoresTop.isEmpty) {
      return _buildPlaceholder('No hay datos de compras a proveedores', '🏢');
    }

    final datos = proveedoresTop.take(8).toList();

    return SfCartesianChart(
      primaryXAxis: CategoryAxis(
        labelRotation: -45,
        labelStyle: const TextStyle(fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(text: 'Monto Compras (\$)'),
        numberFormat: NumberFormat.compactCurrency(symbol: '\$'),
      ),
      series: <CartesianSeries>[
        ColumnSeries<Map<String, dynamic>, String>(
          dataSource: datos,
          xValueMapper: (data, _) => data['nombre']?.toString() ?? 'Sin nombre',
          yValueMapper: (data, _) => (data['monto_total_compras'] ?? data['monto_total'] ?? 0).toDouble(),
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelAlignment: ChartDataLabelAlignment.top,
          ),
          color: Colors.teal,
          // Efecto de gradiente
          gradient: LinearGradient(
            colors: [Colors.teal.shade600, Colors.teal.shade300],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        )
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true,
        format: 'point.x : \$point.y',
      ),
    );
  }
  // 🎯 INDICADORES DE CARRUSEL
  Widget _buildCarouselIndicators(int length, int currentIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index ? Colors.deepPurple : Colors.grey,
          ),
        );
      }),
    );
  }

  // 📦 WIDGETS AUXILIARES
  Widget _buildPlaceholder(String message, String emoji) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 🔴 ALERTA DE STOCK BAJO
  Widget _buildStockBajoAlert() {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                const Text(
                  "Productos con Stock Bajo",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                Badge(
                  backgroundColor: Colors.red,
                  label: Text(stockBajo.length.toString()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            loading
                ? const LinearProgressIndicator()
                : stockBajo.isEmpty
                ? const Text("✅ No hay productos con stock bajo")
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: stockBajo.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p["nombre"] ?? "Sin nombre",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Chip(
                        label: Text("Stock: ${p["stock"]}"),
                        backgroundColor: Colors.red.shade100,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(parentContext: context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PRIMERA FILA: KPIs y Gráficos
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  // 🟣 Carrusel de KPIs
                  Expanded(
                    flex: 1,
                    child: _buildKpiCarousel(),
                  ),
                  const SizedBox(width: 16),
                  // 📊 Carrusel de Gráficos
                  Expanded(
                    flex: 2,
                    child: _buildGraficosCarousel(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 🔴 Alerta de Stock Bajo
            _buildStockBajoAlert(),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text("Descargar Reporte PDF de Inventario"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () async {
                final reportService = ReportService();
                await reportService.downloadInventoryReport();
              },
            ),

          ],
        ),
      ),
    );
  }
}