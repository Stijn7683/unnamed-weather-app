import 'package:flutter/material.dart';

class CustomDropdownMenu {
  static Widget build(BuildContext context) {
    String? selectedItem;
    final List<String> items = ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
    final MenuController controller = MenuController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: MenuAnchor(
            controller: controller,
            // Always open menu downward
            alignmentOffset: const Offset(0, 0),
            // Ensure menu doesn't clip
            clipBehavior: Clip.none,
            menuChildren: items.asMap().entries.map((entry) {
              //final index = entry.key;
              final item = entry.value;
              return MenuItemButton(
                style: MenuItemButton.styleFrom(
                  minimumSize: const Size(300, 40), // Increased width to 300px
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: selectedItem == item
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                ),
                onPressed: () {
                  setState(() {
                    selectedItem = item;
                    controller.close();
                  });
                },
                child: SizedBox(
                  width: double.infinity,
                  child: Text(item),
                ),
              );
            }).toList(),
            builder: (context, controller, child) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: const Size(300, 48), // Match button width to menu
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedItem ?? 'Select an option',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Helper widget to manage state
class StatefulBuilder extends StatefulWidget {
  final Widget Function(BuildContext, StateSetter) builder;

  const StatefulBuilder({super.key, required this.builder});

  @override
  State<StatefulBuilder> createState() => _StatefulBuilderState();
}

class _StatefulBuilderState extends State<StatefulBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context, setState);
  }
}