// homePage.dart
import 'package:flutter/material.dart';
import 'camera/camera_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Drivense")),
      body: Center(
        child: Column(
          children: [// homePage.dart
        import 'package:flutter/material.dart';
        import 'camera/camera_screen.dart';

        class HomePage extends StatelessWidget {
        const HomePage({super.key});

        @override
        Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(title: const Text("Drivense")),
        body: Center(
        child: Column(
        children: [
        ElevatedButton(
        onPressed: () {
        Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
        },
        child: const Text(
        "Start",
        style: TextStyle(fontSize: 32, color: Colors.red),
        ),
        ),
        ],
        ),
        ),
        );
        throw UnimplementedError();
        }
        }

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CameraScreen()),
                );
              },
              child: const Text(
                "Start",
                style: TextStyle(fontSize: 32, color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
    throw UnimplementedError();
  }
}
