import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'wallet_repository.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _cnpj = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  bool _loading = false;
  String? _message;
  Color _messageColor = Colors.red;

  @override
  void dispose() {
    _cnpj.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final dio = ref.read(apiClientProvider);
      final lookup = await dio.get<Map<String, dynamic>>(
        '/companies/by-cnpj/${_cnpj.text.trim()}',
      );
      final toCompanyId = lookup.data!['id'] as String;

      final amountCents = (double.parse(_amount.text.replaceAll(',', '.')) * 100)
          .round();

      await ref.read(walletRepositoryProvider).transfer(
            toCompanyId: toCompanyId,
            amountCents: amountCents,
            description:
                _description.text.trim().isEmpty ? null : _description.text.trim(),
          );

      setState(() {
        _message = 'Transferência realizada com sucesso';
        _messageColor = Colors.green;
        _cnpj.clear();
        _amount.clear();
        _description.clear();
      });
    } on DioException catch (e) {
      setState(() {
        _message = e.response?.data?['message']?.toString() ?? 'Erro';
        _messageColor = Colors.red;
      });
    } catch (e) {
      setState(() {
        _message = e.toString();
        _messageColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transferir créditos')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _cnpj,
              decoration: const InputDecoration(
                labelText: 'CNPJ do destinatário',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              decoration: const InputDecoration(labelText: 'Valor (UP\$)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 16),
            if (_message != null)
              Text(_message!, style: TextStyle(color: _messageColor)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
