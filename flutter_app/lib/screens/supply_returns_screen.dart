import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class SupplyReturnsView extends StatefulWidget {
  const SupplyReturnsView({super.key, required this.service});

  final ApiService service;

  @override
  State<SupplyReturnsView> createState() => SupplyReturnsViewState();
}

class SupplyReturnsViewState extends State<SupplyReturnsView> {
  late Future<void> _loader;
  List<SupplyWithdrawal> _withdrawals = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loader = _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
    });
    try {
      final withdrawals = await widget.service.fetchSupplyWithdrawals();
      setState(() {
        _withdrawals = withdrawals;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
      });
    }
  }

  Future<void> refresh() async {
    setState(() {
      _loader = _load();
    });
    await _loader;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _withdrawals.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return _ErrorState(message: _error!, onRetry: refresh);
        }

        if (_withdrawals.isEmpty) {
          return const _EmptyState();
        }

        return RefreshIndicator(
          onRefresh: refresh,
          backgroundColor: AppColors.card,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _withdrawals.length,
            itemBuilder: (context, index) {
              final withdrawal = _withdrawals[index];
              return _WithdrawalCard(
                withdrawal: withdrawal,
                onReturn: () => _showReturnDialog(withdrawal),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showReturnDialog(SupplyWithdrawal withdrawal) async {
    final quantityController = TextEditingController(text: withdrawal.pendingQuantity.toString());
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar retorno',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text('${withdrawal.item.name} (${withdrawal.item.sku})'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantidade devolvida'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Informe uma quantidade válida';
                      }
                      if (quantity > withdrawal.pendingQuantity) {
                        return 'Quantidade maior que a pendência';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Observações'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: const Text('Confirmar'),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final quantity = int.parse(quantityController.text);

    try {
      await widget.service.returnSupplyWithdrawal(
        withdrawalId: withdrawal.id,
        quantity: quantity,
        note: noteController.text.isEmpty ? null : noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retorno registrado com sucesso!')),
      );
      await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }
}

class _WithdrawalCard extends StatelessWidget {
  const _WithdrawalCard({required this.withdrawal, required this.onReturn});

  final SupplyWithdrawal withdrawal;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final isOverdue = withdrawal.isOverdue;
    final pendingQuantity = withdrawal.pendingQuantity;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    withdrawal.item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber_outlined, color: Colors.deepOrangeAccent, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Atrasado',
                          style: TextStyle(
                            color: Colors.deepOrangeAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'SKU: ${withdrawal.item.sku}',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.logout,
                  label: 'Retirado: ${withdrawal.quantityWithdrawn}',
                ),
                _InfoChip(
                  icon: Icons.watch_later_outlined,
                  label:
                      'Retirado em ${_formatDate(withdrawal.withdrawnAt)}',
                ),
                if (withdrawal.dueAt != null)
                  _InfoChip(
                    icon: Icons.event_busy_outlined,
                    label: 'Devolver até ${_formatDate(withdrawal.dueAt!)}',
                  ),
                _InfoChip(
                  icon: Icons.inventory_2_outlined,
                  label: 'Pendente: $pendingQuantity',
                ),
              ],
            ),
            if (withdrawal.note != null && withdrawal.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                withdrawal.note!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: withdrawal.isPending ? onReturn : null,
                icon: const Icon(Icons.keyboard_return),
                label: const Text('Registrar retorno'),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Não foi possível carregar as pendências.'),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => onRetry(), child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 72, color: AppColors.textSecondary),
          SizedBox(height: 16),
          Text('Nenhuma pendência de insumo no momento.'),
        ],
      ),
    );
  }
}
