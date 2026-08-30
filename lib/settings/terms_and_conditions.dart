import 'package:flutter/material.dart';

class TermsAndConditions extends StatelessWidget {
  const TermsAndConditions({Key? key}) : super(key: key);

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget divider() {
    return const Divider(
      color: Colors.black26,
      thickness: 1,
      height: 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        backgroundColor: const Color.fromARGB(255, 201, 201, 201),
        foregroundColor: Colors.black87,
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
                      'Terms and Conditions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  divider(),

                  // SECTION 1
                  sectionTitle("1. Acceptance of Terms"),
                  const Text(
                    "By creating an account or using UniFind, you agree to these Terms and Conditions. "
                    "If you do not agree, please do not use the platform. These terms apply to all students, "
                    "staff, and alumni who access or use the app.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 2
                  sectionTitle("2. Purpose of the Platform"),
                  const Text(
                    "UniFind is an educational platform developed for BCC to help students and staff report, "
                    "locate, and retrieve lost and found items within the college community. The app serves "
                    "only as a communication tool and does not physically handle or guarantee the recovery of items.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 3
                  sectionTitle("3. Eligibility and Account Verification"),
                  const Text(
                    "Registration requires accurate personal details (Full Name, Course) and a valid school ID "
                    "photo for admin approval and verification.\n\n"
                    "User's real name will be displayed for reliability. Providing false or misleading details may "
                    "result in suspension or a permanent ban.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 4
                  sectionTitle("4. User Responsibilities"),
                  const Text(
                    "All users agree to:\n"
                    "• Post only truthful and accurate information.\n"
                    "• Avoid abusive, offensive, or misleading content.\n"
                    "• Understand that item ownership cannot be fully verified by admin.\n"
                    "• Use comments/messaging responsibly.\n"
                    "• Avoid spam, scams, and unrelated content.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 5
                  sectionTitle("5. Content Guidelines"),
                  const Text(
                    "Users may upload images and descriptions of items. All content must be appropriate and relevant. "
                    "Flagged or reported posts may be reviewed and removed. UniFind may display submitted content "
                    "for lost & found purposes only.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 6
                  sectionTitle("6. Admin Responsibilities & Limitations"),
                  const Text(
                    "A designated BCC staff member serves as admin. They may approve/ban users or remove posts when needed. "
                    "Admin cannot monitor the platform 24/7. BCC and the admin are not responsible for disputes, "
                    "false claims, or item conditions.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 7
                  sectionTitle("7. Privacy & Data Protection"),
                  const Text(
                    "Personal data (Name, Course, ID Photo, Profile Picture) is used only for verification and identification. "
                    "Information is not shared with third parties outside BCC unless required by law. Users should avoid "
                    "sharing sensitive details publicly.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 8
                  sectionTitle("8. Limitations of Liability"),
                  const Text(
                    "UniFind is only a tool for communication. BCC, developers, and admin are not liable for:\n"
                    "• Lost or stolen items\n"
                    "• Misuse of shared information\n"
                    "• Technical issues or downtime\n\n"
                    "Users engage in item recovery at their own risk.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 9
                  sectionTitle("9. Prohibited Conduct"),
                  const Text(
                    "Users may not:\n"
                    "• Impersonate others or submit fake IDs\n"
                    "• Post fraudulent reports\n"
                    "• Harass or threaten users\n"
                    "• Hack or disrupt the platform\n\n"
                    "Violations may result in suspension or permanent ban.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 10
                  sectionTitle("10. Updates to Terms"),
                  const Text(
                    "UniFind reserves the right to update these Terms at any time. Continued use of the app means you "
                    "accept the updated terms.",
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  divider(),

                  // SECTION 11
                  sectionTitle("11. Governing Authority"),
                  const Text(
                    "These Terms and Conditions follow the policies of Buenavista Community College (BCC).",
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
