import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:navapp2/Models/PlaceProviders.dart';
import 'package:navapp2/Models/Places.dart';
import 'package:navapp2/consts.dart';
import 'package:navapp2/screens/searchPage.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../utlilities/themes.dart';

class Home extends StatefulWidget {
  Home({Key? key, required this.placesProvider}) : super(key: key);

  Places placesProvider;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  TextEditingController currentLocController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  ValueNotifier<bool> isSearched = ValueNotifier(false);
  GoogleMapController? mapController;

  late Stream<List<PlaceDetail?>> combinedStream;

  @override
  void initState() {
    super.initState();
    Provider.of<LocationProvider>(context, listen: false).locationUpdate();
  }

  @override
  Widget build(BuildContext mainContext) {
    Set<Polyline> polylineSet = {};
    ValueNotifier<List<LatLng>?> listOfPolyPts = ValueNotifier(null);
    BitmapDescriptor originIcon = BitmapDescriptor.defaultMarker;
    BitmapDescriptor destiantionIcon = BitmapDescriptor.defaultMarker;

    void setMapIcons() {
      BitmapDescriptor.fromAssetImage(
              ImageConfiguration.empty, 'assets/images/origin.png')
          .then((value) => destiantionIcon = value);
    }

    void getPolyPoints(Places places) async {
      PolylinePoints polylinePoints = PolylinePoints();
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
          apikey,
          PointLatLng(places.currentLocCoords[0], places.currentLocCoords[1]),
          PointLatLng(
              places.destinationCoords[0], places.destinationCoords[1]));

      if (result.points.isEmpty) {
        listOfPolyPts.value = [];
        return;
      }
      listOfPolyPts.value = [];
      result.points.forEach((point) =>
          listOfPolyPts.value!.add(LatLng(point.latitude, point.longitude)));
      listOfPolyPts.notifyListeners();
    }

    // void retrieveroutes(Places places) async {
    //   routes = await places.getRoutes(
    //       LatLng(places.currentLocCoords[0], places.currentLocCoords[1]),
    //       LatLng(places.destinationCoords[0], places.destinationCoords[1]));
    //   print(
    //       '********************************************************************************8');
    //   print(routes);
    //   if (routes.isEmpty) {
    //     places.searchingRoute = true;
    //     retrieveroutes(places);
    //   } else {
    //     final routeSet = routes.toSet();
    //     polylineSet = routeSet
    //         .map((e) => Polyline(
    //             polylineId: PolylineId(''),
    //             points: e.encodedPolyline,
    //             color: myThemes.green,
    //             width: 4))
    //         .toSet();
    //     places.searchingRoute = false;
    //     print(polylineSet.first);
    //   }
    // }

