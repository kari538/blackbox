import 'package:flutter/material.dart';

class SpinnerScreen extends StatelessWidget {
  const SpinnerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
