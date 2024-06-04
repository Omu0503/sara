import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';



class Leg {
  final LatLng start;
  final LatLng end;
  final String distanceText;
  final int distanceValue;
  final String instructions;
  

  Leg({required this.start, required this.end, required this.distanceText,
    required this.distanceValue, required this.instructions});

    Map<String, dynamic> toJson() {
    return {
      'distance': {
        'text': distanceText,
        'value': distanceValue,
      },
      'end_location': {
        'lat': end.latitude,
        'lng': end.longitude,
      },
      'html_instructions': instructions,
      'start_location': {
        'lat': start.latitude,
        'lng': start.longitude,
      }
    };
  }  

    factory Leg.fromJson(Map<String, dynamic> json) {
    return Leg(
      distanceText: json['distance']['text'],
      distanceValue: json['distance']['value'],
      start: LatLng(json['start_location']['lat'], json['start_location']['lng']),
      end: LatLng(json['end_location']['lat'], json['end_location']['lng']),
      instructions: json['html_instructions'],
    );
  }

}

class RouteLeg {
  
  final double endLat;
  final double endLng;
  
  final double startLat;
  final double startLng;

  RouteLeg({
    
    required this.endLat,
    required this.endLng,
    
    required this.startLat,
    required this.startLng,
  });

  
}


double calculateDistance(LatLng loc1, LatLng loc2) {
  var p = 0.017453292519943295; // Pi/180
  var a = 0.5 - cos((loc2.latitude - loc1.latitude) * p)/2 + 
          cos(loc1.latitude * p) * cos(loc2.latitude * p) * 
          (1 - cos((loc2.longitude - loc1.longitude) * p))/2;
  return 12742 * asin(sqrt(a)); // 2*R*asin...
}

bool arePointsNear(LatLng checkPoint, LatLng centerPoint, double km) {
  var ky = 40000 / 360;
  var kx = cos(pi * centerPoint.latitude / 180.0) * ky;
  var dx = (centerPoint.longitude - checkPoint.longitude).abs() * kx;
  var dy = (centerPoint.latitude - checkPoint.latitude).abs() * ky;
  return sqrt(dx * dx + dy * dy) <= km;
}


List<Leg> findCurrentLeg(List<Leg> legs, LatLng currentLocation) {
  Leg? currentLeg;
  Leg? nextLeg;

  for (final Leg leg in legs) {
    final endLocLeg = leg.end;
    if(arePointsNear(endLocLeg, currentLocation, 0.02)){
      legs.remove(leg);
      return legs;
    }
  }

  return legs;

  // print('Current Leg: Start at ${currentLeg?.start.latitude}, ${currentLeg?.start.longitude}');
  // print('Next Leg: Start at ${nextLeg?.start.latitude}, ${nextLeg?.start.longitude}');
}


