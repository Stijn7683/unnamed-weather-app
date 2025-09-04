import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:weer_app/models/weer_model.dart';
import 'package:weer_app/service/weer_service.dart';
import 'settings_page.dart';
import 'package:weer_app/service/shared_prefs_helper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:weer_app/models/pages_model.dart';
import 'package:provider/provider.dart';

Timer? timer;

class WeatherPage extends StatefulWidget {
  final bool? initialUseDeviceLocation;
  final String? initialCity;
  final String? initialWeatherImageType;
  
  final int pageindex;

  const WeatherPage({
    super.key,
    this.initialUseDeviceLocation,
    this.initialCity,
    this.initialWeatherImageType,
    required this.pageindex,
  });

  @override
  State<WeatherPage> createState() => WeatherPageState();
}

class WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService("e58fa171634d277d7decadba84edeaea");
  Weather? _weather;
  String? _info;
  bool _useDeviceLocation = true;
  String? _customCity;
  (double?, double?) _position = (null, null);
  bool _klaarmetvoorbereiden = false;
  bool _instellingen = false;
  bool _hasbeennotdiniedforever = false;
  PermissionStatus? _loactionPermission;
  String _WeatherImageType = "default";
  bool _connection = false;
  DateTime? _previouslocationtime;
  bool _timerstarted = false;
  bool _LocationService = true;
  bool _ShouldLoadWeather = false;
  late StreamSubscription _connectivitySubscription;
  Locale? myLocale;
  int pageindex = 1;




  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    
    myLocale = Localizations.localeOf(context);


    voorbereiden();
    pageindex = widget.pageindex;



    if (widget.initialUseDeviceLocation != null) {
      if (!mounted) return;
      setState(() {
        _useDeviceLocation = widget.initialUseDeviceLocation!;
      });
    }
    if (widget.initialCity != null) {
      if (!mounted) return;
      setState(() {
        _customCity = widget.initialCity;
      });
    }
    if (widget.initialWeatherImageType != null) {
      print('initial weather image type:${widget.initialWeatherImageType}');
      _WeatherImageType = widget.initialWeatherImageType!;
    } 

    _connectivitySubscription =
      Connectivity().onConnectivityChanged.listen((results) {
        if (results.isNotEmpty && _weather == null && _klaarmetvoorbereiden) {
          print("verbindingveranderd");
          print(results.first != ConnectivityResult.none);
          
          if (results.first != ConnectivityResult.none){
            infoinstellen();
          } else if (_weather != null) {
            if (!mounted) return;
            setState(() {
              _info = "geenverbinding";
            });
          }
        }
      });
  }

  

  //@override
  void stop_timer() {
    print('stoptimer');
    timer?.cancel();
    //super.dispose();
    if (!mounted) return;
    setState(() {
      _timerstarted = false;
    });
  }

  Future<void> update() async {
    print('update');
    if (_loactionPermission == PermissionStatus.granted) {
      (double?, double?, String) position = await getCurrentPosition(false);
      if (!mounted) return;
      if (!mounted) return;
      setState(() {
        _position = (position.$1, position.$2);
      });
    }

    if (_connection) {
      _fetchWeather();
    }
    
  }

  Future infoinstellen() async {
    print(_instellingen);
    if (_instellingen) {
      if (_useDeviceLocation) {
        String? info = await _weatherService.permissioninfo();
        if (!mounted) return;
        setState(() {
          _info = info;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _info = null;
        });
      }
    } else {
      if (_useDeviceLocation && _position.$1 == null) {
        print("adsfjlkdsajfalksdfj");

        (double?, double?, DateTime?) savedlocation;

        savedlocation = await SettingsStorage.loadLocationInfo();


        if (savedlocation.$3 == null || DateTime.now().difference(savedlocation.$3!).inMinutes >= 10) {
          (double?, double?, String) position = await getCurrentPosition(false);
          if (_loactionPermission == null || _loactionPermission!.isDenied || _loactionPermission!.isPermanentlyDenied) {
            if (!mounted) return;
            setState(() { 
              _info = position.$3;
            });
          } else {
            if (!mounted) return;
            setState(() {
              _previouslocationtime = DateTime.now();
              _position = (position.$1, position.$2);
              _info = 'laden';
            });
            
            SettingsStorage.saveLocationInfo(position.$1, position.$2, _previouslocationtime);
          }
          if (!_timerstarted) {
            if (!mounted) return;
            setState(() {
              _timerstarted = true;
            });
          }
        } else {
          if (!_timerstarted) {
            if (!mounted) return;
            setState(() {
              _timerstarted = true;
            });
          }
        }
      } else {
        if (!mounted) return;
        setState(() {
          _info = 'laden';
        });
      }
      if (!mounted) return;
      setState(() {
        _ShouldLoadWeather = showSavedWeather();
      });
      if (_ShouldLoadWeather) {
        _fetchWeather();
      }
    }
  }

  Future<void> voorbereiden() async {
    Future<bool> savedweather = _weatherService.load();
    final Map<String, dynamic> settings = context.read<PagesModel>().pages[pageindex];
    if (pageindex >= context.read<PagesModel>().pages.length) return; // page got deleted, skip

    String info = 'laden';
    List<ConnectivityResult> connectivityResults;// = await Connectivity().checkConnectivity();
    PermissionStatus? locatietoegang;

    (double?, double?, String) position = (null, null, 'denied');
    bool loadWheather = true;
    DateTime? previouslocationtime;
    final useDevice = settings["useDeviceLocation"] ?? false;
    final city = settings["customCity"] ?? "";
    final weatherImageType = settings["imageType"] ?? "default";
    
    print('thevaules: $useDevice, $city, $weatherImageType');
    if (!mounted) return;
    setState(() {
      _useDeviceLocation = useDevice;
      _customCity = city;
      _WeatherImageType = weatherImageType;
    });
    if (useDevice){
      final (double?, double?, DateTime? ) savedlocation = await SettingsStorage.loadLocationInfo();
      print('savedlocationtime:');
      print(savedlocation.$3);
      if (savedlocation.$1 != null && await savedweather) {
        if (!mounted) return;
        setState(() {
          _position = (savedlocation.$1,savedlocation.$2);
        });
        loadWheather = showSavedWeather();
      }

      if (savedlocation.$3 == null || DateTime.now().difference(savedlocation.$3!).inMinutes >= 10) {
        
        Future Flocatietoegang =  Permission.location.status;
        Future FconnectivityResults = Connectivity().checkConnectivity();
        locatietoegang = await Flocatietoegang;
        if (locatietoegang!.isGranted) {
          if (!mounted) return;
          setState(() {
            _loactionPermission = PermissionStatus.granted;
          });
        } else if (locatietoegang.isDenied) {
          if (!mounted) return;
          setState(() {
            _loactionPermission = PermissionStatus.denied;
          });
        }
        connectivityResults = await FconnectivityResults;
        if (!connectivityResults.contains(ConnectivityResult.none) || _loactionPermission == PermissionStatus.granted) { 
          position = await getCurrentPosition(true); // get device location
          print('voorbereiden position:');
          print(position.$1);
          if (position.$3 != 'laden') {
            info = position.$3;
          } else {
            previouslocationtime = DateTime.now();
            SettingsStorage.saveLocationInfo(position.$1, position.$2, previouslocationtime);
            if (!mounted) return;
            setState(() {
              _position = (position.$1,position.$2);
            });
            if (await savedweather) {
              loadWheather = showSavedWeather();
            }
            info = 'laden';
            if (!mounted) return;
            setState(() {
              _timerstarted = true;
            });

          }
        }
      } else {
        //position = (savedlocation.$1, savedlocation.$2, '');
        previouslocationtime = savedlocation.$3;
        if (!mounted) return;
        setState(() {
          _timerstarted = true;
          _position = (savedlocation.$1, savedlocation.$2);
        });

        locatietoegang = await Permission.location.status;
        if (locatietoegang.isGranted) {
          if (!mounted) return;
          setState(() {
            _loactionPermission = PermissionStatus.granted;
          });
        } else if (locatietoegang.isPermanentlyDenied) {
          if (!mounted) return;
          setState(() {
            _loactionPermission = PermissionStatus.permanentlyDenied;
          });
        }
      } 
    } else { // don't use device location
      Future <PermissionStatus> Flocatietoegang = Permission.location.status;
      if (await savedweather) {
        loadWheather = showSavedWeather();
      }
      locatietoegang = await Flocatietoegang;
      if (locatietoegang.isGranted) {
        if (!mounted) return;
        setState(() {
          _loactionPermission = PermissionStatus.granted;
        });
      } else if (locatietoegang.isPermanentlyDenied) {
        if (!mounted) return;
        setState(() {
          _loactionPermission = PermissionStatus.permanentlyDenied;
        });
      }
    }
    if (info == 'laden') {
      connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        info = "geenverbinding";
      }
    }
    
    
    if (!mounted) return;
    setState(() {
      _info = info;
      _ShouldLoadWeather = loadWheather;
      _previouslocationtime = previouslocationtime;
      _klaarmetvoorbereiden = true;
    });

    if (info == 'laden' && loadWheather) {
      _fetchWeather();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    timer?.cancel(); 
    super.dispose();
  }

  Future<(double?, double?, String)> getCurrentPosition(bool tijdmeten) async {
    print("permission:");
    print(await Permission.location.status);
    PermissionStatus? locatietoegang = await Permission.location.status;
    if (_loactionPermission == null || _loactionPermission!.isDenied || _loactionPermission!.isPermanentlyDenied) {
      if (!mounted) return (null, null, 'denied');
      setState(() {
        _info = "denied";
      });
      if (_loactionPermission != null && _loactionPermission!.isPermanentlyDenied && _hasbeennotdiniedforever) {
        return (null, null, 'denied');
      }
      
      if (tijdmeten) {
        final stopwatch = Stopwatch();
        stopwatch.start();
        locatietoegang = await Permission.location.request();
        stopwatch.stop();
        int elapsed = stopwatch.elapsedMilliseconds;
        print("elapsed:");
        print(elapsed);
        if (elapsed < 650){
          print("testdfdsfdsf");
          if (!mounted) return (null, null, 'denied');
          setState(() {
            _hasbeennotdiniedforever = true;
            _loactionPermission = PermissionStatus.permanentlyDenied;
          });
          print("_loactionPermission set to:");
          print(_loactionPermission);
          return (null, null, 'denied');
        }
      } else {
        locatietoegang = await Permission.location.request(); // locatie vragen
      }

      if (locatietoegang.isPermanentlyDenied) {
        if (_hasbeennotdiniedforever) {
          if (!mounted) return (null, null, 'denied');
          setState(() {
            _loactionPermission = PermissionStatus.permanentlyDenied;
          });
          print("_loactionPermission set to:");
          print(_loactionPermission);
        }
        print("hasbeendeniedforever2");
        return (null, null, 'denied');
      } else {
        if (!mounted) return (null, null, 'denied');
        setState(() {
          _hasbeennotdiniedforever = true;
          _loactionPermission = locatietoegang;
        });
        print("hasbeennotdeniedforever");
        print("_loactionPermission set to:");
        print(_loactionPermission);
        if (locatietoegang.isDenied) {
          print("ERRORmisaksljflkdsajflksajlkasdjfklas");
          return (null, null, 'denied');
        }
      }
    }
    if (!mounted) return (null, null, 'denied');
    setState(() {
      _info = null;
    });
    Position position;
    try {   // try to get position
      position = await Geolocator.getCurrentPosition();

    } catch (e) {
      print('loacatiererror:');
      print(e);
      bool LocationService = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return (null, null, 'denied');
      setState(() {
        _LocationService = LocationService;
      });

      
      return (null, null, 'geenlocatieinfo');
    }
    if (!mounted) return (null, null, 'denied');
    setState(() {
      _LocationService = true;
    });
    return (position.latitude, position.longitude, 'laden');
  }

  bool showSavedWeather() { // returns if it should try to load weather 
    final (Weather?, double) opgeslagenweer = _useDeviceLocation && _position.$1 != null
      ? _weatherService.getCachedWeather(lat: _position.$1, lon: _position.$2)
      : (!_useDeviceLocation && _customCity != null)
          ? _weatherService.getCachedWeather(city: _customCity)
          : (null,12);

    print(_customCity);
    print('opgeslagen weer:');
    print(opgeslagenweer.$2);

    if (opgeslagenweer.$2 < 10) {
      if (!mounted) false;
      setState(() {
        _weather = opgeslagenweer.$1;
        _info = 'laden';
      });
      return opgeslagenweer.$2 >= 1;
    } else {
      return true;
    }
  }

  _fetchWeather() async {
    print("fetchweather");


    // laad het weer voor een ingestelde stad
    if (!_useDeviceLocation) {
      if (_customCity != null && _customCity!.isNotEmpty && _customCity != "") {
        try {
          final (Weather? weather, bool error) = await _weatherService.getWeather(_customCity, null, null, myLocale);
          print('weatherafterloadingfromlocation:');
          print(weather);
          if (error) {
            if (!mounted) return;
            setState(() {
              _info = "onbekende stad";
            });
            return;
          } else if (weather == null) {
            if (!mounted) return;
            setState(() {
              _info = "kon weer niet laden";
            });
            return;
          } else {
            if (!mounted) return;
            setState(() {
              _weather = weather;
              _info = 'laden';
            });
            _weatherService.addToCache(_customCity, weather.latitude, weather.longitude, weather, weather.icon);

            return;
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _info = "kon weer niet laden";
          });
          return;
        }
      } else {
        if (!mounted) return;
        setState(() {
          _info = "geen locatie";
        });
        return;
      }
    }

    print('_fetchweather position:');
    print(_position.$1);
    if (_position.$1 != null) {
      try {
        final (Weather? weather, bool error) = await _weatherService.getWeather(null, _position.$1, _position.$2, myLocale);
        if (weather == null) {
          if (_weather != null) {
            if (!mounted) return;
            setState(() {
              _info = "kon weer niet laden";
            });
          }
          //return;
        } else {
          if (!mounted) return;
          setState(() {
            _weather = weather;
          });
          _weatherService.addToCache(_weather?.cityName, _position.$1, _position.$2, weather, weather.icon);
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _info = "weer niet geladen";
        });
      }
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return '';

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'rain':
      case 'drizzle':
      case 'shower rain':
      case 'thunderstorm':
        return 'assets/wolken.json';
      case 'clear':
        return 'assets/zon.json';
      case 'few clouds':
        return 'assets/zon_en_wolk.json';
      default:
        return '';
    }
  }

  String getWeatherAnimation2(String? mainCondition, double? temperature) {
    if (mainCondition == null) return '';

    switch (mainCondition.toLowerCase()) {
      case 'few clouds':
        return 'assets/fdsalkjfdsakjkjfdsalk.jpg';
      case 'clouds':
        return 'assets/Piekie_overcast_clouds.jpg';
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'dust':
      case 'fog':
      case 'rain':
      case 'drizzle':
      case 'shower rain':
      case 'thunderstorm':
        return 'assets/Piekie_regen.jpg';
      case 'clear':
        return temperature?.round() == 27 ?'assets/Piekie_clear_sky_27.jpg' :'assets/Piekie_clear_sky.jpg';
      
      default:
        return '';
    }
  }


  (bool, String) getWeatherIcon3(String icon) {
    print('imageicon:');
    print(icon);
    switch (icon) {
      case '01d':
        return (false, 'assets/openweathermap_icons/01d@4x.png');
      case '02d':
        return (false, 'assets/openweathermap_icons/02d@4x.png');
      case '03d':
        return (false, 'assets/openweathermap_icons/03d@4x.png');
      case '04d':
        return (false, 'assets/openweathermap_icons/04d@4x.png');
      case '09d':
        return (false, 'assets/openweathermap_icons/09d@4x.png');
      case '10d':
        return (false, 'assets/openweathermap_icons/10d@4x.png');
      case '11d':
        return (false, 'assets/openweathermap_icons/11d@4x.png');
      
      default:
        return (true, 'https://openweathermap.org/img/wn/$icon@4x.png');
    }
  }

  void _openSettings() async {
    if (!mounted) return;
setState(() {
      _instellingen = true;
    });
    /*
    if (_position == (null,null)) {
      PermissionStatus? locatietoegang = await Permission.location.status;
      if (locatietoegang.isGranted) {
        if (!mounted) return;
setState(() {
          _position = (null,null);
        });
      }
    }
    */
    

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsPage(
          useDeviceLocation: _useDeviceLocation,
          currentCity: _customCity,
          WeatherImageType: _WeatherImageType, 
          LocationPermisionButton: _loactionPermission == null || _loactionPermission!.isDenied || !_LocationService,
          onSettingsChanged: (bool useDevice, String? city, String WeatherImageType) async { //settingschanged 
            print("changed");
            print(useDevice);
            if (!mounted) return;
            setState(() {
              _weather = null;
              _useDeviceLocation = useDevice;
              _customCity = city;
              _WeatherImageType = WeatherImageType;
            });

          final test = context.read<PagesModel>();
          print('kfdkfdsakjfdsalkj');

          test.updatePage(pageindex, {"useDeviceLocation": useDevice, "customCity": city, "imageType": WeatherImageType});


            stop_timer();
            
            if (!mounted) return;
            setState(() {
              _ShouldLoadWeather = showSavedWeather();
            });

            if (_ShouldLoadWeather) {
              String? info = "laden";

              List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();

              if (connectivityResults.contains(ConnectivityResult.none)) {
                info = "geenverbinding";
                if (!mounted) return;
                setState(() {
                  _connection = false;
                });
              } else {
                if (!mounted) return;
                setState(() {
                  _connection = true;
                });
                if (useDevice && _position.$1 == null && (_loactionPermission == null || !_loactionPermission!.isPermanentlyDenied)) {
                  (double?, double?, String) position = await getCurrentPosition(_loactionPermission == null);
                  if (_loactionPermission == null || _loactionPermission!.isDenied || _loactionPermission!.isPermanentlyDenied) {
                    info = position.$3;
                  } else {
                    if (!mounted) return;
                    setState(() {
                      _previouslocationtime = DateTime.now();
                      _position = (position.$1,position.$2);
                      _ShouldLoadWeather = showSavedWeather();
                    });
                    SettingsStorage.saveLocationInfo(position.$1, position.$2, _previouslocationtime);
                  }
                  List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();
                  if (connectivityResults.contains(ConnectivityResult.none)) {
                    info = "geenverbinding";
                  } else {
                    info = position.$3;
                  }
                }
              }

              if (!mounted) return;
              setState(() {
                _info = info;
                _instellingen = false;
              });
              
              if (_ShouldLoadWeather && info == 'laden') {
                _fetchWeather();
              }
            }
          },
          onSettingsNOTChanged: (String WeatherImageType, bool askPermission) async {
            print("nochange");
            if (!mounted) return;
            setState(() {
              _instellingen = false;
              if (WeatherImageType != _WeatherImageType) {
                _WeatherImageType = WeatherImageType;
                context.read<PagesModel>().updatePage(pageindex, {"imageType": WeatherImageType});
              }
              _ShouldLoadWeather = showSavedWeather();
            });


            if (_ShouldLoadWeather) {
              List<ConnectivityResult> connectivityResults = await Connectivity().checkConnectivity();
              print(connectivityResults.contains(ConnectivityResult.none));
              if (connectivityResults.contains(ConnectivityResult.none)) {
                if (!mounted) return;
                setState(() {
                  _info = "geenverbinding";
                });
              } else if (_useDeviceLocation) {
                if (_loactionPermission == null || _loactionPermission!.isDenied) {
                  if (askPermission) { // only ask permisson again when user pressed save button;
                    (double?, double?, String) position = await getCurrentPosition(false);
                    print("nochangeposition:");
                    print(position);
                    if (!(_loactionPermission == null || _loactionPermission!.isDenied || _loactionPermission!.isPermanentlyDenied)) {
                      if (!mounted) return;
                      setState(() {
                        _previouslocationtime = DateTime.now();
                        _position = (position.$1,position.$2);
                        _ShouldLoadWeather = showSavedWeather();
                      });
                    }
                    connectivityResults = await Connectivity().checkConnectivity();
                    if (connectivityResults.contains(ConnectivityResult.none)) {
                      if (!mounted) return;
                      setState(() {
                        _info = "geenverbinding";
                        _connection = false;
                      });
                    } else {
                      if (!mounted) return;
                      setState(() {
                        _info = position.$3;
                        _connection = true;
                      });
                      if (position.$1 != null && _ShouldLoadWeather) {
                        _fetchWeather();
                      }
                    }
                  }
                } else if (_ShouldLoadWeather && _position.$1 != null) { 
                  _fetchWeather();
                }
              } else if (_ShouldLoadWeather) {
                if (!mounted) return;
                setState(() {
                  _info = "laden";
                });
                _fetchWeather();
              }
            }
          },
          onRequestLocationPermission: () async {
            print("permissionrequest");
            print("permission:");
            print(await Geolocator.checkPermission());
            print(await Permission.location.status);
            print(_hasbeennotdiniedforever);

            PermissionStatus? locatietoegang;
            if (_loactionPermission == null){
              print("dothestopwatch");
              final stopwatch = Stopwatch();
              stopwatch.start();
              locatietoegang = await Permission.location.request();
              stopwatch.stop();
              int elapsed = stopwatch.elapsedMilliseconds;
              print("elapsed:");
              print(elapsed);
              if (elapsed < 650){
                print("testdfdsfdsf");
                if (!mounted) return false;
                setState(() {
                  _hasbeennotdiniedforever = true;
                  _loactionPermission = PermissionStatus.permanentlyDenied;
                });
                print("_loactionPermission set to:");
                print(_loactionPermission);
                return true;
              }
            } else {
              locatietoegang = await Permission.location.request();
            }
            if (!mounted) return false;
            setState(() {
              _loactionPermission = locatietoegang;
            });
            print(locatietoegang);
            if ((locatietoegang.isDenied || locatietoegang.isPermanentlyDenied)) {
              if (locatietoegang.isPermanentlyDenied) {
                if (_hasbeennotdiniedforever) {
                  if (!mounted) return false;
                  setState(() {
                    _loactionPermission = PermissionStatus.permanentlyDenied;
                    _position = (null,null);
                  });
                  print("1");
                  return true;
                } else {
                  print("2");
                  return false;
                }
              }
              if (!mounted) return false;
              setState(() {
                _loactionPermission = locatietoegang;
                _hasbeennotdiniedforever = true;
              });
              print("hasbeennotdeniedforever");
              
              return false; // don't hide
            } else {
              if (!_LocationService) {
                Position position;
                try {   // try to get position
                  position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

                } catch (e) {
                  print('loacatiererror:');
                  print(e);
                  bool LocationService = await Geolocator.isLocationServiceEnabled();
                  if (!mounted) return false;
                  setState(() {
                    _LocationService = LocationService;
                  });
                  if (LocationService) {
                    if (!mounted) return false;
                    setState(() {
                      _info = 'geenlocatieinfo';
                    });
                    return true;

                  }
                  return false;

                }
                if (!mounted) return false;
                setState(() {
                  _LocationService = true;
                  _position = (position.latitude, position.longitude);
                  _previouslocationtime = DateTime.now();
                });


              }
              if (!mounted) return false;
              setState(() {
                _info = "laden";
                _loactionPermission = locatietoegang;
                _hasbeennotdiniedforever = true;
              });
              return true;
            }
          },
          deletepage: () {
            if (context.read<PagesModel>().pages.length > 1) {
              context.read<PagesModel>().removePage(pageindex);
              Navigator.pop(context);
            } else {
              // maybe show a message that at least one page is required
            }
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(122, 189, 245, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 238, 238, 238),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings),
          iconSize: 37,
          onPressed: _openSettings,
        ),
      ),
      extendBodyBehindAppBar: true, // Laat body achter AppBar lopen
      body: Stack(
        children: [
          _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_weather?.mainCondition != null) 
            SizedBox(height: screenSize.height * 0.01),
          _buildLocationInfo(screenSize),
          if (_weather?.mainCondition != null) 
            SizedBox(height: screenSize.height * 0.04),
          if (_weather?.mainCondition != null)
            _buildWeatherAnimation(screenSize),
          if (_weather?.mainCondition != null) 
            SizedBox(height: screenSize.height * 0.02),
          if (_weather?.mainCondition != null)
            _buildWeatherDetails(screenSize),
        ],
      ),
    );
  }

