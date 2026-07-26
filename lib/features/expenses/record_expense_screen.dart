import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/database/enums.dart';
import '../../core/providers.dart';
import '../../core/widgets/numeric_input_field.dart';
import '../../core/widgets/payment_method_selector.dart';
import '../../core/widgets/primary_button.dart';

/// Feature-local in-flight flag guarding the Record Expense submit button
/// (design D3 double-submit protection / common-rules async-submit guard).
final _recordExpenseInFlightProvider = StateProvider<bool>((ref) => false);

/// Record Expense (route `/expenses/add`). Track T3 body.
class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  ConsumerState<RecordExpenseScreen> createState() => _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  ExpenseCategory? _category;
  PaymentMethod _method = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();
  String? _amountError;
  String? _categoryError;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final amountCents =
        NumericInputField.parseValue(_amountController.text, NumericInputMode.money);

    setState(() {
      _amountError =
          (amountCents == null || amountCents <= 0) ? 'Enter a valid amount greater than zero' : null;
      _categoryError = _category == null ? 'Select a category' : null;
    });
    if (_amountError != null || _categoryError != null) return;

    ref.read(_recordExpenseInFlightProvider.notifier).state = true;
    try {
      await ref.read(expensesDaoProvider).recordExpense(
            amountCents: amountCents!,
            category: _category!,
            description:
                _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
            method: _method,
            selectedDate: _selectedDate,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense recorded.')),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (ref.exists(_recordExpenseInFlightProvider)) {
        ref.read(_recordExpenseInFlightProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(_recordExpenseInFlightProvider);
    final dateLabel = DateFormat.yMMMd().format(_selectedDate);

    return Scaffold(
      appBar: AppBar(title: const Text('Record Expense')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NumericInputField.money(
              label: 'Amount',
              controller: _amountController,
              errorText: _amountError,
              enabled: !submitting,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text('Category', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in ExpenseCategory.values)
                  ChoiceChip(
                    label: Text(category.label),
                    selected: _category == category,
                    showCheckmark: false,
                    backgroundColor: AppTokens.surfaceMuted,
                    selectedColor: AppTokens.emeraldContainer,
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: AppTextStyles.caption.copyWith(
                      color: _category == category ? AppTokens.emeraldDeep : AppTokens.inkSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: submitting
                        ? null
                        : (selected) {
                            if (selected) setState(() => _category = category);
                          },
                  ),
              ],
            ),
            if (_categoryError != null) ...[
              const SizedBox(height: 4),
              Text(_categoryError!, style: AppTextStyles.caption.copyWith(color: AppTokens.red)),
            ],
            if (_category == ExpenseCategory.stockPurchase) ...[
              const SizedBox(height: 8),
              Text(
                'Cash taken from the till for stock. Reduces expected cash at '
                'close, not profit — stock cost is counted when items sell.',
                style: AppTextStyles.caption.copyWith(color: AppTokens.inkMuted),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              enabled: !submitting,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 16),
            Text('Payment method', style: AppTextStyles.bodyStrong),
            const SizedBox(height: 8),
            PaymentMethodSelector(
              value: _method,
              onChanged: submitting ? (_) {} : (value) => setState(() => _method = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: submitting ? null : _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  suffixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                ),
                child: Text(dateLabel, style: AppTextStyles.body),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save Expense',
              loading: submitting,
              onPressed: submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
