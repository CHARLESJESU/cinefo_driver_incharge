import 'package:flutter/material.dart';
import 'package:production/Screens/Login/loginscreen.dart';


class Sessionexpired extends StatefulWidget {
  const Sessionexpired({super.key});

  @override
  State<Sessionexpired> createState() => _SessionexpiredState();
}

class _SessionexpiredState extends State<Sessionexpired> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/sessionexpired.jpg'),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Loginscreen()));
                },
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Center(
                      child: Text(
                    "please login again",
                    style: TextStyle(fontSize: 16),
                  )),
                ),
              )
            ],
          ),
        ));
  }
}
