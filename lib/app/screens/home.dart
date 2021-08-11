import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          child: Text("Welcome"),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.shade100,
            border: Border.all(width: 4, color: Colors.black87),
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 2,
        title: Text("Data Editor"),
      ),
      drawer: Drawer(),
    );
  }
}
