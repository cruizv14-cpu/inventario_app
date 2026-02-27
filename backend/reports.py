# reports.py
from fastapi import APIRouter, Response, Query
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
from reportlab.platypus import Table, TableStyle
import io
from collections import Counter, defaultdict
from datetime import datetime

from db import (
    listar_productos,
    listar_ventas_periodo,
    listar_compras_periodo,
    listar_mermas_periodo,
)

router = APIRouter(prefix="/reportes", tags=["Reportes"])

def _safe_float(value):
    try:
        return float(value)
    except:
        return 0.0

def _fmt_date(fecha_str):
    """Formatea la fecha para mostrar en el PDF."""
    if not fecha_str:
        return "-"
    try:
        if hasattr(fecha_str, 'strftime'):
            return fecha_str.strftime("%d/%m/%Y")
        dt = datetime.fromisoformat(str(fecha_str).replace("Z", "+00:00"))
        return dt.strftime("%d/%m/%Y")
    except:
        return str(fecha_str)[:10]


@router.get("/pdf")
def generar_reporte_pdf(
    fecha_desde: str = Query(..., description="Fecha inicio YYYY-MM-DD"),
    fecha_hasta: str = Query(..., description="Fecha fin YYYY-MM-DD"),
):
    # ==========================
    # 1) OBTENER DATOS
    # ==========================
    productos    = listar_productos()
    ventas       = listar_ventas_periodo(fecha_desde, fecha_hasta)
    compras      = listar_compras_periodo(fecha_desde, fecha_hasta)
    mermas       = listar_mermas_periodo(fecha_desde, fecha_hasta)

    fecha_generacion = datetime.now().strftime("%d/%m/%Y %H:%M")

    # ---- Inventario ----
    inventario = []
    valor_total_inventario = 0.0
    alertas_stock = []

    for p in productos:
        stock      = int(p.get("stock") or 0)
        stock_min  = int(p.get("stock_minimo") or 0)
        p_compra   = _safe_float(p.get("precio_compra") or 0)
        p_venta    = _safe_float(p.get("precio_venta") or 0)
        valor      = stock * p_compra
        valor_total_inventario += valor
        inventario.append({
            "nombre": p.get("nombre", "?"),
            "stock": stock,
            "stock_min": stock_min,
            "p_compra": p_compra,
            "p_venta": p_venta,
            "valor": valor,
        })
        if stock <= stock_min:
            alertas_stock.append({"nombre": p.get("nombre", "?"), "stock": stock, "stock_min": stock_min})

    # ---- Ventas periodo ----
    total_ventas   = len(ventas)
    suma_ventas    = sum(_safe_float(v.get("total") or 0)    for v in ventas)
    suma_descuento = sum(_safe_float(v.get("descuento") or 0) for v in ventas)
    suma_iva       = sum(_safe_float(v.get("iva") or 0)       for v in ventas)

    # Ranking productos más vendidos
    prod_qty = defaultdict(int)
    prod_monto = defaultdict(float)
    for v in ventas:
        for item in v.get("items", []):
            nombre = item.get("producto", "?")
            prod_qty[nombre]   += int(item.get("cantidad") or 0)
            prod_monto[nombre] += _safe_float(item.get("subtotal") or 0)

    top_productos = sorted(prod_qty.items(), key=lambda x: x[1], reverse=True)[:5]

    # Ranking clientes
    cliente_monto = defaultdict(float)
    for v in ventas:
        cliente = v.get("cliente") or "Sin cliente"
        cliente_monto[cliente] += _safe_float(v.get("total") or 0)
    top_clientes = sorted(cliente_monto.items(), key=lambda x: x[1], reverse=True)[:5]

    # ---- Compras periodo ----
    total_compras  = len(compras)
    suma_compras   = sum(_safe_float(c.get("total") or 0) for c in compras)

    prov_monto = defaultdict(float)
    for c in compras:
        prov = c.get("proveedor") or "Sin proveedor"
        prov_monto[prov] += _safe_float(c.get("total") or 0)
    top_proveedores = sorted(prov_monto.items(), key=lambda x: x[1], reverse=True)[:5]

    # ---- Mermas periodo ----
    total_mermas    = len(mermas)
    cant_merma_total = sum(int(m.get("cantidad") or 0)  for m in mermas)

    merma_qty = defaultdict(int)
    for m in mermas:
        merma_qty[m.get("producto", "?")] += int(m.get("cantidad") or 0)
    top_mermas = sorted(merma_qty.items(), key=lambda x: x[1], reverse=True)[:5]

    # Valor estimado de pérdida por merma (a precio de compra)
    precio_map = {p["nombre"]: _safe_float(p.get("precio_compra") or 0) for p in productos}
    valor_merma = sum(qty * precio_map.get(nombre, 0) for nombre, qty in merma_qty.items())

    # Ganancia neta
    ganancia_neta = suma_ventas - suma_compras - valor_merma

    # ==========================
    # 2) GENERAR PDF
    # ==========================
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4
    margin = 15 * mm
    col_w = width - 2 * margin

    # Paleta de colores
    COLOR_PRIMARY   = colors.HexColor("#1a3a5c")  # Azul oscuro
    COLOR_ACCENT    = colors.HexColor("#2e86ab")  # Azul medio
    COLOR_SUCCESS   = colors.HexColor("#27ae60")  # Verde
    COLOR_WARNING   = colors.HexColor("#e67e22")  # Naranja
    COLOR_DANGER    = colors.HexColor("#c0392b")  # Rojo
    COLOR_LIGHT     = colors.HexColor("#f0f4f8")  # Gris claro
    COLOR_DARK_TEXT = colors.HexColor("#1c1c2e")  # Texto oscuro

    y = height - margin

    def check_page(needed=20 * mm):
        nonlocal y
        if y < needed:
            c.showPage()
            y = height - margin

    def draw_header_band():
        """Dibuja banda de color para separar secciones."""
        nonlocal y
        check_page(40 * mm)
        c.setFillColor(COLOR_PRIMARY)
        c.rect(margin - 2, y - 6, col_w + 4, 10, fill=1, stroke=0)

    def section_title(title: str, number: str):
        nonlocal y
        check_page(30 * mm)
        y -= 8 * mm
        c.setFillColor(COLOR_PRIMARY)
        c.rect(margin - 2, y - 5, col_w + 4, 9 * mm, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont("Helvetica-Bold", 11)
        c.drawString(margin + 2, y, f"{number}  {title}")
        c.setFillColor(COLOR_DARK_TEXT)
        y -= 8 * mm

    def kpi_row(labels_values, cols=3):
        """Dibuja una fila de KPIs tipo tarjeta."""
        nonlocal y
        check_page(25 * mm)
        cell_w = col_w / cols
        for i, (label, value, color) in enumerate(labels_values[:cols]):
            x = margin + i * cell_w
            c.setFillColor(COLOR_LIGHT)
            c.roundRect(x + 1, y - 14 * mm, cell_w - 4, 14 * mm, 3, fill=1, stroke=0)
            c.setFillColor(color)
            c.setFont("Helvetica-Bold", 13)
            c.drawString(x + 4, y - 7 * mm, str(value))
            c.setFillColor(colors.gray)
            c.setFont("Helvetica", 7)
            c.drawString(x + 4, y - 12 * mm, label)
        y -= 18 * mm

    def simple_table(headers, rows, col_widths):
        """Dibuja una tabla simple con reportlab."""
        nonlocal y
        check_page(30 * mm)
        # Encabezado
        c.setFillColor(COLOR_ACCENT)
        c.rect(margin, y - 6 * mm, col_w, 6 * mm, fill=1, stroke=0)
        c.setFillColor(colors.white)
        c.setFont("Helvetica-Bold", 8)
        x_cur = margin + 2
        for i, h in enumerate(headers):
            c.drawString(x_cur, y - 4 * mm, h)
            x_cur += col_widths[i]
        y -= 6 * mm
        # Filas
        c.setFont("Helvetica", 8)
        for ri, row in enumerate(rows):
            check_page(8 * mm)
            if ri % 2 == 0:
                c.setFillColor(COLOR_LIGHT)
                c.rect(margin, y - 5 * mm, col_w, 5 * mm, fill=1, stroke=0)
            c.setFillColor(COLOR_DARK_TEXT)
            x_cur = margin + 2
            for i, cell in enumerate(row):
                c.drawString(x_cur, y - 3.5 * mm, str(cell)[:40])
                x_cur += col_widths[i]
            y -= 5 * mm
        y -= 3 * mm

    # =============================================
    # PORTADA
    # =============================================
    # Banda superior
    c.setFillColor(COLOR_PRIMARY)
    c.rect(0, height - 45 * mm, width, 45 * mm, fill=1, stroke=0)

    c.setFillColor(colors.white)
    c.setFont("Helvetica-Bold", 20)
    c.drawCentredString(width / 2, height - 22 * mm, "INFORME DE INVENTARIO")
    c.setFont("Helvetica", 11)
    c.drawCentredString(width / 2, height - 30 * mm, "Huevos MARA — Sistema de Gestión")

    # Banda inferior portada
    c.setFillColor(COLOR_ACCENT)
    c.rect(0, height - 52 * mm, width, 7 * mm, fill=1, stroke=0)
    c.setFillColor(colors.white)
    c.setFont("Helvetica", 9)
    c.drawCentredString(width / 2, height - 49 * mm,
        f"Período: {fecha_desde.replace('-', '/')}  →  {fecha_hasta.replace('-', '/')}")

    y = height - 62 * mm

    # Info general
    c.setFillColor(COLOR_DARK_TEXT)
    c.setFont("Helvetica", 9)
    c.drawString(margin, y, f"Generado: {fecha_generacion}")
    c.drawRightString(width - margin, y, f"Total productos en sistema: {len(productos)}")
    y -= 12 * mm

    # =============================================
    # SECCIÓN 0: RESUMEN EJECUTIVO
    # =============================================
    section_title("Resumen Ejecutivo", "0.")

    kpi_row([
        ("Ventas brutas", f"${suma_ventas:,.0f}", COLOR_SUCCESS),
        ("Compras (inversión)", f"${suma_compras:,.0f}", COLOR_WARNING),
        ("Valor en bodega", f"${valor_total_inventario:,.0f}", COLOR_ACCENT),
    ])
    kpi_row([
        ("Pérdida por mermas", f"${valor_merma:,.0f}", COLOR_DANGER),
        ("Ganancia estimada", f"${ganancia_neta:,.0f}",
            COLOR_SUCCESS if ganancia_neta >= 0 else COLOR_DANGER),
        ("Alertas de stock bajo", str(len(alertas_stock)), COLOR_WARNING),
    ])

    # =============================================
    # SECCIÓN 1: INVENTARIO ACTUAL
    # =============================================
    section_title("Inventario Actual (estado presente)", "1.")
    check_page(35 * mm)

    c.setFont("Helvetica", 9)
    c.setFillColor(colors.darkgray)
    c.drawString(margin, y, "Refleja el estado de stock al momento de generar este informe.")
    y -= 6 * mm

    headers = ["Producto", "Stock", "Mín", "P.Compra", "P.Venta", "Valor bodega"]
    widths  = [65 * mm, 15 * mm, 15 * mm, 22 * mm, 22 * mm, 28 * mm]
    rows = []
    for p in sorted(inventario, key=lambda x: x["nombre"]):
        rows.append([
            p["nombre"][:35],
            str(p["stock"]),
            str(p["stock_min"]),
            f"${p['p_compra']:,.0f}",
            f"${p['p_venta']:,.0f}",
            f"${p['valor']:,.0f}",
        ])
    simple_table(headers, rows, widths)

    # Total
    c.setFont("Helvetica-Bold", 9)
    c.setFillColor(COLOR_PRIMARY)
    c.drawString(margin, y, f"Valor total del inventario: ${valor_total_inventario:,.0f}")
    y -= 10 * mm

    # =============================================
    # SECCIÓN 2: VENTAS DEL PERÍODO
    # =============================================
    section_title("Ventas del Período", "2.")

    kpi_row([
        ("N° ventas", str(total_ventas), COLOR_PRIMARY),
        ("Total facturado", f"${suma_ventas:,.0f}", COLOR_SUCCESS),
        ("Descuentos otorgados", f"${suma_descuento:,.0f}", COLOR_WARNING),
    ])
    kpi_row([
        ("IVA recaudado (19%)", f"${suma_iva:,.0f}", COLOR_ACCENT),
        ("Ticket promedio", f"${(suma_ventas/total_ventas if total_ventas else 0):,.0f}", COLOR_PRIMARY),
        ("", "", colors.white),
    ])

    if top_productos:
        check_page(20 * mm)
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(COLOR_PRIMARY)
        c.drawString(margin, y, "Top 5 Productos más vendidos:")
        y -= 5 * mm
        simple_table(
            ["Producto", "Cant. vendida", "Monto total"],
            [(n, str(q), f"${prod_monto.get(n, 0):,.0f}") for n, q in top_productos],
            [100 * mm, 35 * mm, 40 * mm],
        )
    else:
        c.setFont("Helvetica", 9)
        c.setFillColor(colors.gray)
        c.drawString(margin, y, "Sin ventas en el período seleccionado.")
        y -= 7 * mm

    if top_clientes:
        check_page(15 * mm)
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(COLOR_PRIMARY)
        c.drawString(margin, y, "Top 5 Clientes por monto:")
        y -= 5 * mm
        simple_table(
            ["Cliente", "Total comprado"],
            [(n, f"${m:,.0f}") for n, m in top_clientes],
            [120 * mm, 50 * mm],
        )

    # =============================================
    # SECCIÓN 3: COMPRAS DEL PERÍODO
    # =============================================
    section_title("Compras del Período", "3.")

    kpi_row([
        ("N° compras", str(total_compras), COLOR_PRIMARY),
        ("Total invertido", f"${suma_compras:,.0f}", COLOR_WARNING),
        ("Compra promedio", f"${(suma_compras/total_compras if total_compras else 0):,.0f}", COLOR_ACCENT),
    ])

    if top_proveedores:
        check_page(15 * mm)
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(COLOR_PRIMARY)
        c.drawString(margin, y, "Top 5 Proveedores por inversión:")
        y -= 5 * mm
        simple_table(
            ["Proveedor", "Total comprado"],
            [(n, f"${m:,.0f}") for n, m in top_proveedores],
            [120 * mm, 50 * mm],
        )
    else:
        c.setFont("Helvetica", 9)
        c.setFillColor(colors.gray)
        c.drawString(margin, y, "Sin compras en el período seleccionado.")
        y -= 7 * mm

    # =============================================
    # SECCIÓN 4: MERMAS DEL PERÍODO
    # =============================================
    section_title("Mermas del Período", "4.")

    kpi_row([
        ("N° eventos de merma", str(total_mermas), COLOR_DANGER),
        ("Unidades perdidas", str(cant_merma_total), COLOR_DANGER),
        ("Valor pérdida estimada", f"${valor_merma:,.0f}", COLOR_DANGER),
    ])

    if top_mermas:
        check_page(15 * mm)
        c.setFont("Helvetica-Bold", 9)
        c.setFillColor(COLOR_PRIMARY)
        c.drawString(margin, y, "Productos con más merma:")
        y -= 5 * mm
        simple_table(
            ["Producto", "Unidades perdidas"],
            [(n, str(q)) for n, q in top_mermas],
            [120 * mm, 50 * mm],
        )
    else:
        c.setFont("Helvetica", 9)
        c.setFillColor(COLOR_SUCCESS)
        c.drawString(margin, y, "✓ Sin mermas registradas en el período.")
        y -= 7 * mm

    # =============================================
    # SECCIÓN 5: ALERTAS DE STOCK BAJO
    # =============================================
    section_title("Alertas — Productos con Stock Bajo o Agotado", "5.")

    if alertas_stock:
        simple_table(
            ["Producto", "Stock actual", "Stock mínimo", "¿Agotado?"],
            [
                (a["nombre"][:35], str(a["stock"]), str(a["stock_min"]),
                 "SÍ" if a["stock"] == 0 else "—")
                for a in sorted(alertas_stock, key=lambda x: x["stock"])
            ],
            [90 * mm, 25 * mm, 25 * mm, 27 * mm],
        )
    else:
        c.setFont("Helvetica", 9)
        c.setFillColor(COLOR_SUCCESS)
        c.drawString(margin, y, "✓ Todos los productos están dentro del rango de stock mínimo.")
        y -= 7 * mm

    # =============================================
    # FOOTER EN TODAS LAS PÁGINAS
    # =============================================
    c.setFont("Helvetica", 7)
    c.setFillColor(colors.gray)
    for page_num in range(1, c.getPageNumber() + 1):
        c.drawString(margin, 12 * mm,
            f"Informe generado automáticamente · Huevos MARA · {fecha_generacion}")
        c.drawRightString(width - margin, 12 * mm, f"Página {page_num}")

    c.save()
    buffer.seek(0)

    nombre_archivo = f"reporte_inventario_{fecha_desde}_{fecha_hasta}.pdf"

    return Response(
        content=buffer.getvalue(),
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{nombre_archivo}"'}
    )
