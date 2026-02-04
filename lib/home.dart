import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'selectcity.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Lottie.asset('assets/animations/background.json',
                fit: BoxFit.cover),
          ),
          Positioned(
            top: 20,
            child: Lottie.asset(
              'assets/animations/animation2.json',
              height: 300,
            ),
          ),
          Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Welcome to',
                style: TextStyle(
                  fontSize: 36,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.5,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Weather Vibe',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 40,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent.shade400,
                      letterSpacing: 5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          offset: Offset(6, 3),
                          blurRadius: 10,
                        ),
                        Shadow(
                          color: Colors.orangeAccent.withOpacity(0.6),
                          offset: Offset(-1, -1),
                          blurRadius: 6,
                        ),
                      ],
                    )),
              ),
            ),
            SizedBox(height: 35),
            SizedBox(
              height: 50,
              width: 200,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => SelectCity()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: Colors.black,
                    elevation: 10,
                  ),
                  child: Text('Get Started',
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ))),
            ),
          ])),
        ],
      ),
    );
  }
}
