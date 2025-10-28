import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'screens/items_screen.dart';
import 'screens/lockers_screen.dart';
import 'screens/purchase_requests_screen.dart';
import 'screens/supply_returns_screen.dart';
import 'services/api_service.dart';
import 'theme.dart';

void main() {
  runApp(const RelicStockApp());
}

class RelicStockApp extends StatelessWidget {
  const RelicStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildRelicTheme(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _service = ApiService();
  final GlobalKey<ItemsViewState> _itemsKey = GlobalKey();
  final GlobalKey<LockersViewState> _lockersKey = GlobalKey();
  final GlobalKey<PurchaseRequestsViewState> _requestsKey = GlobalKey();
  final GlobalKey<SupplyReturnsViewState> _returnsKey = GlobalKey();

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RelicStock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCurrent,
            tooltip: 'Atualizar',
          )
        ],
      ),
      floatingActionButton: _buildFab(),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) => setState(() => _selectedIndex = index),
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.accent.withOpacity(0.2),
            selectedIconTheme: const IconThemeData(color: AppColors.accent),
            selectedLabelTextStyle: const TextStyle(color: AppColors.accent),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Visão geral'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Itens'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.assignment_return_outlined),
                selectedIcon: Icon(Icons.assignment_return),
                label: Text('Retorno de insumos'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cases_outlined),
                selectedIcon: Icon(Icons.cases_rounded),
                label: Text('Armários'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_checkout_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Solicitações'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(service: _service, key: const ValueKey('dashboard'));
      case 1:
        return ItemsView(service: _service, key: _itemsKey);
      case 2:
        return SupplyReturnsView(service: _service, key: _returnsKey);
      case 3:
        return LockersView(service: _service, key: _lockersKey);
      case 4:
        return PurchaseRequestsView(service: _service, key: _requestsKey);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget? _buildFab() {
    switch (_selectedIndex) {
      case 1:
        return FloatingActionButton.extended(
          onPressed: () => _itemsKey.currentState?.showCreateItemDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Novo item'),
        );
      case 3:
        return FloatingActionButton.extended(
          onPressed: () => _lockersKey.currentState?.showCreateLockerDialog(),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Novo armário'),
        );
      case 4:
        return FloatingActionButton.extended(
          onPressed: () => _requestsKey.currentState?.showCreateRequestDialog(),
          icon: const Icon(Icons.playlist_add),
          label: const Text('Nova solicitação'),
        );
      default:
        return null;
    }
  }

  Future<void> _refreshCurrent() async {
    switch (_selectedIndex) {
      case 1:
        await _itemsKey.currentState?.refresh();
        break;
      case 2:
        await _returnsKey.currentState?.refresh();
        break;
      case 3:
        await _lockersKey.currentState?.refresh();
        break;
      case 4:
        await _requestsKey.currentState?.refresh();
        break;
      default:
        setState(() {});
    }
  }
}
