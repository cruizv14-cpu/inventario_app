"""
crear_usuario.py  -  Script de creación segura de usuarios de administración
Uso:  python crear_usuario.py

Lee DATABASE_URL desde el archivo .env.
Pide username y contraseña interactivamente (no quedan registrados en el código).
La contraseña se hashea con bcrypt antes de guardarse.
"""

import os
import sys
import getpass
import psycopg2
import bcrypt
from dotenv import load_dotenv

load_dotenv()

DB_URL = os.getenv("DATABASE_URL")
if not DB_URL:
    print("❌ No se encontró DATABASE_URL en el archivo .env")
    sys.exit(1)


def crear_usuario():
    print("=" * 50)
    print("   CREAR USUARIO ADMINISTRADOR")
    print("=" * 50)
    print()

    # Pedir datos por terminal (nunca quedan en el código)
    username = input("Username: ").strip()
    if not username:
        print("❌ El username no puede estar vacío.")
        sys.exit(1)

    password = getpass.getpass("Contraseña (oculta): ")
    if len(password) < 6:
        print("❌ La contraseña debe tener al menos 6 caracteres.")
        sys.exit(1)

    confirm = getpass.getpass("Confirmar contraseña: ")
    if password != confirm:
        print("❌ Las contraseñas no coinciden.")
        sys.exit(1)

    rol = input("Rol [admin/usuario] (Enter = admin): ").strip() or "admin"
    if rol not in ("admin", "usuario"):
        print("❌ Rol inválido. Elige 'admin' o 'usuario'.")
        sys.exit(1)

    # Encriptar contraseña
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

    try:
        con = psycopg2.connect(DB_URL)
        cur = con.cursor()

        # Verificar si el usuario ya existe
        cur.execute("SELECT id FROM usuarios WHERE username = %s", (username,))
        if cur.fetchone():
            sobreescribir = input(
                f"⚠️  El usuario '{username}' ya existe. ¿Actualizar contraseña? (s/N): "
            ).strip().lower()
            if sobreescribir != "s":
                print("Operación cancelada.")
                return

            cur.execute(
                "UPDATE usuarios SET password_hash = %s, rol = %s WHERE username = %s",
                (hashed, rol, username),
            )
            con.commit()
            print(f"\n✅ Contraseña actualizada para '{username}' con rol '{rol}'.")
        else:
            cur.execute(
                "INSERT INTO usuarios (username, password_hash, rol) VALUES (%s, %s, %s)",
                (username, hashed, rol),
            )
            con.commit()
            print(f"\n✅ Usuario '{username}' creado exitosamente con rol '{rol}'.")

        print("   La contraseña está encriptada con bcrypt — nunca se guardó en texto plano.")

    except Exception as e:
        print(f"❌ Error al conectar o escribir en la base de datos: {e}")
    finally:
        if "con" in locals():
            con.close()


if __name__ == "__main__":
    crear_usuario()
