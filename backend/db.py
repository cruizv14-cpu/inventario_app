# db.py
import sqlite3
from pathlib import Path

# Ruta donde se guardará la base de datos
DB_PATH = Path(__file__).with_name("inventario.db")

# Conexión a la base de datos
def get_connection():
    con = sqlite3.connect(DB_PATH, check_same_thread=False)
    con.row_factory = sqlite3.Row
    return con

# ------------------------
# CREAR TABLAS SI NO EXISTEN
# ------------------------
def init_db():
    con = get_connection()
    cur = con.cursor()

    # Tabla Productos
    cur.execute("""
    CREATE TABLE IF NOT EXISTS productos (
        id_producto     INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre          TEXT NOT NULL,
        descripcion     TEXT,
        precio_compra   REAL DEFAULT 0,
        precio_venta    REAL DEFAULT 0,
        stock           INTEGER DEFAULT 0,
        stock_minimo    INTEGER DEFAULT 0
    );
    """)

    # Tabla Proveedores
    cur.execute("""
    CREATE TABLE IF NOT EXISTS proveedores (
        id_proveedor INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT,
        rut TEXT,
        comuna TEXT
    );
    """)

    # Tabla Clientes
    cur.execute("""
    CREATE TABLE IF NOT EXISTS clientes (
        id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        telefono TEXT,
        direccion TEXT,
        rut TEXT,
        comuna TEXT
    );
    """)

    # Tabla Ventas (cabecera)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS ventas (
        id_venta INTEGER PRIMARY KEY AUTOINCREMENT,
        id_cliente INTEGER,
        fecha TEXT DEFAULT (datetime('now','localtime')),
        subtotal REAL NOT NULL,
        descuento REAL DEFAULT 0,
        iva REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente)
    );
    """)

    # Tabla Detalle de Ventas
    cur.execute("""
    CREATE TABLE IF NOT EXISTS detalle_ventas (
        id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
        id_venta INTEGER NOT NULL,
        id_producto INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (id_venta) REFERENCES ventas(id_venta),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    );
    """)
        # Tabla Compras (cabecera)
    cur.execute("""
    CREATE TABLE IF NOT EXISTS compras (
        id_compra INTEGER PRIMARY KEY AUTOINCREMENT,
        id_proveedor INTEGER,
        fecha TEXT DEFAULT (datetime('now','localtime')),
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        FOREIGN KEY (id_proveedor) REFERENCES proveedores(id_proveedor)
    );
    """)

    # Tabla Detalle de Compras
    cur.execute("""
    CREATE TABLE IF NOT EXISTS detalle_compras (
        id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
        id_compra INTEGER NOT NULL,
        id_producto INTEGER NOT NULL,
        cantidad INTEGER NOT NULL,
        precio_unitario REAL NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (id_compra) REFERENCES compras(id_compra),
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    );
    """)
        # Tabla Mermas
    cur.execute("""
    CREATE TABLE IF NOT EXISTS mermas (
        id_merma INTEGER PRIMARY KEY AUTOINCREMENT,
        id_producto INTEGER NOT NULL,
        fecha TEXT DEFAULT (datetime('now','localtime')),
        cantidad INTEGER NOT NULL,
        motivo TEXT NOT NULL,
        observacion TEXT,
        FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
    );
    """)



    con.commit()
    con.close()

# ------------------------
# CRUD PRODUCTOS
# ------------------------
def listar_productos():
    con = get_connection()
    cur = con.execute("SELECT * FROM productos ORDER BY id_producto DESC")
    rows = [dict(r) for r in cur.fetchall()]
    con.close()
    return rows

def insertar_producto(data: dict) -> int:
    con = get_connection()
    cur = con.execute("""
        INSERT INTO productos (nombre, descripcion, precio_compra, precio_venta, stock, stock_minimo)
        VALUES (?, ?, ?, ?, ?, ?)
    """, (
        data.get("nombre"),
        data.get("descripcion"),
        data.get("precio_compra", 0.0),
        data.get("precio_venta", 0.0),
        data.get("stock", 0),
        data.get("stock_minimo", 0),
    ))
    con.commit()
    new_id = cur.lastrowid
    con.close()
    return new_id

def obtener_producto(id_producto: int) -> dict | None:
    con = get_connection()
    cur = con.execute("SELECT * FROM productos WHERE id_producto = ?", (id_producto,))
    row = cur.fetchone()
    con.close()
    return dict(row) if row else None

def actualizar_producto(id_producto: int, data: dict) -> bool:
    con = get_connection()
    cur = con.execute("""
        UPDATE productos
        SET nombre = ?, descripcion = ?, precio_compra = ?, precio_venta = ?, stock = ?, stock_minimo = ?
        WHERE id_producto = ?
    """, (
        data.get("nombre"),
        data.get("descripcion"),
        data.get("precio_compra", 0.0),
        data.get("precio_venta", 0.0),
        data.get("stock", 0),
        data.get("stock_minimo", 0),
        id_producto
    ))
    con.commit()
    ok = (cur.rowcount > 0)
    con.close()
    return ok

def eliminar_producto(id_producto: int) -> bool:
    con = get_connection()
    cur = con.execute("DELETE FROM productos WHERE id_producto = ?", (id_producto,))
    con.commit()
    ok = (cur.rowcount > 0)
    con.close()
    return ok

# ------------------------
# CRUD PROVEEDORES
# ------------------------
def listar_proveedores():
    con = get_connection()
    cur = con.cursor()
    cur.execute("SELECT * FROM proveedores")
    rows = cur.fetchall()
    con.close()
    return [dict(row) for row in rows]

def insertar_proveedor(data: dict) -> int:
    con = get_connection()
    cur = con.cursor()
    cur.execute("""
        INSERT INTO proveedores (nombre, telefono, direccion, rut, comuna)
        VALUES (?, ?, ?, ?, ?)
    """, (data["nombre"], data.get("telefono"), data.get("direccion"),data.get("rut"), data.get("comuna")))
    con.commit()
    new_id = cur.lastrowid
    con.close()
    return new_id

def obtener_proveedor(id_proveedor: int):
    con = get_connection()
    cur = con.cursor()
    cur.execute("SELECT * FROM proveedores WHERE id_proveedor = ?", (id_proveedor,))
    row = cur.fetchone()
    con.close()
    return dict(row) if row else None

def actualizar_proveedor(id_proveedor: int, datos: dict) -> bool:
    con = get_connection()
    cur = con.cursor()
    cur.execute("""
        UPDATE proveedores
        SET nombre = ?, telefono = ?, direccion = ?, rut= ?, comuna= ?
        WHERE id_proveedor = ?
    """, (datos["nombre"], datos.get("telefono"), datos.get("direccion"),datos.get("rut"), datos.get("comuna"), id_proveedor))
    con.commit()
    ok = cur.rowcount > 0
    con.close()
    return ok

def eliminar_proveedor(id_proveedor: int) -> bool:
    con = get_connection()
    cur = con.cursor()
    cur.execute("DELETE FROM proveedores WHERE id_proveedor = ?", (id_proveedor,))
    con.commit()
    ok = cur.rowcount > 0
    con.close()
    return ok

# ------------------------
# CRUD CLIENTES
# ------------------------
def listar_clientes():
    con = get_connection()
    cur = con.cursor()
    cur.execute("SELECT * FROM clientes")
    rows = cur.fetchall()
    con.close()
    return [dict(row) for row in rows]

def insertar_cliente(cliente: dict) -> int:
    con = get_connection()
    cur = con.cursor()
    cur.execute(
        "INSERT INTO clientes (nombre, telefono, direccion, rut, comuna) VALUES (?, ?, ?, ?, ?)",
        (cliente["nombre"], cliente.get("telefono"), cliente.get("direccion"), cliente.get("rut"), cliente.get("comuna")),
    )
    con.commit()
    new_id = cur.lastrowid
    con.close()
    return new_id

def obtener_cliente(id_cliente: int):
    con = get_connection()
    cur = con.cursor()
    cur.execute("SELECT * FROM clientes WHERE id_cliente = ?", (id_cliente,))
    row = cur.fetchone()
    con.close()
    return dict(row) if row else None

def actualizar_cliente(id_cliente: int, cliente: dict) -> bool:
    con = get_connection()
    cur = con.cursor()
    cur.execute(
        """
        UPDATE clientes
        SET nombre = ?, telefono = ?, direccion = ?, rut= ?, comuna= ?
        WHERE id_cliente = ?
        """,
        (cliente["nombre"], cliente.get("telefono"), cliente.get("direccion"), cliente.get("rut"), cliente.get("comuna"), id_cliente),
    )
    con.commit()
    ok = cur.rowcount > 0
    con.close()
    return ok

def eliminar_cliente(id_cliente: int) -> bool:
    con = get_connection()
    cur = con.cursor()
    cur.execute("DELETE FROM clientes WHERE id_cliente = ?", (id_cliente,))
    con.commit()
    ok = cur.rowcount > 0
    con.close()
    return ok

# ------------------------
# CRUD VENTAS Y DETALLE VENTAS
# ------------------------
def insertar_venta(id_cliente: int | None, productos: list, descuento: float = 0.0) -> int:
    """
    Inserta una venta con múltiples productos.
    productos = [{"id_producto": 1, "cantidad": 2}, {"id_producto": 3, "cantidad": 1}]
    """
    con = get_connection()
    cur = con.cursor()

    subtotal = 0.0
    detalle_data = []

    # Calcular subtotales y verificar stock
    for item in productos:
        id_producto = item["id_producto"]
        cantidad = item["cantidad"]

        # Obtener info del producto
        cur.execute("SELECT precio_venta, stock FROM productos WHERE id_producto = ?", (id_producto,))
        row = cur.fetchone()
        if not row:
            con.close()
            raise ValueError(f"Producto {id_producto} no existe")
        precio_unitario, stock_actual = row

        if cantidad > stock_actual:
            con.close()
            raise ValueError(f"Stock insuficiente para producto {id_producto}")

        sub = precio_unitario * cantidad
        subtotal += sub
        detalle_data.append((id_producto, cantidad, precio_unitario, sub))

    # Aplicar descuento y calcular IVA
    subtotal_con_descuento = subtotal - descuento
    iva = round(subtotal_con_descuento * 0.19, 2)
    total = subtotal_con_descuento + iva

    # Insertar cabecera de la venta
    cur.execute("""
        INSERT INTO ventas (id_cliente, subtotal, descuento, iva, total)
        VALUES (?, ?, ?, ?, ?)
    """, (id_cliente, subtotal_con_descuento, descuento, iva, total))
    id_venta = cur.lastrowid

    # Insertar detalle y actualizar stock
    for id_producto, cantidad, precio_unitario, sub in detalle_data:
        cur.execute("""
            INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (?, ?, ?, ?, ?)
        """, (id_venta, id_producto, cantidad, precio_unitario, sub))

        cur.execute("UPDATE productos SET stock = stock - ? WHERE id_producto = ?", (cantidad, id_producto))

    con.commit()
    con.close()
    return id_venta

def listar_ventas():
    con = get_connection()
    cur = con.cursor()
    cur.execute("""
        SELECT v.id_venta, v.fecha, c.nombre AS cliente, v.subtotal, v.descuento, v.iva, v.total
        FROM ventas v
        LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
        ORDER BY v.id_venta DESC
    """)
    rows = [dict(zip([col[0] for col in cur.description], r)) for r in cur.fetchall()]
    con.close()
    return rows

def obtener_venta(id_venta: int):
    con = get_connection()
    cur = con.cursor()

    # Cabecera
    cur.execute("""
        SELECT v.id_venta, v.fecha, c.nombre AS cliente, v.subtotal, v.descuento, v.iva, v.total
        FROM ventas v
        LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
        WHERE v.id_venta = ?
    """, (id_venta,))
    cabecera = cur.fetchone()
    if not cabecera:
        con.close()
        return None
    cabecera = dict(zip([col[0] for col in cur.description], cabecera))

    # Detalle
    cur.execute("""
        SELECT d.id_detalle, p.nombre AS producto, d.cantidad, d.precio_unitario, d.subtotal
        FROM detalle_ventas d
        JOIN productos p ON d.id_producto = p.id_producto
        WHERE d.id_venta = ?
    """, (id_venta,))
    detalle = [dict(zip([col[0] for col in cur.description], r)) for r in cur.fetchall()]

    con.close()
    return {"venta": cabecera, "detalle": detalle}

def eliminar_venta(id_venta: int) -> bool:
    """
    Elimina una venta y devuelve stock a los productos.
    """
    con = get_connection()
    cur = con.cursor()

    # Recuperar detalle antes de borrar
    cur.execute("SELECT id_producto, cantidad FROM detalle_ventas WHERE id_venta = ?", (id_venta,))
    productos = cur.fetchall()

    if not productos:
        con.close()
        return False

    # Devolver stock
    for id_producto, cantidad in productos:
        cur.execute("UPDATE productos SET stock = stock + ? WHERE id_producto = ?", (cantidad, id_producto))

    # Eliminar detalle y cabecera
    cur.execute("DELETE FROM detalle_ventas WHERE id_venta = ?", (id_venta,))
    cur.execute("DELETE FROM ventas WHERE id_venta = ?", (id_venta,))

    con.commit()
    borrado = cur.rowcount > 0
    con.close()
    return borrado

# ------------------------
# CRUD COMPRAS Y DETALLE COMPRAS
# ------------------------
def insertar_compra(id_proveedor: int | None, productos: list) -> int:
    """
    Inserta una compra con múltiples productos.
    productos = [{"id_producto": 1, "cantidad": 5, "precio_unitario": 1200.0}]
    """
    con = get_connection()
    cur = con.cursor()

    subtotal = 0.0
    detalle_data = []

    # Calcular subtotales y verificar productos
    for item in productos:
        id_producto = item["id_producto"]
        cantidad = item["cantidad"]
        precio_unitario = item.get("precio_unitario")

        if precio_unitario is None:
            # Obtener el precio_compra actual del producto si no viene en el cuerpo
            cur.execute("SELECT precio_compra FROM productos WHERE id_producto = ?", (id_producto,))
            row = cur.fetchone()
            if not row:
                con.close()
                raise ValueError(f"Producto {id_producto} no existe")
            precio_unitario = row[0]

        sub = precio_unitario * cantidad
        subtotal += sub
        detalle_data.append((id_producto, cantidad, precio_unitario, sub))

    total = subtotal  # Sin IVA

    # Insertar cabecera
    cur.execute("""
        INSERT INTO compras (id_proveedor, subtotal, total)
        VALUES (?, ?, ?)
    """, (id_proveedor, subtotal, total))
    id_compra = cur.lastrowid

    # Insertar detalle y actualizar stock (+)
    for id_producto, cantidad, precio_unitario, sub in detalle_data:
        cur.execute("""
            INSERT INTO detalle_compras (id_compra, id_producto, cantidad, precio_unitario, subtotal)
            VALUES (?, ?, ?, ?, ?)
        """, (id_compra, id_producto, cantidad, precio_unitario, sub))

        cur.execute("UPDATE productos SET stock = stock + ? WHERE id_producto = ?", (cantidad, id_producto))

    con.commit()
    con.close()
    return id_compra


def listar_compras():
    con = get_connection()
    cur = con.cursor()
    cur.execute("""
        SELECT c.id_compra, c.fecha, p.nombre AS proveedor, c.subtotal, c.total
        FROM compras c
        LEFT JOIN proveedores p ON c.id_proveedor = p.id_proveedor
        ORDER BY c.id_compra DESC
    """)
    rows = [dict(zip([col[0] for col in cur.description], r)) for r in cur.fetchall()]
    con.close()
    return rows


def obtener_compra(id_compra: int):
    con = get_connection()
    cur = con.cursor()

    cur.execute("""
        SELECT c.id_compra, p.nombre AS proveedor, c.fecha, c.total
        FROM compras c
        LEFT JOIN proveedores p ON c.id_proveedor = p.id_proveedor
        WHERE c.id_compra = ?
    """, (id_compra,))
    cabecera = cur.fetchone()
    if not cabecera:
        con.close()
        return None
    cabecera = dict(zip([col[0] for col in cur.description], cabecera))

    # Detalle
    cur.execute("""
        SELECT d.id_detalle, pr.nombre AS producto, d.cantidad, d.precio_unitario, d.subtotal
        FROM detalle_compras d
        JOIN productos pr ON d.id_producto = pr.id_producto
        WHERE d.id_compra = ?
    """, (id_compra,))
    detalle = [dict(zip([col[0] for col in cur.description], r)) for r in cur.fetchall()]

    con.close()
    return {"compra": cabecera, "detalle": detalle}



def eliminar_compra(id_compra: int) -> bool:
    """
    Elimina una compra y resta el stock de los productos involucrados.
    """
    con = get_connection()
    cur = con.cursor()

    # Recuperar detalle antes de borrar
    cur.execute("SELECT id_producto, cantidad FROM detalle_compras WHERE id_compra = ?", (id_compra,))
    productos = cur.fetchall()

    if not productos:
        con.close()
        return False

    # Restar stock
    for id_producto, cantidad in productos:
        cur.execute("UPDATE productos SET stock = stock - ? WHERE id_producto = ?", (cantidad, id_producto))

    # Eliminar detalle y cabecera
    cur.execute("DELETE FROM detalle_compras WHERE id_compra = ?", (id_compra,))
    cur.execute("DELETE FROM compras WHERE id_compra = ?", (id_compra,))

    con.commit()
    borrado = cur.rowcount > 0
    con.close()
    return borrado
   
# ------------------------
# CRUD MERMAS
# ------------------------
def insertar_merma(id_producto: int, cantidad: int, motivo: str, observacion: str = "") -> int:
    """
    Inserta una merma y descuenta el stock del producto.
    """
    con = get_connection()
    cur = con.cursor()

    # Verificar producto existente y stock suficiente
    cur.execute("SELECT stock FROM productos WHERE id_producto = ?", (id_producto,))
    row = cur.fetchone()
    if not row:
        con.close()
        raise ValueError(f"Producto {id_producto} no existe")

    stock_actual = row[0]
    if cantidad > stock_actual:
        con.close()
        raise ValueError("Stock insuficiente para registrar la merma")

    # Insertar la merma
    cur.execute("""
        INSERT INTO mermas (id_producto, cantidad, motivo, observacion)
        VALUES (?, ?, ?, ?)
    """, (id_producto, cantidad, motivo, observacion))
    id_merma = cur.lastrowid

    # Actualizar stock del producto
    cur.execute("UPDATE productos SET stock = stock - ? WHERE id_producto = ?", (cantidad, id_producto))

    con.commit()
    con.close()
    return id_merma


def listar_mermas():
    con = get_connection()
    cur = con.cursor()
    cur.execute("""
        SELECT m.id_merma, m.fecha, p.nombre AS producto, m.cantidad, m.motivo, m.observacion
        FROM mermas m
        JOIN productos p ON m.id_producto = p.id_producto
        ORDER BY m.id_merma DESC
    """)
    rows = [dict(zip([col[0] for col in cur.description], r)) for r in cur.fetchall()]
    con.close()
    return rows


def eliminar_merma(id_merma: int) -> bool:
    """
    Elimina una merma y devuelve el stock al producto.
    """
    con = get_connection()
    cur = con.cursor()

    cur.execute("SELECT id_producto, cantidad FROM mermas WHERE id_merma = ?", (id_merma,))
    row = cur.fetchone()
    if not row:
        con.close()
        return False

    id_producto, cantidad = row

    # Devolver stock al producto
    cur.execute("UPDATE productos SET stock = stock + ? WHERE id_producto = ?", (cantidad, id_producto))

    # Eliminar merma
    cur.execute("DELETE FROM mermas WHERE id_merma = ?", (id_merma,))
    con.commit()
    ok = cur.rowcount > 0
    con.close()
    return ok

def obtener_productos_mas_vendidos(limite=10):
    con = get_connection()
    cur = con.execute("""
        SELECT p.nombre, SUM(dv.cantidad) as total_vendido
        FROM detalle_ventas dv
        JOIN productos p ON dv.id_producto = p.id_producto
        GROUP BY p.id_producto, p.nombre
        ORDER BY total_vendido DESC
        LIMIT ?
    """, (limite,))
    rows = [dict(row) for row in cur.fetchall()]
    con.close()
    return rows

def obtener_clientes_top(limite=7):
    con = get_connection()
    cur = con.execute("""
        SELECT c.nombre, COUNT(v.id_venta) as total_ventas, SUM(v.total) as monto_total
        FROM ventas v
        JOIN clientes c ON v.id_cliente = c.id_cliente
        GROUP BY c.id_cliente, c.nombre
        ORDER BY total_ventas DESC, monto_total DESC
        LIMIT ?
    """, (limite,))
    rows = [dict(row) for row in cur.fetchall()]
    con.close()
    return rows

def obtener_proveedores_top(limite=10):
    con = get_connection()
    cur = con.execute("""
        SELECT 
            p.nombre,
            SUM(c.total) as monto_total_compras,
            COUNT(c.id_compra) as total_compras
        FROM proveedores p
        LEFT JOIN compras c ON p.id_proveedor = c.id_proveedor
        GROUP BY p.id_proveedor, p.nombre
        HAVING monto_total_compras > 0
        ORDER BY monto_total_compras DESC
        LIMIT ?
    """, (limite,))
    rows = [dict(row) for row in cur.fetchall()]
    con.close()
    return rows

def obtener_ventas_por_comuna():
    con = get_connection()
    cur = con.execute("""
        SELECT c.comuna, COUNT(v.id_venta) as total_ventas, SUM(v.total) as monto_total
        FROM ventas v
        JOIN clientes c ON v.id_cliente = c.id_cliente
        WHERE c.comuna IS NOT NULL AND c.comuna != ''
        GROUP BY c.comuna
        ORDER BY monto_total DESC
    """)
    rows = [dict(row) for row in cur.fetchall()]
    con.close()
    return rows

def obtener_margenes_productos():
    con = get_connection()
    cur = con.execute("""
        SELECT 
            p.nombre,
            p.precio_compra,
            p.precio_venta,
            (p.precio_venta - p.precio_compra) as margen_unitario,
            COALESCE(SUM(dv.cantidad), 0) as total_vendido,
            (p.precio_venta - p.precio_compra) * COALESCE(SUM(dv.cantidad), 0) as margen_total
        FROM productos p
        LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
        GROUP BY p.id_producto, p.nombre, p.precio_compra, p.precio_venta
        HAVING total_vendido > 0
        ORDER BY margen_total DESC
    """)
    rows = [dict(row) for row in cur.fetchall()]
    con.close()
    return rows

