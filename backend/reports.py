# reports.py
from fastapi import APIRouter, Response
from reportlab.lib.pagesizes import A4
from reportlab.pdfgen import canvas
from reportlab.lib.units import mm
import io
from collections import Counter
from datetime import datetime

from db import (
    listar_productos,
    listar_ventas,
    listar_compras,
    listar_proveedores,
    listar_clientes,
    listar_mermas
)

# Prefijo agregado -> ahora tu endpoint será /reportes/pdf
router = APIRouter(prefix="/reportes", tags=["Reportes"])

def _safe_float(value):
    try:
        return float(value)
    except:
        return 0.0

@router.get("/pdf")
def generar_reporte_pdf():
    # ==========================
    # 1) OBTENER DATOS
    # ==========================
    productos = listar_productos()
    ventas = listar_ventas()
    compras = listar_compras()
    proveedores = listar_proveedores()
    clientes = listar_clientes()
    mermas = listar_mermas()

    # Fecha actual
    fecha_actual = datetime.now().strftime("%d-%m-%Y %H:%M")

    # ==========================
    # 2) INVENTARIO
    # ==========================
    inventario = []
    valor_total_inventario = 0.0

    for p in productos:
        stock = p.get("stock", 0) or 0
        precio_compra = _safe_float(p.get("precio_compra", 0))
        valor = stock * precio_compra
        valor_total_inventario += valor

        inventario.append({
            "id_producto": p.get("id_producto"),
            "nombre": p.get("nombre"),
            "stock": stock,
            "precio_compra": precio_compra,
            "valor": valor
        })

    # ==========================
    # 3) RESUMEN VENTAS / COMPRAS
    # ==========================
    suma_ventas = sum(_safe_float(v.get("total", 0)) for v in ventas)
    suma_compras = sum(_safe_float(c.get("total", 0)) for c in compras)
    ganancia_aproximada = suma_ventas - suma_compras

    # ==========================
    # 4) RANKING
    # ==========================
    # Productos más vendidos
    prod_contador = Counter()

    for v in ventas:
        if isinstance(v.get("productos"), list):
            for item in v["productos"]:
                pid = item.get("id_producto")
                cantidad = item.get("cantidad", 1)
                prod_contador[pid] += cantidad

    id2nombre = {p["id_producto"]: p.get("nombre") for p in productos}

    productos_mas_vendidos = [
        {"id_producto": pid, "nombre": id2nombre.get(pid, str(pid)), "cantidad": qty}
        for pid, qty in prod_contador.most_common(10)
    ]

    # Clientes top
    cliente_totales = {}
    for v in ventas:
        id_cliente = v.get("id_cliente", "Sin cliente")
        total = _safe_float(v.get("total", 0))
        cliente_totales[id_cliente] = cliente_totales.get(id_cliente, 0) + total

    id2cliente = {c["id_cliente"]: c.get("nombre") for c in clientes}

    clientes_top = sorted(
        [{"id_cliente": k, "nombre": id2cliente.get(k, str(k)), "monto": v} 
         for k, v in cliente_totales.items()],
        key=lambda x: x["monto"], 
        reverse=True
    )[:10]

    # Proveedores top
    prov_totales = {}
    for c in compras:
        id_prov = c.get("id_proveedor", "Sin proveedor")
        total = _safe_float(c.get("total", 0))
        prov_totales[id_prov] = prov_totales.get(id_prov, 0) + total

    id2prov = {p["id_proveedor"]: p.get("nombre") for p in proveedores}

    proveedores_top = sorted(
        [{"id_proveedor": k, "nombre": id2prov.get(k, str(k)), "monto": v}
         for k, v in prov_totales.items()],
        key=lambda x: x["monto"],
        reverse=True
    )[:10]

    # ==========================
    # 5) GENERAR PDF
    # ==========================
    buffer = io.BytesIO()
    c = canvas.Canvas(buffer, pagesize=A4)
    width, height = A4

    margin = 15 * mm
    y = height - 20 * mm

    def nueva_linea(space=7*mm):
        nonlocal y
        y -= space
        if y < 25 * mm:
            c.showPage()
            c.setFont("Helvetica", 10)
            y = height - 20 * mm

    # ==========================
    # HEADER
    # ==========================
    c.setFont("Helvetica-Bold", 16)
    c.drawString(margin, y, "Informe Completo de Inventario - Huevos MARA")
    nueva_linea(12*mm)

    c.setFont("Helvetica", 10)
    c.drawString(margin, y, f"Productos totales: {len(productos)}")
    c.drawString(margin + 90*mm, y, f"Generado: {fecha_actual}")
    nueva_linea(10*mm)

    # ==========================
    # (1) Inventario
    # ==========================
    c.setFont("Helvetica-Bold", 12)
    c.drawString(margin, y, "1) Inventario Actual")
    nueva_linea(7*mm)

    c.setFont("Helvetica-Bold", 9)
    c.drawString(margin, y, "ID")
    c.drawString(margin + 15*mm, y, "Producto")
    c.drawString(margin + 80*mm, y, "Stock")
    c.drawString(margin + 105*mm, y, "Precio compra")
    c.drawString(margin + 145*mm, y, "Valor total")
    nueva_linea(5*mm)

    c.setFont("Helvetica", 9)
    for p in inventario:
        c.drawString(margin, y, str(p["id_producto"]))
        c.drawString(margin + 15*mm, y, str(p["nombre"])[:30])
        c.drawString(margin + 80*mm, y, str(p["stock"]))
        c.drawRightString(margin + 125*mm, y, f"${p['precio_compra']:.0f}")
        c.drawRightString(margin + 170*mm, y, f"${p['valor']:.0f}")
        nueva_linea(4*mm)

    nueva_linea(8*mm)
    c.setFont("Helvetica-Bold", 10)
    c.drawString(margin, y, f"Valor total de inventario: ${valor_total_inventario:.0f}")
    nueva_linea(12*mm)

    # ==========================
    # (2) Movimientos
    # ==========================
    c.setFont("Helvetica-Bold", 12)
    c.drawString(margin, y, "2) Resumen de Movimientos")
    nueva_linea(7*mm)

    c.setFont("Helvetica", 10)
    c.drawString(margin, y, f"Total ventas: ${suma_ventas:.0f}")
    c.drawString(margin + 80*mm, y, f"Total compras: ${suma_compras:.0f}")
    nueva_linea(7*mm)

    c.drawString(margin, y, f"Ganancia aproximada: ${ganancia_aproximada:.0f}")
    nueva_linea(10*mm)

    # ==========================
    # (3) Rankings
    # ==========================
    c.setFont("Helvetica-Bold", 12)
    c.drawString(margin, y, "3) Rankings")
    nueva_linea(7*mm)

    # Productos más vendidos
    c.setFont("Helvetica-Bold", 10)
    c.drawString(margin, y, "Productos más vendidos")
    nueva_linea(6*mm)
    c.setFont("Helvetica", 9)

    if productos_mas_vendidos:
        for p in productos_mas_vendidos:
            c.drawString(margin, y, f"{p['nombre']} - {p['cantidad']} unidades")
            nueva_linea(4*mm)
    else:
        c.drawString(margin, y, "No hay detalle suficiente para calcular cantidad vendida.")
        nueva_linea(8*mm)

    nueva_linea(5*mm)

    # Clientes top
    c.setFont("Helvetica-Bold", 10)
    c.drawString(margin, y, "Clientes con más compras")
    nueva_linea(6*mm)

    c.setFont("Helvetica", 9)
    for cl in clientes_top:
        c.drawString(margin, y, f"{cl['nombre']} - ${cl['monto']:.0f}")
        nueva_linea(4*mm)

    nueva_linea(5*mm)

    # Proveedores top
    c.setFont("Helvetica-Bold", 10)
    c.drawString(margin, y, "Proveedores más utilizados")
    nueva_linea(6*mm)

    c.setFont("Helvetica", 9)
    for pr in proveedores_top:
        c.drawString(margin, y, f"{pr['nombre']} - ${pr['monto']:.0f}")
        nueva_linea(4*mm)

    # ==========================
    # FOOTER
    # ==========================
    nueva_linea(15*mm)
    c.setFont("Helvetica", 8)
    c.drawString(margin, 20*mm, "Generado automáticamente por el sistema de Inventario - Huevos MARA")

    c.save()
    buffer.seek(0)

    return Response(
        content=buffer.getvalue(),
        media_type="application/pdf",
        headers={"Content-Disposition": 'attachment; filename=\"reporte_inventario.pdf\"'}
    )
