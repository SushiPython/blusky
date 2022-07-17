import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(const MyApp());
}

Future<Placemark?> _getCity(double lat, double lng) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      lat,
      lng,
    );
    return placemarks[0];
  } catch (e) {
    return null;
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  Position position = await Geolocator.getCurrentPosition();
  return position;
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'BluSky Weather',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(title: 'BluSky Home'),
        builder: EasyLoading.init());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _temp = 'Loading...';
  String _city = '...';
  String _imgUrl = 'https://miro.medium.com/max/1400/0*ptDX0HfJCYpo9Pcs.gif';
  static const codesToUrls = {
    0: {
      'name': 'Clear Sky',
      'url':
          'https://unsplash.com/photos/Mn6WChN0Q1o/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8NHx8Y2xlYXIlMjBza3l8ZW58MHx8fHwxNjU4MDY5MjY2&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/01d@2x.png'
    },
    1: {
      'name': 'Few Clouds',
      'url':
          'https://unsplash.com/photos/ROVBDer29PQ/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8Y2xlYXIlMjBza3l8ZW58MHx8fHwxNjU4MDY5MjY2&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/02d@2x.png'
    },
    2: {
      'name': 'Partly Cloudy',
      'url':
          'https://unsplash.com/photos/ROVBDer29PQ/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8Mnx8Y2xlYXIlMjBza3l8ZW58MHx8fHwxNjU4MDY5MjY2&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/02d@2x.png'
    },
    3: {
      'name': 'Overcast',
      'url':
          'https://unsplash.com/photos/pbxwxwfI0B4/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8MXx8b3ZlcmNhc3R8ZW58MHx8fHwxNjU4MDc5MjU2&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/03d@2x.png'
    },
    45: {
      'name': 'Fog',
      'url':
          'https://unsplash.com/photos/5FHv5nS7yGg/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc4NTcx&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/50d@2x.png'
    },
    48: {
      'name': 'Fog',
      'url':
          'https://unsplash.com/photos/5FHv5nS7yGg/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc4NTcx&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/50d@2x.png'
    },
    51: {
      'name': 'Light Drizzle',
      'url':
          'https://unsplash.com/photos/UsYOap7yIMg/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    53: {
      'name': 'Moderate Drizzle',
      'url':
          'https://unsplash.com/photos/UsYOap7yIMg/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    55: {
      'name': 'Heavy Drizzle',
      'url':
          'https://unsplash.com/photos/UsYOap7yIMg/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    56: {
      'name': 'Freezing Drizzle',
      'url':
          'https://unsplash.com/photos/UsYOap7yIMg/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    57: {
      'name': 'Freezing Drizzle',
      'url':
          'https://unsplash.com/photos/UsYOap7yIMg/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    61: {
      'name': 'Light Rain',
      'url':
          'https://unsplash.com/photos/bWtd1ZyEy6w/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/10d@2x.png'
    },
    63: {
      'name': 'Moderate Rain',
      'url':
          'https://unsplash.com/photos/bWtd1ZyEy6w/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/10d@2x.png'
    },
    65: {
      'name': 'Heavy Rain',
      'url':
          'https://unsplash.com/photos/bWtd1ZyEy6w/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/10d@2x.png'
    },
    66: {
      'name': 'Freezing Rain',
      'url':
          'https://unsplash.com/photos/bWtd1ZyEy6w/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/10d@2x.png'
    },
    67: {
      'name': 'Freezing Rain',
      'url':
          'https://unsplash.com/photos/bWtd1ZyEy6w/download?force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/10d@2x.png'
    },
    71: {
      'name': 'Light Snow',
      'url':
          'https://unsplash.com/photos/IWenq-4JHqo/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5Njk1&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/13d@2x.png'
    },
    73: {
      'name': 'Moderate Snow',
      'url':
          'https://unsplash.com/photos/IWenq-4JHqo/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5Njk1&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/13d@2x.png'
    },
    75: {
      'name': 'Heavy Snow',
      'url':
          'https://unsplash.com/photos/IWenq-4JHqo/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5Njk1&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/13d@2x.png'
    },
    77: {
      'name': 'Snow grains',
      'url':
          'https://unsplash.com/photos/IWenq-4JHqo/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5Njk1&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/13d@2x.png'
    },
    80: {
      'name': 'Light Rainshower',
      'url':
          'https://unsplash.com/photos/4XSdSFgKm8k/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8MXx8cmFpbnNob3dlcnxlbnwwfHx8fDE2NTgwNzk4MTE&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    81: {
      'name': 'Moderate Rainshower',
      'url':
          'https://unsplash.com/photos/4XSdSFgKm8k/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8MXx8cmFpbnNob3dlcnxlbnwwfHx8fDE2NTgwNzk4MTE&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    82: {
      'name': 'Heavy Rainshower',
      'url':
          'https://unsplash.com/photos/4XSdSFgKm8k/download?ixid=MnwxMjA3fDB8MXxzZWFyY2h8MXx8cmFpbnNob3dlcnxlbnwwfHx8fDE2NTgwNzk4MTE&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/09d@2x.png'
    },
    85: {
      'name': 'Light Snowshower',
      'url':
          'https://unsplash.com/photos/PzhmEp_aDU4/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc4NjU1&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/13d@2x.png'
    },
    86: {
      'name': 'Heavy Snowshower',
      'url':
          'https://unsplash.com/photos/PzhmEp_aDU4/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc4NjU1&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/13d@2x.png'
    },
    95: {
      'name': 'Thunderstorm',
      'url':
          'https://unsplash.com/photos/AtQoiUN_w1s/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5OTg4&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/11d@2x.png',
    },
    96: {
      'name': 'Hail Thunderstorm',
      'url':
          'https://unsplash.com/photos/AtQoiUN_w1s/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5OTg4&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/11d@2x.png',
    },
    99: {
      'name': 'Hail Thunderstorm',
      'url':
          'https://unsplash.com/photos/AtQoiUN_w1s/download?ixid=MnwxMjA3fDB8MXxhbGx8fHx8fHx8fHwxNjU4MDc5OTg4&force=true&w=640',
      'icon': 'http://openweathermap.org/img/wn/11d@2x.png',
    },
  };

  @override
  void initState() {
    EasyLoading.show(status: 'Loading Weather');
    super.initState();
    _loadWeather();
    EasyLoading.dismiss();
  }

  Function() checkWeather = () async {
    Position position = await _determinePosition();
    Placemark? placemark =
        await _getCity(position.latitude, position.longitude);
    final String currentTimeZone =
        await FlutterNativeTimezone.getLocalTimezone();
    var city = placemark?.locality;
    city ??= placemark?.subAdministrativeArea;
    city ??= placemark?.administrativeArea;
    var tempUnit = 'celsius';
    var windspeedUnit = 'kmh';
    var precipitationUnit = 'mm';
    if (placemark?.country == "United States") {
      tempUnit = 'fahrenheit';
      windspeedUnit = 'mph';
      precipitationUnit = 'inch';
    }
    final response = await Dio().get(
        'https://api.open-meteo.com/v1/forecast?latitude=${position.latitude}&longitude=${position.longitude}&hourly=temperature_2m,apparent_temperature,precipitation,rain,showers,snowfall,weathercode,snow_depth,cloudcover&daily=weathercode,temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,sunrise,sunset,precipitation_sum,rain_sum,showers_sum,snowfall_sum,windspeed_10m_max&timezone=$currentTimeZone&temperature_unit=$tempUnit&windspeed_unit=$windspeedUnit&precipitation_unit=$precipitationUnit&current_weather=true');
    var jsonResponse = json.decode(json.encode(response.data));
    var weatherImage =
        codesToUrls[jsonResponse['current_weather']['weathercode'].toInt()];
    return [jsonResponse, city, weatherImage];
  };

  void _loadWeather() {
    checkWeather().then((value) => {
          setState(() {
            _city = value[1];
            _temp = value[0]['current_weather']['temperature'].toString() +
                value[0]['hourly_units']['temperature_2m'];
            _imgUrl = value[2]['url'];
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Align(
        child: Card(
          shadowColor: Colors.black,
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(_imgUrl),
                fit: BoxFit.fitWidth,
                alignment: Alignment.topCenter,
              ),
            ),
            height: MediaQuery.of(context).size.height * 0.5,
            width: MediaQuery.of(context).size.width * 0.9,
            child: Text(_temp,
                style: const TextStyle(
                  fontSize: 50,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadWeather,
        tooltip: 'Add city',
        child: const Icon(Icons.add),
      ),
    );
  }
}
