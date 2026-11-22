import 'package:flutter/material.dart';

class FAQ extends StatelessWidget {
  const FAQ({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,


        title: const Text(
          'FAQ',
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

            //header
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Frequently Asked Questions",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Find quick answers to your UniFind concerns.",
                      style: TextStyle(
                        fontSize: 16,

                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            //faq list
            _faqItem(context,
              question: "What is UniFind?",
              answer:
                  "UniFind is an official mobile application for BCC students, faculty, and staff to receive announcements, lost and found reports, and stay updated with school-related information.",
            ),

            _faqItem(context,
              question: "Do I need an account to use UniFind?",
              answer:
                  "Yes. Users must create an account first to view content to ensure safety and reliablity of campus-related information inside the app.",
            ),

            _faqItem(context,
              question: "How long do we wait to get verified?",
              answer:
                  "Depending on the staff or admin's availability and schedule. About 1-3 business days. ",
            ),
            _faqItem(context,
              question: "Who manages UniFind?",
              answer:
                  "The app is managed by authorized BCC staff and designated administrators who ensure that all information is accurate and updated.",
            ),

            _faqItem(context,
              question: "Can I report an issue or bug?",
              answer:
                  '''Yes, there are two ways to report an issue or bug. 
     1. You can report issues through the Contact Support page. Simply tap the email, phone number or facebook account to copy the details.
     2. Or simply message the admin's account within the app.
Just search the admin's account on the search page.
The system's admin is named by "System Admin" as default.
                  ''',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // FAQ CARD WIDGET
  Widget _faqItem(BuildContext context, {required String question, required String answer}) {
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,

          ),
        ),


        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,

            ),
          ),
        ],
      ),
    );
  }
}