Widget _buildLocationInfo(Size screenSize) {
  final hasWeather = _weather?.mainCondition != null;
  
  return SizedBox(
    width: screenSize.width * 0.8,
    height: hasWeather 
      ? screenSize.height * 0.13  // Taller height when weather exists
      : screenSize.height * 0.5, // Default height
    child: FittedBox(
      child: Center(
        child: Text(_buildLocationText(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    ),
  );
}

  String _buildLocationText() {
    String text;

    if (_weather == null) {
      switch (_info) {
        case 'denied':
          text = "locatie toegang geweigerd";
          break;
        case 'laden':
          text = AppLocalizations.of(context)!.loadingText;  // weer laden...
          break;
        case 'geenverbinding':
          text = "geen verbinding met internet";
          break;
        case 'kon weer niet laden':
          text = "kon weer niet laden";
          break;
        case 'geenlocatieinfo':
          text = "kon geen locatieinfo krijgen";
          break;
        case 'geen locatie':
          text = "geen locatie ingevuld";
          break;
        case 'onbekende stad':
          text = "onbekende locatie ingevuld";
          break;
        default:
          text = "laden...";
      }
    } else {
      text = _weather!.cityName;
    }

    return text;
  }



  Widget _buildWeatherAnimation(Size screenSize) {
    if (_WeatherImageType == "minimal") {
        bool loadfrominternet;
        String image;
        (loadfrominternet, image) = getWeatherIcon3(_weather!.icon);
        if (loadfrominternet) {
          if (_connection) {
            return SizedBox(
              width: screenSize.width * 0.96,
              height: screenSize.height * 0.5,
                child: Image.network(
                  'https://openweathermap.org/img/wn/${_weather!.icon}@4x.png',
                )
            );
          } else {
            return SizedBox(
              width: screenSize.width * 0.96,
              height: screenSize.height * 0.5,
              child: FittedBox(
                child: Icon(Icons.error)
              )
            );
          }
        } else {
          return SizedBox(
            width: screenSize.width * 0.96,
            height: screenSize.height * 0.5,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Image.asset(
                image
              ),
            )
          );
        }       
      
    } else if (_WeatherImageType == "default") {
      return SizedBox(
        width: screenSize.width * 0.96,
        height: screenSize.height * 0.5,
        child: FittedBox(
          child: Lottie.asset(
            getWeatherAnimation(_weather?.mainCondition),
            fit: BoxFit.contain,
          ),
        ),
      );
    } else {
      return SizedBox(
        width: screenSize.width * 0.96,
        height: screenSize.height * 0.5,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Image.asset(
            getWeatherAnimation2(_weather?.mainCondition, _weather?.temperature),
          ),
        ),
      );
    }
  }


  Widget _buildWeatherDetails(Size screenSize) {
    return SizedBox(
      width: screenSize.width * 0.8,
      height: screenSize.height * 0.15,
      child: FittedBox(
        child: 
          Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_weather?.temperature != null)
            Text(AppLocalizations.of(context)!.temperatureText(
              _weather?.temperature.round() ?? 0,
            )),

            Text(_weather?.description ?? ""),
            if (_weather?.windspeed != null)
              Text(AppLocalizations.of(context)!.windspeedText(
              (_weather!.windspeed * 10).round() / 10,
            )),
            if (_weather?.temp_min != null)
              Text(AppLocalizations.of(context)!.tempMinText(
              (_weather!.temp_min * 10).round() / 10,
            )),
            if (_weather?.temp_max != null)
              Text(AppLocalizations.of(context)!.tempMaxText(
              (_weather!.temp_max * 10).round() / 10,
            )),
          ],
        ),
      ),
    );
  }
}


class WeatherPager extends StatefulWidget {
  const WeatherPager({super.key});

  @override
  State<WeatherPager> createState() => _WeatherPagerState();
}

class _WeatherPagerState extends State<WeatherPager> {
  final PageController _controller = PageController();

  final List<Map<String, dynamic>> pagesSettings = [
    {
      'city': 'Amsterdam',
      'useDeviceLocation': false,
      'weatherImageType': 'minimal',
    },
    {
      'city': 'Paris',
      'useDeviceLocation': false,
      'weatherImageType': 'default',
    },
    {
      'city': 'London',
      'useDeviceLocation': false,
      'weatherImageType': 'other',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: pagesSettings.length,
        itemBuilder: (context, index) {
          final settings = pagesSettings[index];
          print('index: $index');
          print(settings);
          return WeatherPage(
            key: ValueKey(index),
            initialCity: settings['city'],
            initialUseDeviceLocation: settings['useDeviceLocation'],
            initialWeatherImageType: settings['weatherImageType'], pageindex: 1,
          );
        },
      ),
    );
  }
}