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
import '../utils/responsive.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final BuildContext parentContext;

  const AppHeader({super.key, required this.parentContext});

  // Definición centralizada de las rutas del menú
  List<Map<String, dynamic>> get _menuItems => [
    {
      'icon': Icons.dashboard,
      'label': 'Inicio',
      'onTap': (BuildContext ctx) => Navigator.pushAndRemoveUntil(
        ctx,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      ),
    },
    {
      'icon': Icons.inventory,
      'label': 'Productos',
      'onTap': (BuildContext ctx) => Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => const ProductosPage())),
    },
    {
      'icon': Icons.people,
      'label': 'Clientes',
      'onTap': (BuildContext ctx) => Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => const ClientesPage())),
    },
    {
      'icon': Icons.local_shipping,
      'label': 'Proveedores',
      'onTap': (BuildContext ctx) => Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => const ProveedoresPage())),
    },
    {
      'icon': Icons.point_of_sale,
      'label': 'Ventas',
      'onTap': (BuildContext ctx) => Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => const VentasPage())),
    },
    {
      'icon': Icons.shopping_cart,
      'label': 'Compras',
      'onTap': (BuildContext ctx) => Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => const ComprasPage())),
    },
    {
      'icon': Icons.warning_amber,
      'label': 'Mermas',
      'onTap': (BuildContext ctx) => Navigator.push(
        ctx, MaterialPageRoute(builder: (_) => const MermasPage())),
    },
  ];

  Future<void> _logout(BuildContext ctx) async {
    await AuthService.logout();
    if (ctx.mounted) {
      Navigator.pushAndRemoveUntil(
        ctx,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    return AppBar(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.egg, size: 28),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sistema de Inventario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('Huevos MARA', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
      centerTitle: false,
      // En móvil: el drawer se abre con el ícono de hamburguesa automático
      // En desktop: botones en la barra superior
      actions: mobile
          ? [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: () => _logout(parentContext),
              ),
            ]
          : [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._menuItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ElevatedButton.icon(
                            icon: Icon(item['icon'] as IconData, size: 18),
                            label: Text(item['label'] as String),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            onPressed: () =>
                                (item['onTap'] as Function(BuildContext))(
                                    parentContext),
                          ),
                        )),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Cerrar Sesión'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                      ),
                      onPressed: () => _logout(parentContext),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Drawer que se usa en pantallas móviles
class AppDrawer extends StatelessWidget {
  final BuildContext parentContext;

  const AppDrawer({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    final items = AppHeader(parentContext: parentContext)._menuItems;

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.egg, color: Colors.white, size: 40),
                SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sistema de\nInventario',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('Huevos MARA',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: items
                  .map((item) => ListTile(
                        leading: Icon(item['icon'] as IconData,
                            color: Colors.deepPurple),
                        title: Text(item['label'] as String),
                        onTap: () {
                          Navigator.pop(context); // cierra el drawer
                          (item['onTap'] as Function(BuildContext))(
                              parentContext);
                        },
                      ))
                  .toList(),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await AuthService.logout();
              if (parentContext.mounted) {
                Navigator.pushAndRemoveUntil(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
