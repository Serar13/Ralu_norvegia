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
    final double iconSize = 50;
    final double iconSizeMailCall = 50;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Om meg",
          style: TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppColors.accent),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primaryBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        width: MediaQuery.of(context).size.width,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Email Icon
                  Container(
                    height: iconSizeMailCall,
                    width: iconSizeMailCall,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
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
                            }),
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
                  SizedBox(width: 50),
                  // Website Icon
                  Container(
                    height: iconSize,
                    width: iconSize,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () async {
                        final Uri websiteUri = Uri.parse('https://vaskmedmeg.no/');
                        try {
                          if (await canLaunchUrl(websiteUri)) {
                            await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
                          }
                        } catch (e) {
                          print("Error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: Could not open website.")),
                          );
                        }
                      },
                      icon: Icon(Icons.language, color: AppColors.accent3),
                      tooltip: "Website",
                    ),
                  ),
                  SizedBox(width: 50),
                  // Instagram Icon
                  Container(
                    height: iconSizeMailCall,
                    width: iconSizeMailCall,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
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
                      icon: Image.asset('assets/instagram.webp'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Text(
                      'Hei! Jeg er Raluca, mor, kone og renholdsleder i Kristiansand – bedre kjent som @vaskmedmeg på Instagram. Som renholdsentusiast med 15 års erfaring (10 som faglært) elsker jeg å dele tips, triks og produkter som gjør vasking enklere og bidrar til en positiv holdning rundt renholdet.\n\n'
                      'Jeg vet hvordan det føles når vasking virker kjedelig og frustrerende – jeg var der selv! Men jeg har lært hva skal til for et lett og overkommelig vaskeliv og i appen "Vask med meg" hjelper jeg deg å gjøre det samme.\n\n'
                      'Her får du en smart vaskeplan med konkrete daglige økter som er enkle å følge. Si farvel til utsettelse, rot som hoper seg opp og helger tapt til maratonvask. Bygg rutiner, få kontroll og nyt et plettfritt hjem uten å slitte deg ut!\n\n'
                      'Velkommen til en ny vaskeverden – la oss starte i dag! Har du spørsmål? Sjekk appen eller kontakt meg via epost eller Instagram',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
