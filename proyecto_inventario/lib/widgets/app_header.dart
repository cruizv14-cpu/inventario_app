import 'package:flutter/material.dart';
import '../screens/productos.dart';
import '../screens/clientes.dart';
import '../screens/proveedores.dart';
import '../screens/ventas.dart';
import '../screens/compras.dart';
import '../screens/mermas.dart';
import '../screens/dashboard.dart';
import '../services/auth_service.dart';
import '../screens/login.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext parentContext;

  const AppHeader({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Sistema de inventario'),
              Text('Huevos MARA', style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.egg, size: 30),
        ],
      ),
      centerTitle: false,
      actions: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildButton(
                icon: Icons.dashboard,
                label: "Inicio",
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const DashboardPage()),
                        (route) => false,
                  );
                },
              ),
              _buildButton(
                icon: Icons.inventory,
                label: "Productos",
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const ProductosPage()),
                  );
                },
              ),
              _buildButton(
                icon: Icons.people,
                label: "Clientes",
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const ClientesPage()),
                  );
                },
              ),
              _buildButton(
                icon: Icons.local_shipping,
                label: "Proveedores",
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const ProveedoresPage()),
                  );
                },
              ),
              _buildButton(
                icon: Icons.point_of_sale,
                label: "Ventas",
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const VentasPage()),
                  );
                },
              ),
              _buildButton(
                icon: Icons.shopping_cart,
                label: "Compras",
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const ComprasPage()),
                  );
                },
              ),
              _buildButton(
                icon: Icons.warning,
                label: "Mermas",
                onPressed: () {
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (context) => const MermasPage()),
                  );
                },
              ),
              const SizedBox(width: 16),
              // Botón de Cerrar Sesión
              ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text("Cerrar Sesión"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await AuthService.logout();
                  if (parentContext.mounted) {
                    Navigator.pushAndRemoveUntil(
                      parentContext,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }

  // 🔹 Método para crear botones uniformes
  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
        ),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
