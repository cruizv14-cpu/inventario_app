import os
import psycopg2
from psycopg2.extras import DictCursor
from psycopg2.pool import SimpleConnectionPool
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.getenv("DATABASE_URL")
if not DB_URL:
    raise ValueError("No DATABASE_URL found in environment")

# Create a connection pool connection
pool = SimpleConnectionPool(1, 20, DB_URL)

def get_connection():
    return pool.getconn()

def release_connection(con):
    pool.putconn(con)

# ------------------------
# CREAR TABLAS SI NO EXISTEN
# ------------------------
def init_db():
    con = get_connection()
    try:
        cur = con.cursor()

        cur.execute("""
        CREATE TABLE IF NOT EXISTS productos (
            id_producto     SERIAL PRIMARY KEY,
            nombre          TEXT NOT NULL,
            descripcion     TEXT,
            precio_compra   REAL DEFAULT 0,
            precio_venta    REAL DEFAULT 0,
            stock           INTEGER DEFAULT 0,
            stock_minimo    INTEGER DEFAULT 0
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS proveedores (
            id_proveedor SERIAL PRIMARY KEY,
            nombre TEXT NOT NULL,
            telefono TEXT,
            direccion TEXT,
            rut TEXT,
            comuna TEXT
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS clientes (
            id_cliente SERIAL PRIMARY KEY,
            nombre TEXT NOT NULL,
            telefono TEXT,
            direccion TEXT,
            rut TEXT,
            comuna TEXT
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS ventas (
            id_venta SERIAL PRIMARY KEY,
            id_cliente INTEGER REFERENCES clientes(id_cliente),
            fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            subtotal REAL NOT NULL,
            descuento REAL DEFAULT 0,
            iva REAL NOT NULL,
            total REAL NOT NULL
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS detalle_ventas (
            id_detalle SERIAL PRIMARY KEY,
            id_venta INTEGER NOT NULL REFERENCES ventas(id_venta) ON DELETE CASCADE,
            id_producto INTEGER NOT NULL REFERENCES productos(id_producto),
            cantidad INTEGER NOT NULL,
            precio_unitario REAL NOT NULL,
            subtotal REAL NOT NULL
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS compras (
            id_compra SERIAL PRIMARY KEY,
            id_proveedor INTEGER REFERENCES proveedores(id_proveedor),
            fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            subtotal REAL NOT NULL,
            total REAL NOT NULL
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS detalle_compras (
            id_detalle SERIAL PRIMARY KEY,
            id_compra INTEGER NOT NULL REFERENCES compras(id_compra) ON DELETE CASCADE,
            id_producto INTEGER NOT NULL REFERENCES productos(id_producto),
            cantidad INTEGER NOT NULL,
            precio_unitario REAL NOT NULL,
            subtotal REAL NOT NULL
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS mermas (
            id_merma SERIAL PRIMARY KEY,
            id_producto INTEGER NOT NULL REFERENCES productos(id_producto),
            fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            cantidad INTEGER NOT NULL,
            motivo TEXT NOT NULL,
            observacion TEXT
        );
        """)

        cur.execute("""
        CREATE TABLE IF NOT EXISTS usuarios (
            id SERIAL PRIMARY KEY,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            rol TEXT DEFAULT 'user'
        );
        """)

        con.commit()
    finally:
        release_connection(con)

def init_admin_user():
    import bcrypt

    admin_password = os.getenv("ADMIN_PASSWORD", "").strip()
    if not admin_password:
        print("⚠️  ADMIN_PASSWORD no configurada en .env — se omite creación del usuario admin.")
        return

    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT id FROM usuarios WHERE username = 'admin'")
        admin = cur.fetchone()

        if not admin:
            hashed_password = bcrypt.hashpw(
                admin_password.encode("utf-8"), bcrypt.gensalt()
            ).decode("utf-8")
            cur.execute("""
                INSERT INTO usuarios (username, password_hash, rol)
                VALUES (%s, %s, %s)
            """, ("admin", hashed_password, "admin"))
            con.commit()
            print("Usuario 'admin' creado exitosamente.")
    finally:
        release_connection(con)

