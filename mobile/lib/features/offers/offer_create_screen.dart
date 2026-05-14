import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import 'offer_repository.dart';

const _kCategories = [
  'Alimentação',
  'Hospedagem',
  'Logística',
  'Marketing',
  'Tecnologia',
  'Saúde',
  'Educação',
  'Serviços',
];

class OfferCreateScreen extends ConsumerStatefulWidget {
  const OfferCreateScreen({super.key});

  @override
  ConsumerState<OfferCreateScreen> createState() => _OfferCreateScreenState();
}

class _OfferCreateScreenState extends ConsumerState<OfferCreateScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  String? _selectedCategory;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cents = parseMoneyCents(_price.text);
      await ref.read(offerRepositoryProvider).create(
            title: _title.text.trim(),
            description: _description.text.trim(),
            priceCents: cents,
            category: _selectedCategory,
          );
      if (mounted) {
        showAppSnackbar(context,
            message: 'Oferta publicada com sucesso!',
            type: SnackbarType.success);
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final msg = e.response?.data?['message'];
        showAppSnackbar(
          context,
          message: msg is List
              ? (msg as List).join(', ')
              : msg?.toString() ?? 'Erro ao publicar oferta',
          type: SnackbarType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        showAppSnackbar(context, message: e.toString(), type: SnackbarType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceMuted,
      appBar: AppBar(
        title: const Text('Nova oferta'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(80, 38),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publicar'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Informações da oferta'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _title,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Título *',
                          hintText: 'Ex: Diárias de hotel, Transporte de carga',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _description,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.newline,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Descrição *',
                          hintText: 'Detalhe o que está oferecendo, condições, etc.',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 64),
                            child: Icon(Icons.description_outlined),
                          ),
                          alignLabelWithHint: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Obrigatório';
                          if (v.trim().length < 10) return 'Mínimo 10 caracteres';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionTitle('Preço e categoria'),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [MoneyInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'Preço (UP\$) *',
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
                      const SizedBox(height: 16),
                      const Text(
                        'Categoria',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _kCategories.map((cat) {
                          final selected = _selectedCategory == cat;
                          return FilterChip(
                            label: Text(cat),
                            selected: selected,
                            onSelected: (_) => setState(() =>
                                _selectedCategory = selected ? null : cat),
                            backgroundColor: AppColors.surface,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border),
                            showCheckmark: false,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Publicar oferta'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
    );
  }
}
