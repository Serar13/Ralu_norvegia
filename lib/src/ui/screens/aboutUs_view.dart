import 'package:flutter/material.dart';
import 'package:ralu_norvegia/src/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class aboutUsView extends StatefulWidget {
  const aboutUsView({super.key});

  @override
  State<aboutUsView> createState() => _aboutUsViewState();
}

class _aboutUsViewState extends State<aboutUsView> {
  @override
  Widget build(BuildContext context) {
    final double iconSize = 75;
    final double iconSizeMailCall = 50;
    final double spacing = 50;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "About us",
          style: TextStyle(
            color: AppColors.accent3,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppColors.accent3),
        ),
      ),
      body: Container(
        color: AppColors.primary,
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Content container with scrolling
              Positioned(
                top: 50, // Height of the transparent area
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(25.0),
                    child: Text(
                      "Lorem ipsum content...",
                    ),
                  ),
                ),
              ),
              // Transparent area for design
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 50, // Height of the transparent area
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // Icons and buttons at the top
              Positioned(
                top: 10,
                left: (MediaQuery.of(context).size.width -
                    (25 + 2 * spacing + iconSize + 2 * iconSizeMailCall)) /
                    2,
                child: Row(
                  children: [
                    // Email Icon
                    Container(
                      height: iconSizeMailCall,
                      width: iconSizeMailCall,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        border: Border.all(color: AppColors.accent3, width: 2.0),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          try {
                            String? encodeQueryParameters(Map<String, String> params) {
                              return params.entries
                                  .map((MapEntry<String, String> e) =>
                              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                                  .join('&');
                            }

                            final Uri emailUri = Uri(
                                scheme: 'mailto',
                                path: 'raresimon@gmail.com',
                                query: encodeQueryParameters(<String, String>{
                                  'subject': 'Hello',
                                  'body': 'Heeloo from body :))'
                                })
                            );

                            if (await canLaunchUrl(emailUri)) {
                              await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                            } else {
                              throw 'Could not launch email';
                            }
                          } catch (e) {
                            print("Failed to launch email: $e");
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: Could not open email app. Please check if an email app is installed.")),
                            );
                          }
                        },
                          icon: Icon(Icons.email, color: AppColors.accent3),
                      ),
                    ),
                    SizedBox(width: spacing),
                    // Center Icon (fast food)
                    Container(
                      height: iconSize,
                      width: iconSize,
                      child: Icon(
                        Icons.fastfood,
                        size: iconSize,
                      ),
                    ),
                    SizedBox(width: spacing),
                    // Instagram Icon
                    Container(
                      height: iconSizeMailCall,
                      width: iconSizeMailCall,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        border: Border.all(color: AppColors.accent3, width: 2.0),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final Uri instagramUri = Uri.parse('https://www.instagram.com/vaskmedmeg/');
                          try {
                            if (await canLaunchUrl(instagramUri)) {
                              await launchUrl(instagramUri);
                            }
                          } catch (e) {
                            print("Error: $e");
                          }
                        },
                        icon: Image.asset('assets/instagram.webp'), // Can be replaced with an Instagram icon
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