# ------------------------
# CRUD USUARIOS
# ------------------------
def obtener_usuario_por_username(username: str):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM usuarios WHERE username = %s", (username,))
        row = cur.fetchone()
        return dict(row) if row else None
    finally:
        release_connection(con)


# ------------------------
# CRUD PRODUCTOS
# ------------------------
def listar_productos():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM productos ORDER BY id_producto DESC")
        return [dict(r) for r in cur.fetchall()]
    finally:
        release_connection(con)

def insertar_producto(data: dict) -> int:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("""
            INSERT INTO productos (nombre, descripcion, precio_compra, precio_venta, stock, stock_minimo)
            VALUES (%s, %s, %s, %s, %s, %s) RETURNING id_producto
        """, (
            data.get("nombre"),
            data.get("descripcion"),
            data.get("precio_compra", 0.0),
            data.get("precio_venta", 0.0),
            data.get("stock", 0),
            data.get("stock_minimo", 0),
        ))
        new_id = cur.fetchone()[0]
        con.commit()
        return new_id
    finally:
        release_connection(con)

def obtener_producto(id_producto: int) -> dict | None:
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM productos WHERE id_producto = %s", (id_producto,))
        row = cur.fetchone()
        return dict(row) if row else None
    finally:
        release_connection(con)

def actualizar_producto(id_producto: int, data: dict) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("""
            UPDATE productos
            SET nombre = %s, descripcion = %s, precio_compra = %s, precio_venta = %s, stock = %s, stock_minimo = %s
            WHERE id_producto = %s
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
        return cur.rowcount > 0
    finally:
        release_connection(con)

def eliminar_producto(id_producto: int) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("DELETE FROM productos WHERE id_producto = %s", (id_producto,))
        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

# ------------------------
# CRUD PROVEEDORES
# ------------------------
def listar_proveedores():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM proveedores")
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def insertar_proveedor(data: dict) -> int:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("""
            INSERT INTO proveedores (nombre, telefono, direccion, rut, comuna)
            VALUES (%s, %s, %s, %s, %s) RETURNING id_proveedor
        """, (data["nombre"], data.get("telefono"), data.get("direccion"),data.get("rut"), data.get("comuna")))
        new_id = cur.fetchone()[0]
        con.commit()
        return new_id
    finally:
        release_connection(con)

def obtener_proveedor(id_proveedor: int):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM proveedores WHERE id_proveedor = %s", (id_proveedor,))
        row = cur.fetchone()
        return dict(row) if row else None
    finally:
        release_connection(con)

def actualizar_proveedor(id_proveedor: int, datos: dict) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("""
            UPDATE proveedores
            SET nombre = %s, telefono = %s, direccion = %s, rut= %s, comuna= %s
            WHERE id_proveedor = %s
        """, (datos["nombre"], datos.get("telefono"), datos.get("direccion"),datos.get("rut"), datos.get("comuna"), id_proveedor))
        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

def eliminar_proveedor(id_proveedor: int) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("DELETE FROM proveedores WHERE id_proveedor = %s", (id_proveedor,))
        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

# ------------------------
# CRUD CLIENTES
# ------------------------
def listar_clientes():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM clientes")
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def insertar_cliente(cliente: dict) -> int:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute(
            "INSERT INTO clientes (nombre, telefono, direccion, rut, comuna) VALUES (%s, %s, %s, %s, %s) RETURNING id_cliente",
            (cliente["nombre"], cliente.get("telefono"), cliente.get("direccion"), cliente.get("rut"), cliente.get("comuna")),
        )
        new_id = cur.fetchone()[0]
        con.commit()
        return new_id
    finally:
        release_connection(con)

def obtener_cliente(id_cliente: int):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("SELECT * FROM clientes WHERE id_cliente = %s", (id_cliente,))
        row = cur.fetchone()
        return dict(row) if row else None
    finally:
        release_connection(con)

def actualizar_cliente(id_cliente: int, cliente: dict) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute(
            """
            UPDATE clientes
            SET nombre = %s, telefono = %s, direccion = %s, rut= %s, comuna= %s
            WHERE id_cliente = %s
            """,
            (cliente["nombre"], cliente.get("telefono"), cliente.get("direccion"), cliente.get("rut"), cliente.get("comuna"), id_cliente),
        )
        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

def eliminar_cliente(id_cliente: int) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()
        cur.execute("DELETE FROM clientes WHERE id_cliente = %s", (id_cliente,))
        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

# ------------------------
# CRUD VENTAS Y DETALLE VENTAS
# ------------------------
def insertar_venta(id_cliente: int | None, productos: list, descuento: float = 0.0) -> int:
    con = get_connection()
    try:
        cur = con.cursor()

        subtotal = 0.0
        detalle_data = []

        # Calcular subtotales y verificar stock
        for item in productos:
            id_producto = item["id_producto"]
            cantidad = item["cantidad"]

            cur.execute("SELECT precio_venta, stock FROM productos WHERE id_producto = %s", (id_producto,))
            row = cur.fetchone()
            if not row:
                raise ValueError(f"Producto {id_producto} no existe")
            precio_unitario, stock_actual = row

            if cantidad > stock_actual:
                raise ValueError(f"Stock insuficiente para producto {id_producto}")

            sub = float(precio_unitario) * cantidad
            subtotal += sub
            detalle_data.append((id_producto, cantidad, precio_unitario, sub))

        # Aplicar descuento y calcular IVA (Informativo)
        subtotal_con_descuento = subtotal - descuento
        iva = round(subtotal_con_descuento * 0.19, 2)
        total = subtotal_con_descuento  # El IVA no se suma al total

        # Insertar cabecera de la venta
        cur.execute("""
            INSERT INTO ventas (id_cliente, subtotal, descuento, iva, total)
            VALUES (%s, %s, %s, %s, %s) RETURNING id_venta
        """, (id_cliente, subtotal_con_descuento, descuento, iva, total))
        id_venta = cur.fetchone()[0]

        # Insertar detalle y actualizar stock
        for id_producto, cantidad, precio_unitario, sub in detalle_data:
            cur.execute("""
                INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, precio_unitario, subtotal)
                VALUES (%s, %s, %s, %s, %s)
            """, (id_venta, id_producto, cantidad, precio_unitario, sub))

            cur.execute("UPDATE productos SET stock = stock - %s WHERE id_producto = %s", (cantidad, id_producto))

        con.commit()
        return id_venta
    finally:
        release_connection(con)

def listar_ventas():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT v.id_venta, v.fecha, c.nombre AS cliente, v.subtotal, v.descuento, v.iva, v.total
            FROM ventas v
            LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
            ORDER BY v.id_venta DESC
        """)
        return [dict(r) for r in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_venta(id_venta: int):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)

        # Cabecera
        cur.execute("""
            SELECT v.id_venta, v.fecha, c.nombre AS cliente, v.subtotal, v.descuento, v.iva, v.total
            FROM ventas v
            LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
            WHERE v.id_venta = %s
        """, (id_venta,))
        cabecera = cur.fetchone()
        if not cabecera:
            return None

        # Detalle
        cur.execute("""
            SELECT d.id_detalle, p.nombre AS producto, d.cantidad, d.precio_unitario, d.subtotal
            FROM detalle_ventas d
            JOIN productos p ON d.id_producto = p.id_producto
            WHERE d.id_venta = %s
        """, (id_venta,))
        detalle = [dict(r) for r in cur.fetchall()]

        return {"venta": dict(cabecera), "detalle": detalle}
    finally:
        release_connection(con)

