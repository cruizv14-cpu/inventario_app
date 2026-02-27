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
  final String activePage;

  const AppHeader({super.key, required this.parentContext, this.activePage = ""});

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
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/logohuevos.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sistema de Inventario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('Huevos MARA', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
      centerTitle: false,
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
                    ..._menuItems.map((item) {
                      final bool isActive = item['label'] == activePage;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: ElevatedButton.icon(
                          icon: Icon(item['icon'] as IconData, size: 18),
                          label: Text(item['label'] as String),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.deepPurple.shade900 : Colors.white,
                            foregroundColor: isActive ? Colors.white : Colors.deepPurple,
                            elevation: isActive ? 4 : 1,
                            side: isActive ? const BorderSide(color: Colors.white, width: 1.5) : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onPressed: () {
                            if (!isActive) {
                              (item['onTap'] as Function(BuildContext))(parentContext);
                            }
                          },
                        ),
                      );
                    }),
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
  final String activePage;

  const AppDrawer({super.key, required this.parentContext, this.activePage = ""});

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
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logohuevos.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
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
                  .map((item) {
                    final bool isActive = item['label'] == activePage;
                    return ListTile(
                      leading: Icon(item['icon'] as IconData,
                          color: isActive ? Colors.deepPurple : Colors.grey),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isActive ? Colors.deepPurple : Colors.black87,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isActive,
                      selectedTileColor: Colors.deepPurple.withOpacity(0.1),
                      onTap: () {
                        Navigator.pop(context); // cierra el drawer
                        if (!isActive) {
                          (item['onTap'] as Function(BuildContext))(parentContext);
                        }
                      },
                    );
                  })
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
