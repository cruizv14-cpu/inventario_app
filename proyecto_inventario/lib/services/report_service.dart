import 'dart:io' show File, Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// PARA WEB
import 'dart:html' as html;

// PARA MÓVIL / ESCRITORIO
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReportService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://127.0.0.1:8000",
    responseType: ResponseType.bytes,
  ));

  /// 🔹 Descargar PDF de inventario completo
  Future<void> downloadInventoryReport() async {
    try {
      // 🔥 Ruta corregida
      final response = await _dio.get("/reportes/pdf");

      final pdfBytes = response.data;

      if (kIsWeb) {
        // 🌐 DESCARGA PARA FLUTTER WEB
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..download = "reporte_inventario.pdf"
          ..click();

        html.Url.revokeObjectUrl(url);
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