def eliminar_venta(id_venta: int) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()

        # Recuperar detalle antes de borrar
        cur.execute("SELECT id_producto, cantidad FROM detalle_ventas WHERE id_venta = %s", (id_venta,))
        productos = cur.fetchall()

        if not productos:
            return False

        # Devolver stock
        for id_producto, cantidad in productos:
            cur.execute("UPDATE productos SET stock = stock + %s WHERE id_producto = %s", (cantidad, id_producto))

        # Eliminar detalle y cabecera
        cur.execute("DELETE FROM detalle_ventas WHERE id_venta = %s", (id_venta,))
        cur.execute("DELETE FROM ventas WHERE id_venta = %s", (id_venta,))

        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

# ------------------------
# CRUD COMPRAS Y DETALLE COMPRAS
# ------------------------
def insertar_compra(id_proveedor: int | None, productos: list) -> int:
    con = get_connection()
    try:
        cur = con.cursor()

        subtotal = 0.0
        detalle_data = []

        for item in productos:
            id_producto = item["id_producto"]
            cantidad = item["cantidad"]
            precio_unitario = item.get("precio_unitario")

            if precio_unitario is None:
                cur.execute("SELECT precio_compra FROM productos WHERE id_producto = %s", (id_producto,))
                row = cur.fetchone()
                if not row:
                    raise ValueError(f"Producto {id_producto} no existe")
                precio_unitario = row[0]

            sub = float(precio_unitario) * cantidad
            subtotal += sub
            detalle_data.append((id_producto, cantidad, precio_unitario, sub))

        total = subtotal  # Sin IVA

        cur.execute("""
            INSERT INTO compras (id_proveedor, subtotal, total)
            VALUES (%s, %s, %s) RETURNING id_compra
        """, (id_proveedor, subtotal, total))
        id_compra = cur.fetchone()[0]

        for id_producto, cantidad, precio_unitario, sub in detalle_data:
            cur.execute("""
                INSERT INTO detalle_compras (id_compra, id_producto, cantidad, precio_unitario, subtotal)
                VALUES (%s, %s, %s, %s, %s)
            """, (id_compra, id_producto, cantidad, precio_unitario, sub))

            cur.execute("UPDATE productos SET stock = stock + %s WHERE id_producto = %s", (cantidad, id_producto))

        con.commit()
        return id_compra
    finally:
        release_connection(con)

