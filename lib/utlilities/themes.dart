import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../Models/Places.dart';

class generalText extends StatelessWidget {
  generalText(
    this.text, {
    this.fontSize = 18,
    this.color = const Color.fromRGBO(255, 244, 230, 1),
    this.alignment = TextAlign.center,
    this.font = FontWeight.bold,
    this.changeFontFamily = false,
    this.maxLines = 2,
    this.fontFamily = 'Inter',
    this.noOverflow = false,
    this.shouldUnderline = false,
    Key? key,
  }) : super(key: key);
  String text;
  double fontSize;
  Color color;
  TextAlign alignment;
  FontWeight font;
  bool changeFontFamily;
  int maxLines;
  bool noOverflow;
  String? fontFamily;
  bool shouldUnderline;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: alignment,
      maxLines: maxLines,
      overflow: noOverflow ? null : TextOverflow.ellipsis,
      style: TextStyle(
          fontFamily: changeFontFamily ? 'Moon Light' : fontFamily,
          // GoogleFonts.montserrat().fontFamily,
          fontSize: fontSize,
          color: color,
          decoration: shouldUnderline ? TextDecoration.underline : null,
          fontWeight: font),
    );
  }
}

class CustomTextField extends StatefulWidget {
  CustomTextField({super.key, required this.tapped, required this.placeholder});

  String placeholder;
  void Function() tapped;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _sessionToken;
  ValueNotifier<List<Suggestion>> suggestions = ValueNotifier([]);
  var uuid = Uuid();

  @override
  void initState() {
    // TODO: implement initState
    // widget.currentLocController.addListener(() {
    //   _sessionToken ??= uuid.v4();

    //   if (widget.currentLocController.text.length > 1) {
    //     getLocationResults(widget.currentLocController.text);
    //   } else {
    //     suggestions.value.clear();
    //     suggestions.notifyListeners();
    //   }
    // });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.tapped,
      child: Container(
        height: 40,
        width: MediaQuery.of(context).size.width * 0.7,
        decoration: BoxDecoration(
            color: Color.fromARGB(255, 204, 225, 215),
            borderRadius: BorderRadius.circular(12)),
        child: Center(
          child: generalText(
            widget.placeholder,
            color: Colors.black87,
            font: FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void getLocationResults(String input) async {
    String kPLACES_API_KEY = 'AIzaSyBD0_Obb3gHlBdJ9MIAig5dWoFnmdWg7uk';
    // String type = ‘(regions)’;
    String baseURL =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json";
    String request =
        "$baseURL?input=$input&key=$kPLACES_API_KEY&sessiontoken=$_sessionToken&circle:1000@";
    var response = await http.get(Uri.parse(request));
    if (response.statusCode == 200) {
      setState(() {
        final result = json.decode(response.body);
        suggestions.value = result['predictions']
            .map<Suggestion>((p) => Suggestion(p['place_id'], p['description'],
                p['structured_formatting']['main_text']))
            .toList();
      });
    } else {
      throw Exception('failed to load predictions');
    }
  }
}

class myThemes {
  static final green = Color.fromARGB(255, 121, 215, 170);
  static final black = Color.fromARGB(255, 36, 36, 36);

  static double returnWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double returnHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
}
