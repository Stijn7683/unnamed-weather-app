import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


// Custom Dropdown Menu Widget
class CustomDropdownMenu extends StatelessWidget {
  final String? selectedItem;
  final List<DropdownMenuEntry<String>> items;
  final ValueChanged<String?> onSelected;
  final String label;

  const CustomDropdownMenu({
    super.key,
    required this.selectedItem,
    required this.items,
    required this.onSelected,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final MenuController controller = MenuController();
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate dropdown width - minimum of 576px or screen width minus padding
    final double dropdownWidth = screenWidth < 576 ? screenWidth - 32 : 576;

        String displayLabel;
    try {
      displayLabel = items.firstWhere(
        (entry) => entry.value == selectedItem,
        orElse: () => DropdownMenuEntry(value: 'default', label: label),
      ).label;
    } catch (e) {
      displayLabel = label;
    }
    
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600), // Constraint applied here
      child: MenuAnchor(
        style: MenuStyle(
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
        controller: controller,
        alignmentOffset: const Offset(0, 0),
        clipBehavior: Clip.none,
        menuChildren: items.map((entry) {
          return MenuItemButton(
            style: MenuItemButton.styleFrom(
              minimumSize: Size(dropdownWidth, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: selectedItem == entry.value
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : null,
            ),
            onPressed: () {
              onSelected(entry.value);
              controller.close();
            },
            child: SizedBox(
              width: double.infinity,
              child: Text(entry.label),
            ),
          );
        }).toList(),
        builder: (context, controller, child) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11), // This should match the menu items
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
                Expanded(
                  child: Text(
                    displayLabel,
                    style: Theme.of(context).textTheme.bodyLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          );
        },
      ),
    );
  }
}
class SettingsPage extends StatefulWidget {
  final bool useDeviceLocation;
  final String? currentCity;
  final Function(bool, String?, String) onSettingsChanged;
  final Function( String WeatherImageType, bool askPermission) onSettingsNOTChanged;
  final bool LocationPermisionButton;
  final Future<bool> Function()? onRequestLocationPermission;
  final String WeatherImageType;
  final VoidCallback deletepage;

  const SettingsPage({
    super.key,
    required this.useDeviceLocation,
    required this.currentCity,
    required this.onSettingsChanged,
    required this.onSettingsNOTChanged,
    this.LocationPermisionButton = false,
    this.onRequestLocationPermission,
    required this.WeatherImageType,
    required this.deletepage,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _useDeviceLocation;
  late String _city;
  late TextEditingController _controller;
  bool _hidebutton = false;
  String? _selectedWeatherImageType;


  late final List<DropdownMenuEntry<String>> _weatherImageOptions = [
    DropdownMenuEntry(value: 'default', label: 'Standaard afbeeldingen'),
    DropdownMenuEntry(value: 'Piekie', label: 'Piekie'),
    DropdownMenuEntry(value: 'minimal', label: AppLocalizations.of(context)!.minimalisticIconsText),
  ];

  @override
  void initState() {
    super.initState();
    _useDeviceLocation = widget.useDeviceLocation;
    _city = widget.currentCity ?? '';
    _controller = TextEditingController(text: _city);
    
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedWeatherImageType = _weatherImageOptions.any(
      (entry) => entry.value == widget.WeatherImageType
      ) ?widget.WeatherImageType : 'default';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final trimmedCity = _controller.text.trim();

    if (_useDeviceLocation != widget.useDeviceLocation ||
        trimmedCity != (widget.currentCity ?? '' )) {
      //await SettingsStorage.saveSettings(_useDeviceLocation, trimmedCity);
      widget.onSettingsChanged(_useDeviceLocation, trimmedCity, _selectedWeatherImageType.toString());
    } else {
      widget.onSettingsNOTChanged(_selectedWeatherImageType!, true);
    }



    Navigator.pop(context, true);
  }

@override
Widget build(BuildContext context) {
  return PopScope(
    onPopInvokedWithResult: (didPop, result) async {
      if (result != true) {
        widget.onSettingsNOTChanged(_selectedWeatherImageType!, false);
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settingsText),
        backgroundColor:
            Theme.of(context).appBarTheme.backgroundColor ?? Colors.grey[200],
        elevation: Theme.of(context).appBarTheme.elevation ?? 4,
        shadowColor: Theme.of(context).appBarTheme.shadowColor ??
            const Color.fromARGB(153, 158, 158, 158),
      ),
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: 600, // Main content width constraint
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.useDeviceLocationText),
                      value: _useDeviceLocation,
                      onChanged: (value) {
                        setState(() {
                          _useDeviceLocation = value;
                        });
                      },
                    ),
                    if (!_useDeviceLocation)
                      TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.enterCityNameText,
                        ),
                      ),
                    const SizedBox(height: 16),
                    CustomDropdownMenu(
                      selectedItem: _selectedWeatherImageType,
                      items: _weatherImageOptions,
                      onSelected: (String? newValue) {
                        setState(() {
                          _selectedWeatherImageType = newValue;
                        });
                      },
                      label: 'Weer afbeelding stijl',
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color.fromARGB(255, 229, 229, 254),
                        shadowColor: const Color.fromARGB(136, 138, 138, 138),
                        elevation: 1.4,
                      ),
                      child: Text(AppLocalizations.of(context)!.saveButtonText),
                    ),
                    if (widget.LocationPermisionButton && _useDeviceLocation)
                      const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
          if (widget.LocationPermisionButton && _useDeviceLocation && !_hidebutton)
            Positioned(
              left: 0,
              right: 0,
              bottom: 60, // leave space for the new button
              child: Center(
                child: SizedBox(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (widget.onRequestLocationPermission != null) {
                          final hidebutton =
                              await widget.onRequestLocationPermission!();
                          setState(() {
                            _hidebutton = hidebutton;
                          });
                        }
                      } catch (e) {
                        print(e);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: const Color.fromARGB(255, 229, 229, 254),
                      shadowColor: const Color.fromARGB(136, 138, 138, 138),
                      elevation: 1.4,
                    ),
                    child: const Text(
                      'Locatie-toegang geven',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          // ✅ Extra button at the very bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(
              child: SizedBox(
                child: ElevatedButton(
                  onPressed: () {
                    widget.deletepage();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    backgroundColor: Colors.red[200],
                    shadowColor: const Color.fromARGB(136, 138, 138, 138),
                    elevation: 1.4,
                  ),
                  child: const Text(
                    'delete page',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}