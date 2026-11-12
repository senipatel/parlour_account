import 'package:flutter/material.dart';

import 'package:parlour_account/app/theme/app_theme.dart';
import 'package:parlour_account/utils/money_amount.dart';

class EntryFormSection extends StatelessWidget {
  const EntryFormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.mist,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, size: 18, color: AppTheme.slateBlue),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(letterSpacing: .35),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(subtitle!,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );
}

class EntryMoneyField extends StatelessWidget {
  const EntryMoneyField({
    required this.controller,
    required this.label,
    required this.validationLabel,
    required this.icon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String validationLabel;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.steel),
          prefixText: '\u20B9 ',
        ),
        validator: (value) => MoneyAmount.validateRupees(
          value,
          label: validationLabel,
        ),
      );
}

class EntryValuePill extends StatelessWidget {
  const EntryValuePill({required this.label, required this.paise});

  final String label;
  final int paise;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.mist,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$label  \u20B9${MoneyAmount.formatPaise(paise)}',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      );
}

class EntryDateField extends StatelessWidget {
  const EntryDateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.validator,
    this.icon = Icons.calendar_month_outlined,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final FormFieldValidator<String>? validator;
  final IconData icon;

  @override
  Widget build(BuildContext context) => TextFormField(
        key: ValueKey('$label:$value'),
        initialValue: value,
        readOnly: true,
        onTap: onTap,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.steel),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
      );
}
