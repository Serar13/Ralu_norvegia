import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ralu_norvegia/src/app/app_router.dart';
import 'package:ralu_norvegia/src/app/app_string.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:ralu_norvegia/src/ui/widgets/widget_factory.dart';

class WelcomeView extends StatefulWidget {
  const WelcomeView({Key? key}) : super(key: key);

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Color with a subtle cool tint
          Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.primaryBackground, // Cool White Background
          ),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            AppStrings.welcome(context),
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 50,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          "vaskmedmeg",
                          style: TextStyle(
                            color: AppColors.secondary, // Soft Navy Blue
                            fontSize: 50,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.primaryText, // Dark Charcoal
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                "sign in with",
                                style: TextStyle(
                                  color: AppColors.primaryText, // Dark Charcoal
                                  fontSize: 14, // Slightly smaller to maintain hierarchy
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.primaryText, // Dark Charcoal
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            WidgetFactory.buttonWithTextIconExpanded(
                              "Start with email",
                              55,
                              1,
                              AppColors.accent3, // Teal Green
                              Colors.white,
                              2,
                              Colors.white,
                                  () {
                                GoRouter.of(context).push(singinPath);
                                //GoRouter.of(context).push(ChooseOptionPath);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: AppColors.primaryText, // Dark Charcoal
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            child: Text(
                              "Log in",
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                decorationColor: Colors.transparent,
                                decorationThickness: 2.0,
                                color: AppColors.accent3,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                               GoRouter.of(context).push(loginPath);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
