import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:navapp2/Models/Places.dart';

class Places extends ChangeNotifier with PlaceApiProvider {
  List<double> currentLocCoords = [0, 0];
  List<double> destinationCoords = [0, 0];
  String? currentAddress;
  String? destinationAddress;
  List<Routes> route = [];
  bool searchingRoute = false;

  void getCurrentLocCoords(
      {LocationData? defaultLoc}) async {
      currentAddress = 'Current Location';
      currentLocCoords[0] = defaultLoc?.latitude ?? 0;
      currentLocCoords[1] = defaultLoc?.longitude ?? 0;

      notifyListeners();
      return;
    
  }

  void getDestinationCoords(Suggestion place, String sessionToken) async {
    final placeDetails =
        await getPlaceDetailFromId(place.placeId, sessionToken);
    destinationAddress = place.title;
    destinationCoords[0] = placeDetails.latitude ?? 0;
    destinationCoords[1] = placeDetails.longitude ?? 0;

    notifyListeners();
    print(destinationCoords);
    print(destinationAddress);
  }

  void getPolylines(LatLng origin, LatLng destination) async {
    final routeData = await getRoutes(origin, destination);
    route.addAll(routeData);
    searchingRoute = true;
    notifyListeners();
  }
}
