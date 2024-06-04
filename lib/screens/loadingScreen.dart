import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navapp2/utlilities/themes.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: myThemes.returnHeight(context),
      width: myThemes.returnWidth(context),
      color: const Color.fromARGB(74, 0, 0, 0),
      child: Center(child: CupertinoActivityIndicator()),
    );
  }
}