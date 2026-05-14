import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import 'wallet_repository.dart';

// Etapas do fluxo
enum _Step { form, review, success }

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cnpjCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  _Step _step = _Step.form;
  bool _loading = false;

  // Dados da empresa destinatária (preenchidos no passo 1)
  String? _toCompanyId;
  String? _toCompanyName;
  int _amountCents = 0;

  @override
  void dispose() {
    _cnpjCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(apiClientProvider);
      final cleanCnpj = _cnpjCtrl.text.replaceAll(RegExp(r'\D'), '');
      final res =
          await dio.get<Map<String, dynamic>>('/companies/by-cnpj/$cleanCnpj');
      _toCompanyId = res.data!['id'] as String;
      _toCompanyName =
          (res.data!['nomeFantasia'] ?? res.data!['razaoSocial']) as String;
      _amountCents = parseMoneyCents(_amountCtrl.text);
      setState(() => _step = _Step.review);
    } on DioException catch (e) {
      if (mounted) {
        showAppSnackbar(
          context,
          message: e.response?.statusCode == 404
              ? 'CNPJ não encontrado na rede'
              : e.response?.data?['message']?.toString() ?? 'Erro ao buscar empresa',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await ref.read(walletRepositoryProvider).transfer(
            toCompanyId: _toCompanyId!,
            amountCents: _amountCents,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      setState(() => _step = _Step.success);
    } on DioException catch (e) {
      if (mounted) {
        showAppSnackbar(
          context,
          message: e.response?.data?['message']?.toString() ??
              'Erro ao realizar transferência',
          type: SnackbarType.error,
        );
        setState(() => _step = _Step.form);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _reset() {
    _cnpjCtrl.clear();
    _amountCtrl.clear();
    _descCtrl.clear();
    _toCompanyId = null;
    _toCompanyName = null;
    _amountCents = 0;
    setState(() => _step = _Step.form);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Transferir UP\$'),
        leading: _step == _Step.form
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _step == _Step.review
                    ? () => setState(() => _step = _Step.form)
                    : null,
              ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: switch (_step) {
          _Step.form => _FormStep(
              key: const ValueKey('form'),
              formKey: _formKey,
              cnpjCtrl: _cnpjCtrl,
              amountCtrl: _amountCtrl,
              descCtrl: _descCtrl,
              loading: _loading,
              onNext: _lookup,
            ),
          _Step.review => _ReviewStep(
              key: const ValueKey('review'),
              toCompanyName: _toCompanyName!,
              cnpj: _cnpjCtrl.text,
              amountCents: _amountCents,
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              loading: _loading,
              onConfirm: _confirm,
              onBack: () => setState(() => _step = _Step.form),
            ),
          _Step.success => _SuccessStep(
              key: const ValueKey('success'),
              toCompanyName: _toCompanyName!,
              amountCents: _amountCents,
              onNewTransfer: _reset,
              onGoHome: () => context.go('/wallet'),
            ),
        },
      ),
    );
  }
}

// ─── Passo 1: formulário ─────────────────────────────────────────────────────

class _FormStep extends StatelessWidget {
  const _FormStep({
    super.key,
    required this.formKey,
    required this.cnpjCtrl,
    required this.amountCtrl,
    required this.descCtrl,
    required this.loading,
    required this.onNext,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController cnpjCtrl;
  final TextEditingController amountCtrl;
  final TextEditingController descCtrl;
  final bool loading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Indicador de passos
              _StepIndicator(current: 0),
              const SizedBox(height: 24),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Para quem?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Informe o CNPJ da empresa destinatária',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: cnpjCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [CnpjInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'CNPJ',
                        hintText: '00.000.000/0001-00',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                      validator: (v) {
                        final d = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                        if (d.length != 14) return 'CNPJ inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [MoneyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'Valor (UP\$)',
                        hintText: '0,00',
                        prefixIcon: Icon(Icons.attach_money_rounded),
                        prefixText: 'UP\$ ',
                      ),
                      validator: (v) {
                        final c = parseMoneyCents(v ?? '');
                        if (c <= 0) return 'Informe um valor válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: descCtrl,
                      textInputAction: TextInputAction.done,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Opcional',
                        prefixIcon: Icon(Icons.notes_rounded),
                        counterText: '',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              FilledButton(
                onPressed: loading ? null : onNext,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continuar'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Passo 2: revisão ────────────────────────────────────────────────────────

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.toCompanyName,
    required this.cnpj,
    required this.amountCents,
    required this.loading,
    required this.onConfirm,
    required this.onBack,
    this.description,
  });

  final String toCompanyName;
  final String cnpj;
  final int amountCents;
  final String? description;
  final bool loading;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: 1),
            const SizedBox(height: 24),

            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirmar transferência',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ReviewRow(
                    icon: Icons.business_rounded,
                    label: 'Empresa destinatária',
                    value: toCompanyName,
                  ),
                  const Divider(height: 24),
                  _ReviewRow(
                    icon: Icons.badge_outlined,
                    label: 'CNPJ',
                    value: cnpj,
                  ),
                  const Divider(height: 24),
                  _ReviewRow(
                    icon: Icons.attach_money_rounded,
                    label: 'Valor',
                    value: kCurrency.format(amountCents / 100.0),
                    valueStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 20,
                    ),
                  ),
                  if (description != null) ...[
                    const Divider(height: 24),
                    _ReviewRow(
                      icon: Icons.notes_rounded,
                      label: 'Descrição',
                      value: description!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentWash,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.accent.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.accentDark),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A transferência é imediata e não pode ser desfeita após confirmada.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accentDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: loading ? null : onConfirm,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirmar e enviar'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: loading ? null : onBack,
              child: const Text('Voltar e editar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primaryWash,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: valueStyle ??
                    const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Passo 3: sucesso ────────────────────────────────────────────────────────

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    super.key,
    required this.toCompanyName,
    required this.amountCents,
    required this.onNewTransfer,
    required this.onGoHome,
  });

  final String toCompanyName;
  final int amountCents;
  final VoidCallback onNewTransfer;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.credit.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.credit, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transferência realizada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${kCurrency.format(amountCents / 100.0)} enviados para $toCompanyName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: onGoHome,
                child: const Text('Ver extrato'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onNewTransfer,
                child: const Text('Nova transferência'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Widgets ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const steps = ['Dados', 'Revisão'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < current ? AppColors.primary : AppColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final done = idx < current;
        final active = idx == current;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done || active ? AppColors.primary : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: done || active ? AppColors.primary : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                : Text(
                    '${idx + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
