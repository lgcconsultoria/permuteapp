import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'offer_repository.dart';

class OfferCreateScreen extends ConsumerStatefulWidget {
  const OfferCreateScreen({super.key});

  @override
  ConsumerState<OfferCreateScreen> createState() => _OfferCreateScreenState();
}

class _OfferCreateScreenState extends ConsumerState<OfferCreateScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cents = (double.parse(_price.text.replaceAll(',', '.')) * 100).round();
      await ref.read(offerRepositoryProvider).create(
            title: _title.text.trim(),
            description: _description.text.trim(),
            priceCents: cents,
            category: _category.text.trim().isEmpty ? null : _category.text.trim(),
          );
      if (mounted) context.pop();
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message']?.toString() ?? 'erro');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova oferta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descrição'),
              maxLines: 3,
            ),
            TextField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Preço (UP\$)'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Categoria'),
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
