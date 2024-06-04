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
import 'package:navapp2/screens/loadingScreen.dart';
import 'package:navapp2/screens/searchPage.dart';
import 'package:navapp2/utlilities/APIcalls.dart';
import 'package:navapp2/utlilities/GeolocationAlgo.dart';
import 'package:navapp2/utlilities/activationProvider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../AudioModule/audio.dart';
import '../utlilities/themes.dart';


List<Leg> legs = [];
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
    ValueNotifier<String> distance = ValueNotifier('');
    ValueNotifier<String> duration = ValueNotifier('');
    BitmapDescriptor originIcon = BitmapDescriptor.defaultMarker;
    BitmapDescriptor destiantionIcon = BitmapDescriptor.defaultMarker;

    void setMapIcons() {
      BitmapDescriptor.fromAssetImage(
              ImageConfiguration.empty, 'assets/images/origin.png')
          .then((value) => destiantionIcon = value);
    }

    void getPolyPoints(String polylinecode) async {
      PolylinePoints polylinePoints = PolylinePoints();
      final result =  polylinePoints.decodePolyline(polylinecode);

      if (result.isEmpty) {
        listOfPolyPts.value = [];
        return;
      }
      listOfPolyPts.value = [];
      result.forEach((point) =>
          listOfPolyPts.value!.add(LatLng(point.latitude, point.longitude)));
      listOfPolyPts.notifyListeners();
    }

    Future<Map<String, dynamic>> retrieveroutes(Places places) async {
      
      final routes = await APIcalls.fetchRoute(
          LatLng(places.currentLocCoords[0], places.currentLocCoords[1]),
          LatLng(places.destinationCoords[0], places.destinationCoords[1]));
      print(
          '********************************************************************************8');
      print(routes);
      final legsJson = routes['legs'];
       List<Leg> legs = legsJson.map((e) => Leg.fromJson(e)).toList();
      Timer.periodic(Duration(seconds: 15), (timer) { 
        legs = findCurrentLeg(legs,   LatLng(places.currentLocCoords[0], places.currentLocCoords[1]));
        
      });
      return {
        'distance' : routes['distanceMeters'],
        'duration': routes['duration'],
        'polyline_code': routes['polyline']['encodedPolyline']
      };
      
    }

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
        
        body: Consumer<Places>(
          
          builder: (context, places, child)  {
          bool destinationNotGiven = places.destinationCoords.every((element) => element == 0);
          if (!destinationNotGiven) {
            listOfPolyPts.value = [];
            final routes = retrieveroutes(places).then((value)  {
              getPolyPoints(value['polyline_code']);
              distance.value = value['distance'];
              duration.value = value['duration'];
              
              });
            showBothLocations(places);
            

          }
          final LatLng currentLoc = LatLng(places.currentLocCoords[0], places.currentLocCoords[1]);
          return ValueListenableBuilder<List<LatLng>?>(
              valueListenable: listOfPolyPts,
              builder: (context, polypts, snapshot) {
                return polypts != null && polypts.isEmpty  ? LoadingScreen() :Stack(
                  children: [
                    Consumer<LocationProvider>(
                      builder: (context, loc, child) {
                        if (places.currentLocCoords.every((element) => element==0)) places.currentLocCoords = [loc.locationData?.latitude ?? 0,loc.locationData?.longitude ?? 0];
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
                                    zoom: 13),
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
                                    color: myThemes.green,
                                    width: 5,
                                      polylineId: PolylineId('route'),
                                      points: polypts?? [])
                                },
                              );
                      },
                    ),
                     Positioned(
                      right: 10,
                      top: 120,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isSystemActivated,
                        builder: (context, isActivated, child) {
                          return  isActivated? const SizedBox(
                            width: 100,
                            height: 100,
                            child:  STT( )) : Container();
                        }
                      )
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
                        height: (
                                places.destinationCoords.every(
                                  (element) => element == 0,
                                ))
                            ? 180
                            : 220,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                              height: 24,
                            ),
                            !destinationNotGiven ? Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ValueListenableBuilder(
                                      valueListenable: distance,
                                      builder: (context, d, child) {
                                        return d.isEmpty? Container(
                                          height: 24,
                                          width: myThemes.returnWidth(context)*0.3,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: const Color.fromARGB(255, 53, 53, 53),
                                          ),
                                          
                                        ) : generalText('Distance: $d', color: myThemes.green, fontSize: 14,);
                                      }
                                    ),
                                    ValueListenableBuilder(
                                      valueListenable: duration,
                                      builder: (context, d, child) {
                                        return d.isEmpty? Container(
                                          height: 24,
                                          width: myThemes.returnWidth(context)*0.3,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: const Color.fromARGB(255, 53, 53, 53),
                                          ),
                                          
                                        ) : generalText('Distance: $d', color: myThemes.green, fontSize: 14,);
                                      }
                                    ),
                                    
                                  ],
                                ),
                               const Divider(
                                      color: Colors.black,  // Set the color of the divider
                                      height: 20,            // The divider's height, not the thickness
                                      thickness: 2,          // The thickness of the line itself
                                      indent: 20,            // Left side spacing
                                      endIndent: 20,         // Right side spacing
                                    )
                              ],
                            ):
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
                              height: 20,
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
                            !destinationNotGiven
                                ? GestureDetector(
                                    onTap: () async {
                                      //implement places API
                                      print("Current Location: ${places.currentLocCoords}");
                                     
                                      
                                      

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

  // void check(CameraUpdate u, GoogleMapController c) async {
  //   c.animateCamera(u);
  //   mapController?.animateCamera(u);
  //   LatLngBounds l1 = await c.getVisibleRegion();
  //   LatLngBounds l2 = await c.getVisibleRegion();
  //   print(
  //       '****************************************************************************');
  //   print(l1.toString());
  //   print(l2.toString());
  //   if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90)
  //     check(u, c);
  // }

  void showBothLocations(Places places) {
  LatLng currentLocation = LatLng(places.currentLocCoords[0], places.currentLocCoords[1]);
  LatLng destination = LatLng(places.destinationCoords[0], places.destinationCoords[1]);

  LatLngBounds bounds = LatLngBounds(
    southwest: LatLng(
      min(currentLocation.latitude, destination.latitude),
      min(currentLocation.longitude, destination.longitude)
    ),
    northeast: LatLng(
      max(currentLocation.latitude, destination.latitude),
      max(currentLocation.longitude, destination.longitude)
    ),
  );

  print("Current Location: $currentLocation");
  print("Destination: $destination");
  print("Bounds: $bounds");

  CameraUpdate update = CameraUpdate.newLatLngBounds(bounds, 100); // Increased padding
  mapController?.animateCamera(update).then((void v) {
    // check(update, mapController!); // Ensure this function checks or logs appropriately
  });
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
