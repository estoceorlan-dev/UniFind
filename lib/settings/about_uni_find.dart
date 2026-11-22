import 'package:flutter/material.dart';

class AboutUniFind extends StatelessWidget {
  const AboutUniFind({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,


        title: const Text(
          'About UniFind',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //header
            Container(
              alignment: Alignment.center,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    "UniFind",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Your Campus Companion",
                    style: TextStyle(
                      fontSize: 18,

                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            //content gisulod og card
            Container(
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
              child: const Text(
                '''
UniFind is a mobile application developed exclusively for 
Buenavista Community College (BCC). It serves as a centralized platform for students, faculty, and staff to stay connected and updated with important campus announcements, lost and found reports, schedules, and academic information.

The goal of UniFind is to improve communication inside BCC and provide a quick, easy, and reliable way to access school-related information anytime and anywhere.
''',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