    void animateCam(Places places) {
      mapController?.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(
                  places.destinationCoords[0], places.destinationCoords[1]),
              zoom: 14)));
    }

    @override
    void initState() {
      // TODO: implement initState
      super.initState();
      setMapIcons();
    }

    return Scaffold(
        backgroundColor: Colors.black87,
        body: Consumer<Places>(builder: (context, places, child) {
          if (!places.destinationCoords.every((element) => element == 0)) {
            animateCam(places);
          }
          return ValueListenableBuilder<List<LatLng>?>(
              valueListenable: listOfPolyPts,
              builder: (context, polypts, snapshot) {
                return Stack(
                  children: [
                    Consumer<LocationProvider>(
                      builder: (context, loc, child) {
                        return loc.locationData == null
                            ? const Center(
                                child: CupertinoActivityIndicator(
                                  radius: 10,
                                ),
                              )
                            : GoogleMap(
                                onMapCreated: (controller) {
                                  mapController = controller;

                                  setStyle();
                                },
                                initialCameraPosition: CameraPosition(
                                    target: LatLng(loc.locationData!.latitude!,
                                        loc.locationData!.longitude!),
                                    zoom: 14),
                                markers: {
                                  Marker(
                                    markerId:
                                        const MarkerId('Current Location'),
                                    position: LatLng(
                                        loc.locationData!.latitude!,
                                        loc.locationData!.longitude!),
                                  ),
                                  places.destinationAddress != null
                                      ? Marker(
                                          markerId:
                                              const MarkerId('destination'),
                                          position: LatLng(
                                              places.destinationCoords[0],
                                              places.destinationCoords[1]))
                                      : const Marker(markerId: MarkerId('null'))
                                },
                                polylines: {
                                  Polyline(
                                      polylineId: PolylineId('route'),
                                      points: listOfPolyPts.value ?? [])
                                },
                              );
                      },
                    ),
                    Positioned(
                      bottom: 4,
                      left: 14,
                      right: 14,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 550),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: myThemes.black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.only(top: 23),
                        width: MediaQuery.of(context).size.width,
                        height: (places.currentLocCoords
                                    .every((element) => element == 0) ||
                                places.destinationCoords.every(
                                  (element) => element == 0,
                                ))
                            ? 220
                            : 280,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 24,
                            ),
                            Align(
                                alignment: Alignment.center,
                                child: generalText(
                                  'Start your journey: ',
                                  fontSize: 28,
                                  color: myThemes.green,
                                  font: FontWeight.bold,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                  alignment: TextAlign.center,
                                )),
                            const SizedBox(
                              height: 10,
                            ),
                            CustomTextField(
                              placeholder: places.destinationAddress ??
                                  'Enter Destination',
                              tapped: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            ChangeNotifierProvider.value(
                                              value: widget.placesProvider,
                                              child: LocationSearchScreen(
                                                title:
                                                    'Search your Destination',
                                                type: 'Destination',
                                              ),
                                            )));
                              },
                            ),
                            const SizedBox(
                              height: 17,
                            ),
                            !(places.destinationCoords.every(
                              (element) => element == 0,
                            ))
                                ? GestureDetector(
                                    onTap: () {
                                      //implement places API
                                      showBothLocations(places);
                                      // getPolyPoints(places);
                                    },
                                    child: Container(
                                        decoration: BoxDecoration(
                                          color: myThemes.green,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        height: 40,
                                        width: 80,
                                        child: Center(
                                          child: generalText(
                                            'Go',
                                            color: myThemes.black,
                                          ),
                                        )),
                                  )
                                : Container()
                          ],
                        ),
                      ),
                    ),
                    polypts != null && polypts.isEmpty
                        ? Container(
                            width: myThemes.returnWidth(context),
                            height: myThemes.returnHeight(context),
                            color: Color.fromARGB(172, 0, 0, 0),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: myThemes.green),
                            ),
                          )
                        : Container()
                  ],
                );
              });
        }));
  }

  void setStyle() async {
    final style = await DefaultAssetBundle.of(context)
        .loadString('assets/mapsStyle.json');
    mapController!.setMapStyle(style);
  }

  // void showBothLocations(Places places) {
  //   List currentLocation = places.currentLocCoords;
  //   List destination = places.destinationCoords;
  //   var bounds = LatLngBounds(
  //     southwest: LatLng(
  //       min(currentLocation[0], destination[0]),
  //       min(currentLocation[1], destination[1]),
  //     ),
  //     northeast: LatLng(
  //       max(currentLocation[0], destination[0]),
  //       max(currentLocation[1], destination[1]),
  //     ),
  //   );

  //   mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 20));
  // }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    mapController?.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    print(
        '****************************************************************************');
    print(l1.toString());
    print(l2.toString());
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
      check(u, c);
  }

  void showBothLocations(Places places) {
    LatLng currentLocation =
        LatLng(places.currentLocCoords[0], places.currentLocCoords[1]);
    LatLng destination =
        LatLng(places.destinationCoords[0], places.destinationCoords[1]);

    // Check for antimeridian crossing
    ;

    LatLngBounds bound;
    if (destination.latitude > currentLocation.latitude &&
        destination.longitude > currentLocation.longitude) {
      bound = LatLngBounds(southwest: currentLocation, northeast: destination);
    } else if (destination.longitude > currentLocation.longitude) {
      bound = LatLngBounds(
          southwest: LatLng(destination.latitude, currentLocation.longitude),
          northeast: LatLng(currentLocation.latitude, destination.longitude));
    } else if (destination.latitude > currentLocation.latitude) {
      bound = LatLngBounds(
          southwest: LatLng(currentLocation.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, currentLocation.longitude));
    } else {
      bound = LatLngBounds(southwest: destination, northeast: currentLocation);
    }

    // Calculate bounds
    // var bounds = LatLngBounds(
    //   southwest: LatLng(
    //     min(currentLocation[0], destination[0]),
    //     isCrossingAntimeridian ? max(currentLocation[1], destination[1]) : min(currentLocation[1], destination[1]),
    //   ),
    //   northeast: LatLng(
    //     max(currentLocation[0], destination[0]),
    //     isCrossingAntimeridian ? min(currentLocation[1], destination[1]) : max(currentLocation[1], destination[1]),
    //   ),
    // );

    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bound, 50);
    mapController?.animateCamera(u2).then((void v) {
      check(u2, mapController!);
    });

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bound, 50));

    // Increased padding for better view
  }
}

class LocationProvider extends ChangeNotifier {
  LocationData? locationData;
  Location location = Location();

  Future<void> locationUpdate() async {
    bool _serviceEnabled;
    PermissionStatus _permissionStatus;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionStatus = await location.hasPermission();
    if (_permissionStatus == PermissionStatus.denied) {
      _permissionStatus = await location.requestPermission();
      if (_permissionStatus != PermissionStatus.granted) {
        return;
      }
    }

    locationData = await location.getLocation();
    notifyListeners();

    location.onLocationChanged.listen((event) {
      locationData = event;
      notifyListeners();
    });
  }
}
