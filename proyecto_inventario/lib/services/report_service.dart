import 'dart:io' show File;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/constants.dart';

// Importación Condicional para Flutter Web
import 'web_download_stub.dart'
    if (dart.library.html) 'web_download_web.dart'
    if (dart.library.io) 'web_download_io.dart';

// PARA MÓVIL / ESCRITORIO
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReportService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: apiBaseUrl,
    responseType: ResponseType.bytes,
  ));

  /// Descargar PDF filtrado por rango de fechas
  Future<void> downloadInventoryReport({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final fechaDesde = "${desde.year.toString().padLeft(4, '0')}-"
        "${desde.month.toString().padLeft(2, '0')}-"
        "${desde.day.toString().padLeft(2, '0')}";
    final fechaHasta = "${hasta.year.toString().padLeft(4, '0')}-"
        "${hasta.month.toString().padLeft(2, '0')}-"
        "${hasta.day.toString().padLeft(2, '0')}";

    try {
      final response = await _dio.get(
        "/reportes/pdf",
        queryParameters: {
          "fecha_desde": fechaDesde,
          "fecha_hasta": fechaHasta,
        },
      );

      final pdfBytes = response.data;

      if (kIsWeb) {
        downloadFileWeb(pdfBytes, 'reporte_inventario_${fechaDesde}_${fechaHasta}.pdf');
        return;
      }

      // 📱 DESCARGA PARA ANDROID / WINDOWS
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/reporte_inventario.pdf";
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);
      await OpenFilex.open(filePath);
    } catch (e) {
      print("❌ Error descargando PDF: $e");
      rethrow;
    }
  }
}
