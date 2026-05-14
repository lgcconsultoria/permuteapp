import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Logo PermuteApp.
/// Símbolo: hexágono com ícone de troca (⇄) — representa a rede
/// multilateral. Wordmark: "permute" bold com "UP$" âmbar.
class BrandLogo extends StatelessWidget {
  const BrandLogo({this.showTagline = true, this.compact = false, super.key});

  final bool showTagline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 32.0 : 56.0;
    final titleSize = compact ? 18.0 : 28.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LogoMark(size: iconSize),
        SizedBox(width: compact ? 10 : 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'permute',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            if (showTagline && !compact)
              const Text(
                'rede de permuta multilateral',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: Colors.white,
            size: size * 0.52,
          ),
          Positioned(
            top: size * 0.08,
            right: size * 0.08,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Center(
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.14,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
