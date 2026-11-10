import 'package:flutter/material.dart';

import 'package:parlour_account/services/firebase/category_service.dart';

class CategoryChoice {
  const CategoryChoice({required this.id, required this.name});

  final String id;
  final String name;
}

class CategorySelectField extends StatelessWidget {
  const CategorySelectField({
    super.key,
    required this.type,
    required this.value,
    this.currentName,
    required this.onChanged,
  });

  final String type;
  final String? value;
  final String? currentName;
  final ValueChanged<CategoryChoice?> onChanged;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: CategoryService().watch(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const InputDecorator(
            decoration: InputDecoration(labelText: 'Category'),
            child: Text('Could not load categories'),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        final categories = docs
            .where((doc) => doc.data()['active'] != false)
            .map((doc) => CategoryChoice(
                  id: doc.id,
                  name: doc.data()['name'] as String? ?? 'Unnamed category',
                ))
            .toList(growable: true);
        categories.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (value != null &&
            !categories.any((category) => category.id == value)) {
          categories.add(CategoryChoice(
            id: value!,
            name: currentName ?? 'Archived category',
          ));
        }
        final validValue =
            categories.any((category) => category.id == value) ? value : null;
        return DropdownButtonFormField<String?>(
          key: ValueKey('$type:$validValue'),
          initialValue: validValue,
          decoration: InputDecoration(
            labelText:
                type == 'income' ? 'Income category' : 'Expense category',
            hintText: 'Optional',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Uncategorized'),
            ),
            for (final category in categories)
              DropdownMenuItem<String?>(
                value: category.id,
                child: Text(category.name),
              ),
          ],
          onChanged: (id) => onChanged(
            id == null
                ? null
                : categories.firstWhere((category) => category.id == id),
          ),
        );
      },
    );
  }
}
