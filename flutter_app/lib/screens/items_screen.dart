import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class ItemsView extends StatefulWidget {
  const ItemsView({super.key, required this.service});

  final ApiService service;

  @override
  State<ItemsView> createState() => ItemsViewState();
}

class ItemsViewState extends State<ItemsView> {
  late Future<void> _loader;
  List<Item> _items = const [];
  List<Locker> _lockers = const [];
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
      final items = await widget.service.fetchItems();
      final lockers = await widget.service.fetchLockers();
      setState(() {
        _items = items;
        _lockers = lockers;
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

  void showCreateItemDialog() {
    _showItemDialog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return _ErrorBox(message: _error!, onRetry: refresh);
        }

        if (_items.isEmpty) {
          return _EmptyItemsState(onCreate: showCreateItemDialog);
        }

        return RefreshIndicator(
          onRefresh: refresh,
          backgroundColor: AppColors.card,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return _ItemCard(
                item: item,
                onRegisterMovement: () => _openMovementDialog(item, MovementAction.outbound),
                onRegisterEntry: () => _openMovementDialog(item, MovementAction.inbound),
                onShowQrCode: () => _showQrCode(item),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showItemDialog() async {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '0');
    final minQuantityController = TextEditingController(text: '0');
    final returnTimeController = TextEditingController();
    Locker? selectedLocker = _lockers.isNotEmpty ? _lockers.first : null;
    bool isSupply = false;

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
                        Text(
                          'Novo item',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: 'Nome do item'),
                          validator: (value) => value == null || value.isEmpty ? 'Informe o nome' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: skuController,
                          decoration: const InputDecoration(labelText: 'SKU / Código'),
                          validator: (value) => value == null || value.isEmpty ? 'Informe o SKU' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: descriptionController,
                          decoration: const InputDecoration(labelText: 'Descrição'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: quantityController,
                                decoration: const InputDecoration(labelText: 'Quantidade inicial'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: minQuantityController,
                                decoration: const InputDecoration(labelText: 'Estoque mínimo'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<Locker>(
                          value: selectedLocker,
                          decoration: const InputDecoration(labelText: 'Armário / Endereçamento'),
                          items: _lockers
                              .map(
                                (locker) => DropdownMenuItem(
                                  value: locker,
                                  child: Text(locker.code),
                                ),
                              )
                              .toList(),
                          onChanged: (value) => setDialogState(() => selectedLocker = value),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Item é um insumo com retorno obrigatório'),
                          value: isSupply,
                          onChanged: (value) {
                            setDialogState(() {
                              isSupply = value;
                              if (!value) {
                                returnTimeController.clear();
                              }
                            });
                          },
                        ),
                        if (isSupply) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: returnTimeController,
                            decoration: const InputDecoration(
                              labelText: 'Tempo máximo para retorno (em horas)',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (!isSupply) {
                                return null;
                              }
                              final parsed = int.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Informe um tempo válido em horas';
                              }
                              return null;
                            },
                          ),
                        ],
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
                              child: const Text('Salvar item'),
                            ),
                          ],
                        ),
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

    final quantity = int.tryParse(quantityController.text) ?? 0;
    final minQuantity = int.tryParse(minQuantityController.text) ?? 0;
    final maxReturnTime = int.tryParse(returnTimeController.text);

    try {
      await widget.service.createItem(
        name: nameController.text,
        sku: skuController.text,
        quantity: quantity,
        minimumQuantity: minQuantity,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
        lockerId: selectedLocker?.id,
        isSupply: isSupply,
        maxReturnTimeHours: isSupply ? maxReturnTime : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item cadastrado com sucesso!')),
      );
      await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }
  Future<void> _openMovementDialog(Item item, MovementAction type) async {
    final quantityController = TextEditingController();
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
                    type == MovementAction.outbound ? 'Baixa de estoque' : 'Entrada de estoque',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  Text('Item: ${item.name} (${item.sku})'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final quantity = int.tryParse(value ?? '');
                      if (quantity == null || quantity <= 0) {
                        return 'Informe um número válido';
                      }
                      if (type == MovementAction.outbound && quantity > item.quantity) {
                        return 'Quantidade maior que o estoque disponível';
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
      await widget.service.registerMovement(
        itemId: item.id,
        quantity: quantity,
        movementType: type == MovementAction.outbound ? 'out' : 'in',
        note: noteController.text.isEmpty ? null : noteController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == MovementAction.outbound
                ? 'Baixa registrada com sucesso.'
                : 'Entrada registrada com sucesso.',
          ),
        ),
      );
      await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $error')),
      );
    }
  }

  Future<void> _showQrCode(Item item) async {
    try {
      final base64Image = await widget.service.fetchItemQrCode(item.id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return Dialog(
            backgroundColor: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('QR Code - ${item.name}',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Image.memory(base64Decode(base64Image), width: 200, height: 200),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'SKU: ${item.sku}',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar QR Code: $error')),
      );
    }
  }
}

enum MovementAction { inbound, outbound }

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.onRegisterMovement,
    required this.onRegisterEntry,
    required this.onShowQrCode,
  });

  final Item item;
  final VoidCallback onRegisterMovement;
  final VoidCallback onRegisterEntry;
  final VoidCallback onShowQrCode;

  @override
  Widget build(BuildContext context) {
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
                    item.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: item.isLowStock
                        ? Colors.deepOrange.withOpacity(0.15)
                        : AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Estoque: ${item.quantity}',
                    style: TextStyle(
                      color: item.isLowStock ? Colors.deepOrangeAccent : AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'SKU: ${item.sku}',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (item.isSupply) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.recycling_outlined, size: 18, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Text(
                      item.maxReturnTimeHours != null
                          ? 'Retorno até ${_formatReturnWindow(item.maxReturnTimeHours!)}'
                          : 'Retorno obrigatório',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
            ],
            if (item.description != null) ...[
              const SizedBox(height: 8),
              Text(
                item.description!,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.cases_outlined, color: AppColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  item.locker?.code ?? 'Sem endereçamento',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onRegisterMovement,
                  icon: const Icon(Icons.arrow_outward),
                  label: const Text('Baixa'),
                ),
                ElevatedButton.icon(
                  onPressed: onRegisterEntry,
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Entrada'),
                ),
                OutlinedButton.icon(
                  onPressed: onShowQrCode,
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text('QR Code'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatReturnWindow(int hours) {
    final days = hours ~/ 24;
    final remainingHours = hours % 24;
    final parts = <String>[];
    if (days > 0) {
      parts.add('$days dia${days > 1 ? 's' : ''}');
    }
    if (remainingHours > 0) {
      parts.add('$remainingHours hora${remainingHours > 1 ? 's' : ''}');
    }
    if (parts.isEmpty) {
      return '$hours hora${hours > 1 ? 's' : ''}';
    }
    return parts.join(' e ');
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Erro ao carregar itens', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => onRetry(), child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class _EmptyItemsState extends StatelessWidget {
  const _EmptyItemsState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nenhum item cadastrado ainda.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Cadastrar item'),
          ),
        ],
      ),
    );
  }
}
