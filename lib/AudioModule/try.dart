import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:navapp2/utlilities/themes.dart';

class TryWidget extends StatelessWidget {
  const TryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      home: CupertinoPageScaffold(child: Center(child: GestureDetector(onTap: () => log("\n I love gay ppl?"),child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(color: Colors.green),
        child: generalText('Click me', color: Colors.white, fontSize: 20,),
        ),),),),
    );
  }
}