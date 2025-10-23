import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme.dart';

class LockersView extends StatefulWidget {
  const LockersView({super.key, required this.service});

  final ApiService service;

  @override
  State<LockersView> createState() => LockersViewState();
}

class LockersViewState extends State<LockersView> {
  late Future<void> _loader;
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
      final lockers = await widget.service.fetchLockers();
      setState(() {
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

  void showCreateLockerDialog() {
    _openCreateDialog();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _lockers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_error != null) {
          return _ErrorState(message: _error!, onRetry: refresh);
        }
        if (_lockers.isEmpty) {
          return _EmptyState(onCreate: showCreateLockerDialog);
        }
        return RefreshIndicator(
          onRefresh: refresh,
          backgroundColor: AppColors.card,
          color: AppColors.accent,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: _lockers.length,
            itemBuilder: (context, index) {
              final locker = _lockers[index];
              return Card(
                child: ListTile(
                  title: Text(locker.code),
                  subtitle: Text(locker.description ?? 'Sem descrição'),
                  leading: const Icon(Icons.inventory_rounded, color: AppColors.accent),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog() async {
    final codeController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                  Text('Novo armário', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Código / Endereço'),
                    validator: (value) => value == null || value.isEmpty ? 'Informe um código' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                    maxLines: 2,
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
                        child: const Text('Salvar'),
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

    if (result != true) {
      return;
    }

    try {
      await widget.service.createLocker(
        code: codeController.text,
        description: descriptionController.text.isEmpty
            ? null
            : descriptionController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Armário cadastrado com sucesso!')),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Nenhum armário cadastrado ainda.'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onCreate,
            child: const Text('Cadastrar armário'),
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
          Text('Erro ao carregar armários', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => onRetry(), child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
