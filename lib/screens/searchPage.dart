import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:location/location.dart';
import 'package:navapp2/Models/PlaceProviders.dart';
import 'package:navapp2/utlilities/themes.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../Models/Places.dart';

class LocationSearchScreen extends StatefulWidget {
  final title;
  String type;
  LocationData? defaultEntry;

  LocationSearchScreen(
      {Key? key, required this.title, required this.type, this.defaultEntry})
      : super(key: key);

  @override
  _LocationSearchScreenState createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final _controller = TextEditingController();
  final sessionToken = Uuid().v4();
  ValueNotifier<List<Suggestion>> suggestion = ValueNotifier([]);
  Timer? bouncer;

  @override
  void initState() {
    super.initState();

    _controller.addListener(() async {
      if (_controller.text.length > 1) {
        bouncer?.cancel();
        bouncer = Timer(600.milliseconds, () async {
         final currCords = Provider.of<Places>(context, listen: false).currentLocCoords; // Get current location coords to pass into the
          final getSuggestions =
              await Provider.of<Places>(context, listen: false)
                  .fetchSuggestions(
            _controller.text,
            sessionToken,
            currCords[0], //latitude
            currCords[1] //longitude
          );
          suggestion.value.insertAll(0, getSuggestions);
          suggestion.notifyListeners();
        });
      } else {
        bouncer?.cancel();
        suggestion.value.clear();
        suggestion.notifyListeners();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => onBackPressed(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  iconSize: 32,
                  padding: EdgeInsets.only(left: 16, top: 8),
                ),
                Container(
                    margin: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                    child: generalText(
                      widget.title,
                      fontSize: 22,
                      color: Colors.black,
                    ))
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 18, top: 8, right: 18),
              height: 48,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 196, 196, 196),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.start,
                autocorrect: false,
                autofocus: true,
                style: const TextStyle(
                    color: Colors.black, fontFamily: 'Inter', fontSize: 16),
                decoration: InputDecoration(
                  icon: Container(
                    margin: EdgeInsets.only(left: 12),
                    width: 32,
                    child: const Icon(
                      Icons.search_rounded,
                      color: Colors.black,
                      size: 32,
                    ),
                  ),
                  hintText: "Enter location",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: suggestion,
                builder: (context, suggested, child) => suggested.isEmpty
                    ? Container()
                    : Consumer<Places>(
                        builder: (context, placeProvider, child) =>
                            ListView.builder(
                                itemCount: suggested.length,
                                itemBuilder: (context, index) {
                                  final places = suggested[index];
                                  return ListTile(
                                    title: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                              top: 8, bottom: 4),
                                          child: generalText(
                                            places.title,
                                            fontSize: 16,
                                            color: Colors.black,
                                            font: FontWeight.w500,
                                            alignment: TextAlign.start,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.only(
                                              top: 4, bottom: 8),
                                          child: generalText(
                                            places.description,
                                            fontSize: 14,
                                            color: Colors.black,
                                            font: FontWeight.w300,
                                            alignment: TextAlign.start,
                                          ),
                                        ),
                                      ],
                                    ),
                                    leading: Container(
                                      child: const Icon(
                                        Icons.place_rounded,
                                        color: Colors.blue,
                                        size: 32,
                                      ),
                                    ),
                                    onTap: () {
                                      if (widget.type == 'Destination') {
                                        placeProvider.getDestinationCoords(
                                            places, sessionToken);
                                      }

                                      final timer = Timer(1000.ms, () {
                                        onBackPressed(context);
                                      });
                                    },
                                  );
                                }),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

onBackPressed(BuildContext context) => Navigator.of(context).pop();
