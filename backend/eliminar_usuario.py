"""
eliminar_usuario.py  -  Script para eliminar usuarios de la base de datos
Uso:  python eliminar_usuario.py

Lee DATABASE_URL desde el archivo .env.
Pide el username del usuario a eliminar.
"""

import os
import sys
import psycopg2
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.getenv("DATABASE_URL")
if not DB_URL:
    print("❌ No se encontró DATABASE_URL en el archivo .env")
    sys.exit(1)

def eliminar_usuario():
    print("=" * 50)
    print("   ELIMINAR USUARIO")
    print("=" * 50)
    print()

    username = input("Ingrese el Username a eliminar: ").strip()
    if not username:
        print("❌ El username no puede estar vacío.")
        sys.exit(1)

    if username.lower() == "cristopher":
        print("⚠️  ¡Atención! Estás intentando eliminar tu propio usuario actual.")
        confirm_self = input("¿Estás 100% seguro de que quieres eliminarte a ti mismo? (escribe 'ELIMINAR'): ")
        if confirm_self != "ELIMINAR":
            print("Operación cancelada por seguridad.")
            return

    confirm = input(f"¿Estás seguro de que deseas eliminar permanentemente al usuario '{username}'? (s/N): ").strip().lower()
    if confirm != 's':
        print("Operación cancelada.")
        return

    try:
        con = psycopg2.connect(DB_URL)
        cur = con.cursor()

        # Verificar si el usuario existe
        cur.execute("SELECT id FROM usuarios WHERE username = %s", (username,))
        if not cur.fetchone():
            print(f"❌ El usuario '{username}' no existe en la base de datos.")
            return

        cur.execute("DELETE FROM usuarios WHERE username = %s", (username,))
        con.commit()
        print(f"\n✅ Usuario '{username}' eliminado exitosamente.")

    except Exception as e:
        print(f"❌ Error al conectar o borrar en la base de datos: {e}")
    finally:
        if "con" in locals():
            con.close()

if __name__ == "__main__":
    eliminar_usuario()
