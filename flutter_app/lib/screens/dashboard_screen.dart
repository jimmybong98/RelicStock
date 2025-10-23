import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.service});

  final ApiService service;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<InventorySnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.service.fetchSnapshot();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.service.fetchSnapshot();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InventorySnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ErrorState(onRetry: _refresh);
        }

        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Sem dados do inventário.'));
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 180,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
            ),
            children: [
              _MetricCard(
                label: 'Itens cadastrados',
                value: data.totalItems.toString(),
                icon: Icons.inventory_2_outlined,
              ),
              _MetricCard(
                label: 'Itens em alerta',
                value: data.lowStockItems.toString(),
                icon: Icons.warning_amber_outlined,
                accent: Colors.deepOrangeAccent,
              ),
              _MetricCard(
                label: 'Solicitações pendentes',
                value: data.pendingRequests.toString(),
                icon: Icons.shopping_cart_checkout_outlined,
                accent: AppColors.accentMuted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.accent;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Não foi possível carregar o dashboard.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
