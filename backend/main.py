# main.py
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List

from db import (
    init_db,
    listar_productos, insertar_producto, obtener_producto, actualizar_producto, eliminar_producto,
    listar_proveedores, insertar_proveedor, obtener_proveedor, actualizar_proveedor, eliminar_proveedor,
    listar_clientes, insertar_cliente, obtener_cliente, actualizar_cliente, eliminar_cliente,
    insertar_venta, listar_ventas, obtener_venta, eliminar_venta,listar_compras, insertar_compra, obtener_compra, eliminar_compra,
    listar_mermas, insertar_merma, eliminar_merma, obtener_productos_mas_vendidos, obtener_clientes_top, obtener_proveedores_top,
    obtener_ventas_por_comuna, obtener_margenes_productos
)
from reports import router as reports_router

# Inicializar DB
init_db()

app = FastAPI(title="API de Inventario")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(reports_router)
# ------------------------
# MODELOS Pydantic
# ------------------------
class Producto(BaseModel):
    nombre: str
    descripcion: Optional[str] = ""
    precio_compra: Optional[float] = 0.0
    precio_venta: Optional[float] = 0.0
    stock: Optional[int] = 0
    stock_minimo: Optional[int] = 0

class Proveedor(BaseModel):
    nombre: str
    telefono: Optional[str] = None
    direccion: Optional[str] = None
    rut: Optional[str] = None
    comuna: Optional[str] = None

class Cliente(BaseModel):
    nombre: str
    telefono: Optional[str] = None
    direccion: Optional[str] = None
    rut: Optional[str] = None
    comuna: Optional[str] = None

class ItemVenta(BaseModel):
    id_producto: int
    cantidad: int

class Venta(BaseModel):
    id_cliente: Optional[int] = None
    productos: List[ItemVenta]
    descuento: Optional[float] = 0.0

class ItemCompra(BaseModel):
    id_producto: int
    cantidad: int
    precio_unitario: Optional[float] = None

class Compra(BaseModel):
    id_proveedor: Optional[int] = None
    productos: List[ItemCompra]

class Merma(BaseModel):
    id_producto: int
    cantidad: int
    motivo: str
    observacion: Optional[str] = ""

# ------------------------
# ENDPOINTS PRODUCTOS
# ------------------------
@app.get("/productos")
def api_listar_productos():
    return listar_productos()

@app.get("/productos/stock-bajo")
def api_stock_bajo():
    productos = listar_productos()
    return [p for p in productos if p["stock"] <= p["stock_minimo"]]    

@app.post("/productos")
def api_insertar_producto(producto: Producto):
    return {"id_producto": insertar_producto(producto.dict())}

@app.get("/productos/{id_producto}")
def api_obtener_producto(id_producto: int):
    prod = obtener_producto(id_producto)
    if not prod:
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return prod

@app.put("/productos/{id_producto}")
def api_actualizar_producto(id_producto: int, producto: Producto):
    if not actualizar_producto(id_producto, producto.dict()):
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return {"mensaje": "Producto actualizado"}

@app.delete("/productos/{id_producto}")
def api_eliminar_producto(id_producto: int):
    if not eliminar_producto(id_producto):
        raise HTTPException(status_code=404, detail="Producto no encontrado")
    return {"mensaje": "Producto eliminado"}



# ------------------------
# ENDPOINTS PROVEEDORES
# ------------------------
@app.get("/proveedores")
def api_listar_proveedores():
    return listar_proveedores()

@app.post("/proveedores")
def api_insertar_proveedor(proveedor: Proveedor):
    return {"id_proveedor": insertar_proveedor(proveedor.dict())}

@app.get("/proveedores/{id_proveedor}")
def api_obtener_proveedor(id_proveedor: int):
    prov = obtener_proveedor(id_proveedor)
    if not prov:
        raise HTTPException(status_code=404, detail="Proveedor no encontrado")
    return prov

@app.put("/proveedores/{id_proveedor}")
def api_actualizar_proveedor(id_proveedor: int, proveedor: Proveedor):
    if not actualizar_proveedor(id_proveedor, proveedor.dict()):
        raise HTTPException(status_code=404, detail="Proveedor no encontrado")
    return {"mensaje": "Proveedor actualizado"}

@app.delete("/proveedores/{id_proveedor}")
def api_eliminar_proveedor(id_proveedor: int):
    if not eliminar_proveedor(id_proveedor):
        raise HTTPException(status_code=404, detail="Proveedor no encontrado")
    return {"mensaje": "Proveedor eliminado"}

