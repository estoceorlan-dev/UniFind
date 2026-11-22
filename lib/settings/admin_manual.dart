import 'package:flutter/material.dart';

class AdminManual extends StatelessWidget {
  const AdminManual({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,


        title: const Text(
          'Admin Manual',
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
            // Header Card
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
                      "Manual for Admin",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Learn how to manage and operate UniFind efficiently.",
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

            // ------------------- MANUAL SECTIONS --------------------
            _manualItem(context,
              title: "Verifying Users",
              steps: [
                {
                  "step": "Step 1",
                  "desc":
                      "Go to User's  Section",
                  "img": "assets/images/verifystep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "And navigate to Verify Users page",
                   "img": "assets/images/verifystep2.jpg"
                },
                {
                  "step": "Step 3",
                  "desc":
                      "Tap verify button to verify users and tap id icon to view and confirm the user's id.",
                  "img": "assets/images/verifystep3.jpg"
                },
                {
                  "step": "Step 4",
                  "desc":
                      "Check and confirm the user's school id photo. Tap the picture to open a full screen dialog.",
                  "img": "assets/images/verifystep4.jpg"
                },
                {
                  "step": "Step 5",
                  "desc":
                      "Search for user in the search filter bar by their first name or last name.",
                  "img": "assets/images/verifystep5.jpg"
                },
              ],
            ),

            _manualItem(context,
              title: "How to remove a user",
              steps: [
                {
                  "step": "Step 1",
                  "desc":
                      "Go to User's  Section",
                  "img": "assets/images/removestep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "Tap remove icon and confirm.",
                  "img": "assets/images/removestep2.jpg"
                },
                {
                 "step": "Step 3",
                  "desc":
                      "Search for user in the search bar.",
                  "img": "assets/images/removestep3.jpg"
                },
                {
                 "step": "Step 4",
                  "desc":
                      "Go to the user's profile.",
                  "img": "assets/images/removestep4.jpg"
                },
                 {
                 "step": "Step 5",
                  "desc":
                      "Tap remove button and confirm.",
                  "img": "assets/images/removestep5.jpg"
                },
              ],
            ),

            _manualItem(context,
              title: "Delete Innappropriate posts \nand comments",
              steps: [
                {
                  "step": "Step 1",
                  "desc":
                      "Admin can delete or remove innappropirate posts and comments from users",
                  "img": "assets/images/deletestep1.jpg"
                },
                {
                  "step": "Step 2",
                  "desc":
                      "To remove posts, tap the menu toggle.",
                  "img": "assets/images/deletestep2.jpg"
                },
                {
                 "step": "Step 3",
                  "desc":
                      "Tap remove.",
                  "img": "assets/images/deletestep3.jpg"
                },
                {
                 "step": "Step 4",
                  "desc":
                      "And confirm.",
                  "img": "assets/images/deletestep4.jpg"
                },
                {
                 "step": "Step 5",
                  "desc":
                      "To delete comments, tap the trash icon.",
                  "img": "assets/images/deletestep5.jpg"
                },
                {
                 "step": "Step 6",
                  "desc":
                      "And confirm.",
                  "img": "assets/images/deletestep6.jpg"
                },
                
                
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  //reusable item builder
  Widget _manualItem(BuildContext context, {
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
            const Icon(Icons.menu_book_outlined, color: Colors.black54),
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
              // Step heading with icon
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.blueGrey),
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

              //Step description
              Text(
                stepData["desc"] ?? "",
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,

                ),
              ),

              const SizedBox(height: 12),

              //image/Placeholder box
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
