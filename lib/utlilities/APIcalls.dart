import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:navapp2/consts.dart';


class APIcalls {
 
static Future<Map<String,dynamic>> fetchRoute(LatLng currentLoc, LatLng destination) async {
  DateTime now = DateTime.now();
  String formattedDate = now.toUtc().toIso8601String();
  var url = Uri.parse('https://routes.googleapis.com/directions/v2:computeRoutes');
  var apiKey = apikey;  // Replace with your actual API key
  var headers = {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': apiKey,
    'X-Goog-FieldMask': 'routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline,routes.legs',  // Added leg details
  };
  var body = jsonEncode({
    "origin": {
      "location": {
        "latLng": {
          "latitude": currentLoc.latitude,
          "longitude": currentLoc.longitude
        }
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
    "departureTime": formattedDate,
    "computeAlternativeRoutes": false,
    "routeModifiers": {
      "avoidTolls": false,
      "avoidHighways": false,
      "avoidFerries": false
    },
    "languageCode": "en-US",
    "units": "IMPERIAL"
  });

  try {
    var response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      // Parsing the response
      var jsonResponse = jsonDecode(response.body);
      // Parsing the routes
      var routes = jsonResponse['routes'][0];
      return routes;
    } else {
      print("Failed to retrieve routes with status code: ${response.statusCode}");
      return {
        'error' : response.body,
        'status_code': response.statusCode
      };
    }
  } catch (e) {
    throw("Error occurred during HTTP call: $e");
  }
}


static Future<List<dynamic>> getNearestRoads(LatLng currentLoc, LatLng exitLoc) async {
  String apiKey = apikey; // Replace with your actual API key
  String points = '${currentLoc.latitude},${currentLoc.longitude}| ${exitLoc.latitude}, ${exitLoc.longitude}';

  var url = Uri.parse('https://roads.googleapis.com/v1/nearestRoads?points=$points&key=$apiKey');

  try {
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data; // Process your data here
    } else {
      throw('Failed to fetch data with status code: ${response.statusCode}');
      print('Error response body: ${response.body}');
      return [];
    }
  } catch (e) {
    throw('An error occurred: $e');
  }
}

static Future<List<Map<String, dynamic>>> fetchNearbyPlaces(LatLng currentLoc) async {
  
  String url = 'https://places.googleapis.com/v1/places:searchNearby';

  try {
    var response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apikey,
        'X-Goog-FieldMask': 'places.displayName,places.types,places.location,places.viewport'
      },
      body: jsonEncode({
      
        'maxResultCount': 10,
        'locationRestriction': {
          'circle': {
            'center': {
              'latitude': currentLoc.latitude,
              'longitude': currentLoc.longitude
            },
            'radius': 500.0
          }
        }
      }),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      List<Map<String, dynamic>> places = [];
      for (var place in data['results']) {
        places.add({
          'types': place['types'],
          'position': {
            'location': place['geometry']['location'],
            'viewport': place['geometry']['viewport']
          },
          'displayName': place['name']
        });
      }
      return places;
    } else {
      print('Failed with status code: ${response.statusCode}');
      print('Error response body: ${response.body}');
      return [];
    }
  } catch (e) {
    print('An error occurred: $e');
    return [];
  }
}


}