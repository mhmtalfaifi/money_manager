// widgets/transaction_item.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool showDate;
  final EdgeInsets? margin;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onLongPress,
    this.showDate = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isExpense = transaction.type == 'expense';
    final isCommitment = transaction.type == 'commitment';

    Color typeColor = AppColors.getTransactionColor(transaction.type);
    Color lightColor = AppColors.getTransactionLightColor(transaction.type);
    
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (onTap != null) {
              HapticFeedback.lightImpact();
              onTap!();
            }
          },
          onLongPress: () {
            if (onLongPress != null) {
              HapticFeedback.mediumImpact();
              onLongPress!();
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.lightBeige.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // أيقونة النوع
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getTransactionIcon(transaction.type),
                    color: typeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // تفاصيل المعاملة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.description,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${isIncome ? '+' : '-'} ${AppConstants.formatMoney(transaction.amount)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isIncome ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              transaction.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: typeColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              transaction.city,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (showDate)
                            Text(
                              DateFormat('d/M').format(transaction.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          transaction.notes!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                
                // أيقونة التكرار
                if (transaction.isRecurring) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.repeat_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'income':
        return Icons.arrow_downward_rounded;
      case 'expense':
        return Icons.arrow_upward_rounded;
      case 'commitment':
        return Icons.event_repeat_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }
}