import 'package:flutter/material.dart';
import 'package:todo_app/screens/home_page/home_page.dart';
import 'package:todo_app/utils/routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.homePage:
        return MaterialPageRoute(
          builder: (context) => const HomePage(),
          settings: settings,
        );

      default:
        return errorRoute();
    }
  }

  static Route<dynamic> errorRoute() {
    return MaterialPageRoute(
      builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Error In Loading Page"),
          ),
        );
      },
    );
  }
}
