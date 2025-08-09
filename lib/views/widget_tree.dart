import 'package:drivense/data/notifiers.dart';
import 'package:drivense/views/pages/camera.dart';
import 'package:drivense/views/pages/home_page.dart';
import 'package:drivense/views/pages/profile_page.dart';
import 'package:drivense/views/pages/settings_page.dart';
import 'package:drivense/views/widgets/navbar_widgets.dart';
import 'package:flutter/material.dart';

List<Widget> pages = [HomePage(), ProfilePage()];

class WidgetsTree extends StatelessWidget {
  const WidgetsTree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Image.asset('assets/logo/aLogo.png'),
        title: Text(
          "DRIVENSE",
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.brown,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) =>
                  Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedPage, child) {
          return pages.elementAt(selectedPage);
        },
      ),
      bottomNavigationBar: NavbarWidgets(),
    );
    // TODO: implement build
    throw UnimplementedError();
  }
}