def listar_compras():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT c.id_compra, c.fecha, p.nombre AS proveedor, c.subtotal, c.total
            FROM compras c
            LEFT JOIN proveedores p ON c.id_proveedor = p.id_proveedor
            ORDER BY c.id_compra DESC
        """)
        return [dict(r) for r in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_compra(id_compra: int):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)

        cur.execute("""
            SELECT c.id_compra, p.nombre AS proveedor, c.fecha, c.total
            FROM compras c
            LEFT JOIN proveedores p ON c.id_proveedor = p.id_proveedor
            WHERE c.id_compra = %s
        """, (id_compra,))
        cabecera = cur.fetchone()
        if not cabecera:
            return None

        # Detalle
        cur.execute("""
            SELECT d.id_detalle, pr.nombre AS producto, d.cantidad, d.precio_unitario, d.subtotal
            FROM detalle_compras d
            JOIN productos pr ON d.id_producto = pr.id_producto
            WHERE d.id_compra = %s
        """, (id_compra,))
        detalle = [dict(r) for r in cur.fetchall()]

        return {"compra": dict(cabecera), "detalle": detalle}
    finally:
        release_connection(con)


def eliminar_compra(id_compra: int) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()

        cur.execute("SELECT id_producto, cantidad FROM detalle_compras WHERE id_compra = %s", (id_compra,))
        productos = cur.fetchall()

        if not productos:
            return False

        for id_producto, cantidad in productos:
            cur.execute("UPDATE productos SET stock = stock - %s WHERE id_producto = %s", (cantidad, id_producto))

        cur.execute("DELETE FROM detalle_compras WHERE id_compra = %s", (id_compra,))
        cur.execute("DELETE FROM compras WHERE id_compra = %s", (id_compra,))

        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

# ------------------------
# CRUD MERMAS
# ------------------------
def insertar_merma(id_producto: int, cantidad: int, motivo: str, observacion: str = "") -> int:
    con = get_connection()
    try:
        cur = con.cursor()

        cur.execute("SELECT stock FROM productos WHERE id_producto = %s", (id_producto,))
        row = cur.fetchone()
        if not row:
            raise ValueError(f"Producto {id_producto} no existe")

        stock_actual = row[0]
        if cantidad > stock_actual:
            raise ValueError("Stock insuficiente para registrar la merma")

        cur.execute("""
            INSERT INTO mermas (id_producto, cantidad, motivo, observacion)
            VALUES (%s, %s, %s, %s) RETURNING id_merma
        """, (id_producto, cantidad, motivo, observacion))
        id_merma = cur.fetchone()[0]

        cur.execute("UPDATE productos SET stock = stock - %s WHERE id_producto = %s", (cantidad, id_producto))

        con.commit()
        return id_merma
    finally:
        release_connection(con)

def listar_mermas():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT m.id_merma, m.fecha, p.nombre AS producto, m.cantidad, m.motivo, m.observacion
            FROM mermas m
            JOIN productos p ON m.id_producto = p.id_producto
            ORDER BY m.id_merma DESC
        """)
        return [dict(r) for r in cur.fetchall()]
    finally:
        release_connection(con)

