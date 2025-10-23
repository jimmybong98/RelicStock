import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class PurchaseRequestsView extends StatefulWidget {
  const PurchaseRequestsView({super.key, required this.service});

  final ApiService service;

  @override
  State<PurchaseRequestsView> createState() => PurchaseRequestsViewState();
}

class PurchaseRequestsViewState extends State<PurchaseRequestsView> {
  late Future<void> _loader;
  List<PurchaseRequest> _requests = const [];
  List<Item> _items = const [];
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
      final results = await Future.wait([
        widget.service.fetchPurchaseRequests(),
        widget.service.fetchItems(),
      ]);
      setState(() {
        _requests = results[0] as List<PurchaseRequest>;
        _items = results[1] as List<Item>;
        _error = null;
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

  void showCreateRequestDialog() {
    _openCreateDialog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _requests.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return _ErrorState(message: _error!, onRetry: refresh);
        }
        if (_requests.isEmpty) {
          return _EmptyState(onCreate: showCreateRequestDialog);
        }
        return RefreshIndicator(
          onRefresh: refresh,
          backgroundColor: AppColors.card,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _requests.length,
            itemBuilder: (context, index) {
              final request = _requests[index];
              return _RequestCard(
                request: request,
                onChangeStatus: (status) => _updateStatus(request, status),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog() async {
    final itemNameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final requestedByController = TextEditingController();
    final notesController = TextEditingController();
    Item? selectedItem;

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nova solicitação', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Item>(
                          value: selectedItem,
                          decoration: const InputDecoration(labelText: 'Selecionar item (opcional)'),
                          items: _items
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() => selectedItem = value);
                            if (value != null) {
                              itemNameController.text = value.name;
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: itemNameController,
                          decoration: const InputDecoration(labelText: 'Descrição do item'),
                          validator: (value) => value == null || value.isEmpty ? 'Informe o item' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: quantityController,
                          decoration: const InputDecoration(labelText: 'Quantidade'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final qty = int.tryParse(value ?? '');
                            if (qty == null || qty <= 0) {
                              return 'Informe uma quantidade válida';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: requestedByController,
                          decoration: const InputDecoration(labelText: 'Solicitante'),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: notesController,
                          decoration: const InputDecoration(labelText: 'Observações'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState!.validate()) {
                                  Navigator.of(dialogContext).pop(true);
                                }
                              },
                              child: const Text('Cadastrar'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final quantity = int.tryParse(quantityController.text) ?? 1;

    try {
      await widget.service.createPurchaseRequest(
        itemId: selectedItem?.id,
        itemName: itemNameController.text,
        quantity: quantity,
        requestedBy: requestedByController.text.isEmpty ? null : requestedByController.text,
        notes: notesController.text.isEmpty ? null : notesController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação registrada com sucesso!')),
      );
      await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }

  Future<void> _updateStatus(PurchaseRequest request, String status) async {
    try {
      final updated = await widget.service.updatePurchaseRequest(
        requestId: request.id,
        status: status,
      );
      if (!mounted) return;
      setState(() {
        _requests = _requests
            .map((r) => r.id == updated.id ? updated : r)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status atualizado para ${_statusLabel(status)}.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      case 'received':
        return 'Recebido';
      default:
        return 'Pendente';
    }
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onChangeStatus,
  });

  final PurchaseRequest request;
  final ValueChanged<String> onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
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
                    request.itemName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusText(request.status),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: onChangeStatus,
                  itemBuilder: (context) => _buildMenuItems(request.status),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text('Quantidade: ${request.quantity}'),
            if (request.requestedBy != null) ...[
              const SizedBox(height: 8),
              Text('Solicitante: ${request.requestedBy}')
            ],
            const SizedBox(height: 8),
            Text('Criado em: ${request.createdAt.toLocal().toIso8601String().split('T').first}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            if (request.notes != null && request.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(request.notes!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(String currentStatus) {
    final options = <PopupMenuEntry<String>>[];
    if (currentStatus == 'pending') {
      options.add(const PopupMenuItem(value: 'approved', child: Text('Aprovar')));
      options.add(const PopupMenuItem(value: 'rejected', child: Text('Rejeitar')));
    }
    if (currentStatus == 'approved' || currentStatus == 'pending') {
      options.add(const PopupMenuItem(value: 'received', child: Text('Marcar como recebido')));
    }
    if (options.isEmpty) {
      options.add(PopupMenuItem(value: currentStatus, enabled: false, child: const Text('Status atual')));
    }
    return options;
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      case 'received':
        return 'Recebido';
      default:
        return 'Pendente';
    }
  }

  static Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.lightGreenAccent.shade200;
      case 'rejected':
        return Colors.redAccent;
      case 'received':
        return AppColors.accent;
      default:
        return Colors.amberAccent;
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nenhuma solicitação pendente.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Registrar solicitação'),
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
          Text('Erro ao carregar solicitações',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => onRetry(), child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