# ------------------------
# ENDPOINTS CLIENTES
# ------------------------
@app.get("/clientes")
def api_listar_clientes():
    return listar_clientes()

@app.post("/clientes", status_code=201)
def api_insertar_cliente(cliente: Cliente):
    return {"id_cliente": insertar_cliente(cliente.dict())}


@app.get("/clientes/{id_cliente}")
def api_obtener_cliente(id_cliente: int):
    cli = obtener_cliente(id_cliente)
    if not cli:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return cli

@app.put("/clientes/{id_cliente}")
def api_actualizar_cliente(id_cliente: int, cliente: Cliente):
    if not actualizar_cliente(id_cliente, cliente.dict()):
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return {"mensaje": "Cliente actualizado"}

@app.delete("/clientes/{id_cliente}")
def api_eliminar_cliente(id_cliente: int):
    if not eliminar_cliente(id_cliente):
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
    return {"mensaje": "Cliente eliminado"}

# ------------------------
# ENDPOINTS VENTAS
# ------------------------
@app.get("/ventas")
def api_listar_ventas():
    return listar_ventas()

@app.post("/ventas")
def api_insertar_venta(venta: Venta):
    try:
        id_venta = insertar_venta(venta.id_cliente, [item.dict() for item in venta.productos], venta.descuento)
        return {"id_venta": id_venta}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/ventas/{id_venta}")
def api_obtener_venta(id_venta: int):
    venta = obtener_venta(id_venta)
    if not venta:
        raise HTTPException(status_code=404, detail="Venta no encontrada")
    return venta

@app.delete("/ventas/{id_venta}")
def api_eliminar_venta(id_venta: int):
    if not eliminar_venta(id_venta):
        raise HTTPException(status_code=404, detail="Venta no encontrada")
    return {"mensaje": "Venta eliminada"}
#-- resumen--
@app.get("/dashboard/resumen")
def api_resumen_dashboard():
    productos = listar_productos()
    clientes = listar_clientes()
    proveedores = listar_proveedores()
    ventas = listar_ventas()
    compras = listar_compras()

    total_productos = len(productos)
    total_clientes = len(clientes)
    total_proveedores = len(proveedores)
    total_ventas = len(ventas)
    total_compras = len(compras)
    suma_ventas = sum(v["total"] for v in ventas)
    suma_compras = sum(c["total"] for c in compras)

    return {
        "total_productos": total_productos,
        "total_clientes": total_clientes,
        "total_proveedores": total_proveedores,
        "total_ventas": total_ventas,
        "suma_ventas": suma_ventas,
        "total_compras": total_compras,     
        "suma_compras": suma_compras        
    }

@app.get("/compras")
def api_listar_compras():
    return listar_compras()

@app.post("/compras")
def api_insertar_compra(compra: Compra):
    try:
        id_compra = insertar_compra(compra.id_proveedor, [item.dict() for item in compra.productos])
        return {"id_compra": id_compra}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@app.get("/compras/{id_compra}")
def api_obtener_compra(id_compra: int):
    compra = obtener_compra(id_compra)
    if not compra:
        raise HTTPException(status_code=404, detail="Compra no encontrada")
    return compra

@app.delete("/compras/{id_compra}")
def api_eliminar_compra(id_compra: int):
    if not eliminar_compra(id_compra):
        raise HTTPException(status_code=404, detail="Compra no encontrada")
    return {"mensaje": "Compra eliminada"}    

@app.get("/mermas")
def api_listar_mermas():
    return listar_mermas()

@app.post("/mermas")
def api_insertar_merma(merma: Merma):
    try:
        id_merma = insertar_merma(
            merma.id_producto, merma.cantidad, merma.motivo, merma.observacion
        )
        return {"id_merma": id_merma}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@app.delete("/mermas/{id_merma}")
def api_eliminar_merma(id_merma: int):
    if not eliminar_merma(id_merma):
        raise HTTPException(status_code=404, detail="Merma no encontrada")
    return {"mensaje": "Merma eliminada"}

# Agregar después de los otros endpoints existentes

@app.get("/dashboard/productos-mas-vendidos")
def api_productos_mas_vendidos():
    return obtener_productos_mas_vendidos()

@app.get("/dashboard/clientes-top")
def api_clientes_top():
    return obtener_clientes_top()

@app.get("/dashboard/proveedores-top")  
def api_proveedores_top():
    return obtener_proveedores_top()

@app.get("/dashboard/ventas-por-comuna")
def api_ventas_por_comuna():
    return obtener_ventas_por_comuna()

@app.get("/dashboard/margenes-productos")
def api_margenes_productos():
    return obtener_margenes_productos()