def eliminar_merma(id_merma: int) -> bool:
    con = get_connection()
    try:
        cur = con.cursor()

        cur.execute("SELECT id_producto, cantidad FROM mermas WHERE id_merma = %s", (id_merma,))
        row = cur.fetchone()
        if not row:
            return False

        id_producto, cantidad = row

        cur.execute("UPDATE productos SET stock = stock + %s WHERE id_producto = %s", (cantidad, id_producto))

        cur.execute("DELETE FROM mermas WHERE id_merma = %s", (id_merma,))
        con.commit()
        return cur.rowcount > 0
    finally:
        release_connection(con)

def obtener_productos_mas_vendidos(limite=10):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT p.nombre, SUM(dv.cantidad) as total_vendido
            FROM detalle_ventas dv
            JOIN productos p ON dv.id_producto = p.id_producto
            GROUP BY p.id_producto, p.nombre
            ORDER BY total_vendido DESC
            LIMIT %s
        """, (limite,))
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_clientes_top(limite=7):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT c.nombre, COUNT(v.id_venta) as total_ventas, SUM(v.total) as monto_total
            FROM ventas v
            JOIN clientes c ON v.id_cliente = c.id_cliente
            GROUP BY c.id_cliente, c.nombre
            ORDER BY total_ventas DESC, monto_total DESC
            LIMIT %s
        """, (limite,))
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_proveedores_top(limite=10):
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT 
                p.nombre,
                SUM(c.total) as monto_total_compras,
                COUNT(c.id_compra) as total_compras
            FROM proveedores p
            LEFT JOIN compras c ON p.id_proveedor = c.id_proveedor
            GROUP BY p.id_proveedor, p.nombre
            HAVING SUM(c.total) > 0
            ORDER BY monto_total_compras DESC
            LIMIT %s
        """, (limite,))
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_ventas_por_comuna():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT c.comuna, COUNT(v.id_venta) as total_ventas, SUM(v.total) as monto_total
            FROM ventas v
            JOIN clientes c ON v.id_cliente = c.id_cliente
            WHERE c.comuna IS NOT NULL AND c.comuna != ''
            GROUP BY c.comuna
            ORDER BY monto_total DESC
        """)
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_margenes_productos():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT 
                p.nombre,
                p.precio_compra,
                p.precio_venta,
                (p.precio_venta - p.precio_compra) as margen_unitario,
                CASE 
                    WHEN p.precio_compra > 0 
                    THEN ROUND((CAST((p.precio_venta - p.precio_compra) * 100.0 / p.precio_compra AS numeric)), 2)
                    ELSE 0
                END as margen_porcentaje,
                COALESCE(SUM(dv.cantidad), 0) as total_vendido,
                (p.precio_venta - p.precio_compra) * COALESCE(SUM(dv.cantidad), 0) as margen_total
            FROM productos p
            LEFT JOIN detalle_ventas dv ON p.id_producto = dv.id_producto
            WHERE p.precio_compra > 0 AND p.precio_venta > 0
            GROUP BY p.id_producto, p.nombre, p.precio_compra, p.precio_venta
            ORDER BY margen_porcentaje DESC
        """)
        return [dict(row) for row in cur.fetchall()]
    finally:
        release_connection(con)

def obtener_resumen_dashboard():
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        
        cur.execute("SELECT COUNT(*) FROM productos")
        total_productos = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM clientes")
        total_clientes = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*) FROM proveedores")
        total_proveedores = cur.fetchone()[0]
        
        cur.execute("SELECT COUNT(*), COALESCE(SUM(total), 0) FROM ventas")
        row_ventas = cur.fetchone()
        total_ventas = row_ventas[0]
        suma_ventas = float(row_ventas[1])
        
        cur.execute("SELECT COUNT(*), COALESCE(SUM(total), 0) FROM compras")
        row_compras = cur.fetchone()
        total_compras = row_compras[0]
        suma_compras = float(row_compras[1])
        
        return {
            "total_productos": total_productos,
            "total_clientes": total_clientes,
            "total_proveedores": total_proveedores,
            "total_ventas": total_ventas,
            "suma_ventas": suma_ventas,
            "total_compras": total_compras,     
            "suma_compras": suma_compras 
        }
    except Exception as e:
        print(f"Error en resumen de dashboard: {e}")
        return {
            "total_productos": 0, "total_clientes": 0, "total_proveedores": 0,
            "total_ventas": 0, "suma_ventas": 0.0, "total_compras": 0, "suma_compras": 0.0
        }
    finally:
        release_connection(con)

# -------------------------------------------------------
# FUNCIONES PARA REPORTE PDF CON FILTRO DE PERÍODO
# -------------------------------------------------------

def listar_ventas_periodo(fecha_desde: str, fecha_hasta: str):
    """Retorna ventas del período con su detalle de productos."""
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT v.id_venta, v.fecha, c.nombre AS cliente,
                   v.subtotal, v.descuento, v.iva, v.total
            FROM ventas v
            LEFT JOIN clientes c ON v.id_cliente = c.id_cliente
            WHERE v.fecha::date BETWEEN %s AND %s
            ORDER BY v.fecha ASC
        """, (fecha_desde, fecha_hasta))
        ventas = [dict(r) for r in cur.fetchall()]

        # Obtener el detalle de productos por venta
        for venta in ventas:
            cur.execute("""
                SELECT pr.nombre AS producto, dv.cantidad, dv.precio_unitario, dv.subtotal
                FROM detalle_ventas dv
                JOIN productos pr ON dv.id_producto = pr.id_producto
                WHERE dv.id_venta = %s
            """, (venta["id_venta"],))
            venta["items"] = [dict(r) for r in cur.fetchall()]

        return ventas
    finally:
        release_connection(con)


