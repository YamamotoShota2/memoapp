import 'package:flutter/material.dart';

class BaseScreen extends StatelessWidget {
  final PreferredSizeWidget customAppBar;
  final Widget customAppBody;
  final Widget customBottomNavigationBar;

  const BaseScreen({
    required this.customAppBar, 
    required this.customAppBody, 
    required this.customBottomNavigationBar,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: customAppBar,
        body: customAppBody,
        bottomNavigationBar: customBottomNavigationBar,
      )
    );
  }
}