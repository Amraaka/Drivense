import 'package:flutter/material.dart';

class HeroWidgets extends StatelessWidget {
  const HeroWidgets({super.key});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "Logo",
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset("assets/logo/aLogo.png"),
      ),
    );
    // TODO: implement build
    throw UnimplementedError();
  }
}
