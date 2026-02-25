import os
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.getenv("DATABASE_URL")
if not DB_URL:
    raise ValueError("No DATABASE_URL found in environment")

def reset_database():
    print("Conectando a la base de datos...")
    try:
        con = psycopg2.connect(DB_URL)
        cur = con.cursor()
        
        print("Vaciando tablas y reiniciando contadores de ID...")
        # TRUNCATE en PostgreSQL borra todos los datos de las tablas
        # RESTART IDENTITY asegura que los IDs vuelven a empezar en 1
        # CASCADE borra también los registros dependientes
        cur.execute("""
            TRUNCATE TABLE 
                detalle_ventas, 
                detalle_compras, 
                ventas, 
                compras, 
                mermas, 
                productos, 
                proveedores, 
                clientes 
            RESTART IDENTITY CASCADE;
        """)
        
        con.commit()
        print("¡Base de datos reseteada con éxito!")
        print("Todas las tablas están ahora vacías.")
        
    except Exception as e:
        print(f"Error al intentar resetear la base de datos: {e}")
    finally:
        if 'con' in locals():
            con.close()

if __name__ == "__main__":
    confirmacion = input("ATENCIÓN: Esto borrará TODOS los datos de la base de datos de forma permanente. ¿Estás seguro? (escribe 'SI' para continuar): ")
    if confirmacion == 'SI':
        reset_database()
    else:
        print("Operación cancelada. No se ha borrado ningún dato.")