def listar_compras_periodo(fecha_desde: str, fecha_hasta: str):
    """Retorna compras del período con su detalle de productos."""
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT c.id_compra, c.fecha, p.nombre AS proveedor,
                   c.subtotal, c.total
            FROM compras c
            LEFT JOIN proveedores p ON c.id_proveedor = p.id_proveedor
            WHERE c.fecha::date BETWEEN %s AND %s
            ORDER BY c.fecha ASC
        """, (fecha_desde, fecha_hasta))
        compras = [dict(r) for r in cur.fetchall()]

        for compra in compras:
            cur.execute("""
                SELECT pr.nombre AS producto, dc.cantidad, dc.precio_unitario, dc.subtotal
                FROM detalle_compras dc
                JOIN productos pr ON dc.id_producto = pr.id_producto
                WHERE dc.id_compra = %s
            """, (compra["id_compra"],))
            compra["items"] = [dict(r) for r in cur.fetchall()]

        return compras
    finally:
        release_connection(con)


def listar_mermas_periodo(fecha_desde: str, fecha_hasta: str):
    """Retorna mermas del período."""
    con = get_connection()
    try:
        cur = con.cursor(cursor_factory=DictCursor)
        cur.execute("""
            SELECT m.id_merma, m.fecha, p.nombre AS producto,
                   m.cantidad, m.motivo, m.observacion
            FROM mermas m
            JOIN productos p ON m.id_producto = p.id_producto
            WHERE m.fecha::date BETWEEN %s AND %s
            ORDER BY m.fecha ASC
        """, (fecha_desde, fecha_hasta))
        return [dict(r) for r in cur.fetchall()]
    finally:
        release_connection(con)
