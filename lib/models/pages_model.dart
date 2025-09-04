import 'dart:math';

import 'package:flutter/material.dart';
import 'package:weer_app/service/shared_prefs_helper.dart';

class PagesModel extends ChangeNotifier{
  List<Map<String, dynamic>> pages = [
    {"useDeviceLocation": true, "customCity": null, "imageType": "default"},
  ];

  void updatePage(int index, Map<String, dynamic> newSettings) async {
    print('jaaaaaaaaaaaaaaaaaaaaa');
    await SettingsStorage.editPage(index, newSettings);
    
    pages = SettingsStorage.loadPages();
    print(pages);
  
  }

  Map<String, dynamic> loadsettings(int page) {
    return pages[page];
  }

  void loadPages() {
    pages = SettingsStorage.loadPages();

    // If no pages stored, create defaults
    if (pages.isEmpty) {
      pages = [
        {
          'city': 'Amsterdam',
          'useDeviceLocation': false,
          'ImageType': 'minimal',
        },
        {
          'city': 'Paris',
          'useDeviceLocation': false,
          'ImageType': 'default',
        },
      ];
      SettingsStorage.savePages(pages);
    }
  }

  Future<void> addPage() async {
    final types = ["default", "minimal", "other"];
    final random = Random();


    await SettingsStorage.addPage({
      'city': 'New City',
      'useDeviceLocation': true,
      'ImageType': types[random.nextInt(types.length)],
    });

    
    pages.add({
      'city': 'New City',
      'useDeviceLocation': true,
      'ImageType': types[random.nextInt(types.length)],
    });
      notifyListeners(); // <--- ADD THIS
  }

  void removePage(int index) {
    if (pages.length == 1) return; // Keep at least one
    if (index >= pages.length) return; // Invalid index

    pages.removeAt(index);
    SettingsStorage.removePage(index);
    notifyListeners(); // <--- ADD THIS
    
    // Adjust target page if needed
    print('removed page $index');
    
  }
}