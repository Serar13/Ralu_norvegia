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
    final double spacing = 50;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Om meg",
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
        child: Column(
          children: [
            // ICON ROW SUS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                SizedBox(width: spacing),
                // Website Icon
                Container(
                  height: iconSize,
                  width: iconSize,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    border: Border.all(color: AppColors.accent3, width: 2.0),
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
                    icon: Image.asset('assets/instagram.webp'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // CONTAINER CU TEXT (ca panoul tău alb de jos)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(25.0),
                  child: Text(
                    "Hei på deg og velkommen til min lille vaskeverden! Jeg er Raluca, vaskedama bak @vaskmedmeg kontoen på Instagram. Men først og fremst er jeg mor og kone, og renholdsleder i en bedrift i Kristiansand. Jeg er snart 44  år gammel og kan si at jeg lever den beste delen av mitt liv så langt. Så hva gjør jeg? Jeg kan kalles en renholds entusiast. Jeg har lært å like å gjøre rent og leter til enhver tid etter nye produkter, nytt utstyr og nye systemer som hjelper meg å gjøre rent hjemme, og ikke minst - til å holde det rent. Og den kunnskapen og erfaring jeg har fått gjennom nesten 15 år som renholder, hvorav 10 som faglært, og som jeg aktivt jobber med å utvide, det er den jeg elsker å dele med dere, for at vaskeoppgavene hjemme blir lettere, og at selve ordet 'vasking' får en positiv konnotasjon til seg. Det var ikke alltid sånn. Det var ikke sånn at jeg ikke kunne vaske, jeg bare følte at jeg ikke er noe god til dette, at det er vanskelig, frustrerende, kjedelig, at det tar så innmari lang tid bare for å se at det blir skitten og uryddig nok så fort igjen. Så ja … alt det negative med renholdet tok mye plass i hjernen. Men så livet tok meg fra Romania til Norge, en ting førte til en annen og om ikke så lenge ble jeg fast ansatt i en bedrift som jeg stortrives i. Fra gode kollegaer som satt pris på det jeg gjorde til kunnskapen fagbrevet brakt med seg, jeg så mer og mer verdien i yrket, og den mindset tok jeg med meg hjem. Jeg hadde så mange a-ha momenter som trolig har forandret både måten jeg vasker på hjemme,  men også planlegging og holdning rundt renholdet- og resultatet av det, at jeg bestemte meg for å dele med andre det jeg har lært og som hjalp meg få mer kontroll i hverdagen. Denne nettsiden her bygger jeg opp sakte men sikker og har som mål å inneholde akkurat og bare det som jeg tror virkelig kan gjøre en forskjell hjemme hos deg og! 'Must have' produkter, metoder, tankegang, inspirasjon, det er det som du kommer til å finne her! Å spre glede gjennom enkelt of effektiv rengjørings løsninger i vanlige husholdninger, og å hjelpe andre forenkle hverdagen er mitt største lidenskap. Så takk fordi du er her og leser, takk for at du engasjerer deg og ikke nål å ta kontakt via e-post eller instagram om det er noe du lurer på!", // restul textului tău
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
