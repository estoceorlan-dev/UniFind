import 'package:flutter/material.dart';

class UserGuide extends StatelessWidget {
  const UserGuide({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,


        title: const Text(
          'User Guide',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      "Guide for Users",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Learn how to navigate and use UniFind as a regular user.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,

                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),


            _guideItem(context,
              title: "How to message other users",
              steps: [
                {
                  "step": "Step 1",
                  "desc":
                      "Go to the search page.",
                  "img": "assets/images/msgstep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "Search for the user and tap their profile, this will navigate you to their profile page.",
                  "img": "assets/images/msgstep2.jpg"
                },
                {
                  "step": "Step 3",
                  "desc":
                      "Tap the message button, this will open the convo page.",
                  "img": "assets/images/msgstep3.jpg"
                },
                {
                  "step": "Step 4",
                  "desc":
                      "Another way is to simply tap the user's name or profile picure in posts or comments.",
                  "img": "assets/images/msgstep4.jpg"
                },
                {
                  "step": "Step 5",
                  "desc":
                      "Then type and send a message to begin conversation.",
                  "img": "assets/images/msgstep5.jpg"
                },
              ],
            ),

            _guideItem(context,
              title: "How to Post and \nreport lost and found item",
              steps: [
                {
                  "step": "Get Verrified",
                  "desc":
                      "You must first wait to get verified by the admin to be able to post.",
                  "img": "assets/images/postverified.jpg"
                },
                {
                  "step": "Step 1",
                  "desc":
                      "Navigate to the Newsfeed section from the home screen. \nIf you are verified then the post button will appear",
                  "img": "assets/images/poststep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "Tap the post button and choose the appropriate report.",
                  "img": "assets/images/poststep2.jpg"
                },
                {
                  "step": "Step 3",
                  "desc":
                      "Inside the post composer screen, fill in the report description then hit the post button.",
                  "img": "assets/images/poststep3.jpg"
                },
              ],
            ),

            _guideItem(context,
              title: "How to contact or \nmessage the admin",
              steps: [
                {
                  "step": "Step 1",
                  "desc":
                      "Search for the admin in the search page. \nSystem admin is named ''System Admin'' by default. \nIf changed, then search for admin by their default username ''admin''.",
                  "img": "assets/images/msgadminstep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "Tap the message button.",
                  "img": "assets/images/msgadminstep2.jpg"
                },
              ],
            ),

            _guideItem(context,
              title: "How to edit  profile",
              steps: [
                {
                  "step": "Step 1",
                  "desc":
                      "Tap profile picture in the top right corner. \nChoose profile.",
                  "img": "assets/images/editprofilestep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "In your profile page, tap  'Edit Profile'.",
                  "img": "assets/images/editprofilestep2.jpg"
                },
                {
                  "step": "Step 3",
                  "desc":
                      "Fill in the fields you only want to change. \nImportant! : Leave the fields you do not want to change blank.",
                  "img": "assets/images/editprofilestep3.jpg"
                },
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }



  Widget _guideItem(BuildContext context, {
    required String title,
    required List<Map<String, String>> steps,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.black54),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,

              ),
            ),
          ],
        ),


        children: steps.map((stepData) {
          final imagePath = stepData["img"];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //step title
              Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    stepData["step"] ?? "",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              //step description
              Text(
                stepData["desc"] ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,

                ),
              ),

              const SizedBox(height: 12),

              //optional image
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                  image: (imagePath != null && imagePath.isNotEmpty)
                      ? DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (imagePath == null)
                    ? const Center(
                        child: Text(
                          "No image added",
                          style: TextStyle(),
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 20),
            ],
          );
        }).toList(),
      ),
    );
  }
}
