import 'package:flutter/material.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:gap/gap.dart';

class QualitySelector extends StatelessWidget {
  final List<int> qualities;
  final int selectedQuality;
  final Function(int) onSelected;

  const QualitySelector({
    super.key,
    required this.qualities,
    required this.selectedQuality,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (qualities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Selecione a Qualidade",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: qualities.map((quality) {
            final isSelected = quality == selectedQuality;
            return GestureDetector(
              onTap: () => onSelected(quality),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected 
                      ? AppColors.primaryGradient 
                      : null,
                  color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected 
                        ? Colors.white.withValues(alpha: 0.5) 
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const Gap(8),
                    ],
                    Text(
                      "${quality}p",
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
