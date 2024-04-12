import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// We will use this util class to fetch the auto complete result and get the details of the place.
mixin PlaceApiProvider {
  // PlaceApiProvider(this.sessionToken);

  final apiKey = "AIzaSyBD0_Obb3gHlBdJ9MIAig5dWoFnmdWg7uk";

  http.Request createGetRequest(String url) =>
      http.Request('GET', Uri.parse(url));

  Future<List<Suggestion>> fetchSuggestions(
      String input, String sessionToken, double lat, double long) async {
    const radius = 100;
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&location=$lat,$long&radius=$radius&key=$apiKey&sessiontoken=$sessionToken';
    var request = createGetRequest(url);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final result = json.decode(data);

      print(result);

      if (result['status'] == 'OK') {
        return result['predictions']
            .map<Suggestion>((p) => Suggestion(p['place_id'], p['description'],
                p['structured_formatting']['main_text']))
            .toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  Future<PlaceDetail> getPlaceDetailFromId(
      String placeId, String sessionToken) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_address,name,geometry/location&key=$apiKey&sessiontoken=$sessionToken';
    var request = createGetRequest(url);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      final data = await response.stream.bytesToString();
      final result = json.decode(data);
      print(result);

      if (result['status'] == 'OK') {
        // build result
        final place = PlaceDetail();
        place.address = result['result']['formatted_address'];
        place.latitude = result['result']['geometry']['location']['lat'];
        place.longitude = result['result']['geometry']['location']['lng'];
        place.name = result['result']['geometry']['name'];
        return place;
      }
      throw Exception(result['error_message']);
    } else {
      throw Exception('Failed to fetch suggestion');
    }
  }

  // Future<List<Routes>> getRoutes(LatLng origin, LatLng destination) async {
  //    final uri = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');

  //   final reqBody = {
  //     "origin": {
  //       "location": {
  //         "latLng": {"latitude": origin.latitude, "longitude": origin.longitude}
  //       }
  //     },
  //     "destination": {
  //       "location": {
  //         "latLng": {
  //           "latitude": destination.latitude,
  //           "longitude": destination.longitude
  //         }
  //       }
  //     },
  //     "travelMode": "DRIVE",
  //     "routingPreference": "TRAFFIC_AWARE"
  //   };

  //   try {
  //     final response = await http.post(uri,
  //         headers: {
  //           "Content-Type": "application/json",
  //           "X-Goog-Api-Key": apiKey,
  //           "X-Goog-FieldMask":
  //               "routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline"
  //         },

  //         body: jsonEncode(reqBody));

  //     if (response.statusCode == 200) {
  //       final responseBody = jsonDecode(response.body);
  //       final List routeDataJson = responseBody['routes'];
  //       final routeData = routeDataJson
  //           .map((e) => Routes.fromJson(e, _decodePoints))
  //           .toList();
  //       return routeData;
  //     } else {
  //       print('Request failed with status: ${response.statusCode}');
  //     print('Response body: ${response.body}');
  //     return [];
  //     }
  //   } catch (e) {
  //     throw e;
  //   }
  // }

  Future<List<Routes>> getRoutes(LatLng origin, LatLng destination) async {
    var currentTime = DateTime.now().toUtc().add(2.seconds).toIso8601String();

    var url =
        Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
    var headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey, // Replace YOUR_API_KEY with your actual API key
      'X-Goog-FieldMask':
          'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline, routes.legs.step.polyline',
    };
    var body = json.encode({
      "origin": {
        "location": {
          "latLng": {"latitude": origin.latitude, "longitude": origin.longitude}
        }
      },
      "destination": {
        "location": {
          "latLng": {
            "latitude": destination.latitude,
            "longitude": destination.longitude
          }
        }
      },
      "travelMode": "DRIVE",
      "routingPreference": "TRAFFIC_AWARE",
      // "computeAlternativeRoutes": false,
      // "routeModifiers": {
      //   "avoidTolls": false,
      //   "avoidHighways": false,
      //   "avoidFerries": false
      // },
      // "languageCode": "en-US",
      // "units": "IMPERIAL"
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);

        if (responseBody['routes'] != null) {
          final List<dynamic> routeDataJson = responseBody['routes'];
          final routeData = routeDataJson
              .map((e) => Routes.fromJson(e,
                  _decodePoints)) // Make sure Routes.fromJson is correctly implemented
              .toList();
          return routeData;
        } else {
          print('No routes found');
          return [];
        }
      } else {
        print('Request failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching routes: $e');
      throw e;
    }

    // final uri = Uri.parse('https://maps.googleapis.com/maps/api/directions/json')
    //     .replace(queryParameters: {
    //   'origin': '${origin.latitude},${origin.longitude}',
    //   'destination': '${destination.latitude},${destination.longitude}',
    //   'mode': 'driving',
    //   'key': apiKey,
    // });

    // try {
    //   final response = await http.get(uri);

    //   if (response.statusCode == 200) {
    //     final responseBody = jsonDecode(response.body);

    //     if (responseBody['routes'] != null) {
    //       final List<dynamic> routeDataJson = responseBody['routes'];
    //       final routeData = routeDataJson
    //           .map((e) => Routes.fromJson(e, _decodePoints)) // Make sure Routes.fromJson is correctly implemented
    //           .toList();
    //       return routeData;
    //     } else {
    //       print('No routes found');
    //       return [];
    //     }
    //   } else {
    //     print('Request failed with status: ${response.statusCode}');
    //     print('Response body: ${response.body}');
    //     return [];
    //   }
    // } catch (e) {
    //   print('Error fetching routes: $e');
    //   throw e;
    // }
  }

  List<LatLng> _decodePoints(String encodedPoints) {
    int index = 0;
    double lat = 0;
    double lng = 0;
    List<LatLng> out = [];

    try {
      int shift;
      int result;
      while (index < encodedPoints.length) {
        shift = 0;
        result = 0;
        while (true) {
          int b = encodedPoints.codeUnitAt(index++) - '?'.codeUnitAt(0);
          result |= ((b & 31) << shift);
          shift += 5;
          if (b < 32) break;
        }
        lat += ((result & 1) != 0 ? ~(result >> 1) : result >> 1);

        shift = 0;
        result = 0;
        while (true) {
          int b = encodedPoints.codeUnitAt(index++) - '?'.codeUnitAt(0);
          result |= ((b & 31) << shift);
          shift += 5;
          if (b < 32) break;
        }
        lng += ((result & 1) != 0 ? ~(result >> 1) : result >> 1);
        /* Add the new Lat/Lng to the Array. */
        out.add(LatLng(lat * 10, lng * 10));
      }
      return out;
    } catch (e) {
      print(e);
    }
    return out;
  }
}

class Suggestion {
  final String placeId;
  final String description;
  final String title;

  Suggestion(this.placeId, this.description, this.title);
}

class PlaceDetail {
  String? address;
  double? latitude;
  double? longitude;
  String? name;

  PlaceDetail({
    this.address,
    this.latitude,
    this.longitude,
    this.name,
  });
}

class Routes {
  int totalDistance;
  String duration;
  List<LatLng> encodedPolyline;

  Routes(
      {required this.totalDistance,
      required this.duration,
      required this.encodedPolyline});

  factory Routes.fromJson(Map<String, dynamic> json,
          List<LatLng> Function(String encodedPoints) decoder) =>
      Routes(
          totalDistance: json['distanceMeters'],
          duration: json['duration'],
          encodedPolyline: decoder(json['polyline']['encodedPolyline']));
}
