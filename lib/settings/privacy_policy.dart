import 'package:flutter/material.dart';

class PrivacyPolicy extends StatelessWidget {
  const PrivacyPolicy({Key? key}) : super(key: key);

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,

        ),
      ),
    );
  }

  Widget divider() {
    return const Divider(

      thickness: 1,
      height: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Privacy Policy'),


        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                  ),

                  divider(),

                  // SECTION 1
                  sectionTitle("1. Information We Collect"),
                  const Text(
                    "When you use UniFind, we may collect the following information:\n\n"
                    "a. Personal Information:\n"
                    "• Name, username, email address, school ID photo, and profile photo.\n"
                    "• Login credentials for app access.\n\n"
                    "b. Usage Information:\n"
                    "• Posts, comments, likes, and interactions.\n"
                    "• Notifications and app activity data.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 2
                  sectionTitle("2. How We Use Your Information"),
                  const Text(
                    "Your information is used to:\n"
                    "1. Provide and maintain app features such as newsfeed, chats, notifications, and lost-and-found.\n"
                    "2. Send announcements and updates.\n"
                    "3. Improve user experience and app security.\n"
                    "4. Administer and moderate user activity.\n"
                    "5. Comply with legal obligations and protect users and BCC.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 3
                  sectionTitle("3. Sharing and Disclosure"),
                  const Text(
                    "We do not sell, trade, or rent personal information. We may share information:\n"
                    "• With BCC administrators for moderation.\n"
                    "• To comply with legal requirements.\n"
                    "• To protect the rights and safety of UniFind, users, or the public.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 4
                  sectionTitle("4. Data Security"),
                  const Text(
                    "We implement reasonable safeguards to protect your information. However, no system is completely secure, and we cannot guarantee absolute protection.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 5
                  sectionTitle("5. User Rights"),
                  const Text(
                    "Users have the right to:\n"
                    "• Access, update, or correct their personal info.\n"
                    "• Request account deletion.\n\n"
                    "Contact UniFind support or the administrator to exercise these rights.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 6
                  sectionTitle("6. Data Retention"),
                  const Text(
                    "We retain user data while the account is active. Deleted accounts will have data removed within a reasonable timeframe unless legally required to retain it.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 7
                  sectionTitle("7. Children’s Privacy"),
                  const Text(
                    "UniFind is intended for college students and staff. We do not knowingly collect information from children under 13.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 8
                  sectionTitle("8. Changes to This Privacy Policy"),
                  const Text(
                    "We may update this Privacy Policy from time to time. Updates will be posted in the app, and the effective date will be changed accordingly. Continued use means acceptance of the updated policy.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 40), 
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
