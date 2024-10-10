import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';

class admin extends StatefulWidget {
  const admin({super.key});

  @override
  State<admin> createState() => _adminState();
}

class _adminState extends State<admin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: AppColors.primary,
        child: Center(
          child: WidgetFactory.buttonWithTextIcon(
          "Go to console",
          55,
          200,
          1.0,
          AppColors.accent3,
          Colors.white,
          2,
          Colors.white,
          null,
              () {
                GoRouter.of(context).go(adminConsolePath);
              }
              ),
        ),
      ),
    );
  }
}
