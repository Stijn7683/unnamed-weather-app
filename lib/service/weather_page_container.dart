// weather_page_container.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:weer_app/pages/weer_pagina.dart';
import 'package:weer_app/models/pages_model.dart';
import 'package:provider/provider.dart';
import 'package:weer_app/service/shared_prefs_helper.dart';

  class WeatherPageContainer extends StatefulWidget {
    const WeatherPageContainer({super.key});
    

    @override
    State<WeatherPageContainer> createState() => WeatherPageContainerState();
  }

  final weatherPageKey = GlobalKey<WeatherPageContainerState>();

  class WeatherPageContainerState extends State<WeatherPageContainer> {
  
  

  final PageController _controller = PageController();
  int _targetPage = 0; // Track the target page we want to animate to
  final List<GlobalKey<WeatherPageState>> _weatherPageKeys = [];


  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    final test = context.read<PagesModel>();
    test.loadPages();
    final (double?, double?, DateTime? ) savedlocation = await SettingsStorage.loadLocationInfo();

    start_timer(DateTime.now().difference(savedlocation.$3!).inSeconds);

  }

  void start_timer(int startseconden) {
    print('starttimer');
    Future.delayed(
      Duration(seconds: startseconden), 
      () {
        if (startseconden != 0) {
          updateAllPages();
        }
        timer = Timer.periodic(
          const Duration(minutes: 10),
          (Timer t) => updateAllPages(),
        );
      },
    );
  }


  void updateAllPages() {
    for (final key in _weatherPageKeys) {
      key.currentState?.update();
    }
  }


  void _navigateToPreviousPage() {
    if (_targetPage > 0) {
      _targetPage--;
      _animateToPage(_targetPage);
    }
  }



  void _animateToPage(int page) {
    // Always jump to the current target immediately to override any ongoing animation
    _controller.animateToPage(
      _targetPage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PagesModel>(builder: (context, value, child) => LayoutBuilder(
      builder: (context, constraints) {
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowLeft): _navigateToPreviousPage,
            const SingleActivator(LogicalKeyboardKey.arrowRight): () {
              if (_targetPage < value.pages.length - 1) {
                _targetPage++;
                _animateToPage(_targetPage);
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              body: PageView.builder(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                itemCount: value.pages.length,
                itemBuilder: (context, index) {
                  final settings = value.pages[index];
                  return Stack(
                    children: [
                      //WeatherPageContainer(key: weatherPageKey),
                      WeatherPage(
                        key: ValueKey("weather_page_$index"),
                        initialUseDeviceLocation: settings["useDeviceLocation"],
                        initialCity: settings["customCity"],
                        initialWeatherImageType: settings["imageType"],
                        pageindex: index
                      ),

                      // Small remove button on top-right
                      Positioned(
                        top: 40,
                        right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            context.read<PagesModel>().removePage(index);
                            final lenght = value.pages.length;
                            if (_targetPage >= lenght) {
                              _targetPage = lenght - 1;
                              
                            }
                            /*
                            if (index >= value.pages.length) {
                              index = value.pages.length - 1;
                              _controller.jumpToPage(index);
                            } */
                          }
                        ),
                      ),
                    ],
                  );
                },
              ),

              // Floating add button
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  final test =  context.read<PagesModel>();
                  _targetPage = value.pages.length;

                  test.addPage();

                  _animateToPage(_targetPage);
                },
                child: const Icon(Icons.add),
              ),
            ),
          ),
        );
      },
    ));
  }
}