import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 

class Developers extends StatelessWidget {
  const Developers({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,


        title: const Text(
          'Developers',
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
            // HEADER
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
                      "Meet the Developers",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "The creators behind UniFind",
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


            _sectionTitle("Lead Developer"),
            _developerCard(context,
              name: "Orlandone Estoce", 
              role: "Project Lead & Developer",
              email: "estoce.orlan@gmail.com",
              facebook: "Orlan Castillo Estoce",
              imgPath: "assets/images/orlan.png",
            ),

            const SizedBox(height: 25),


            _sectionTitle("Group Members"),

            // LIST OF 9 MEMBERS
            _developerCard(context,
              name: "Rynhard Mencede",
              role: "Developer",
              email: "mencederynhard12@gmail.com",
              facebook: "Rhynhard Mencede",
              imgPath: "assets/images/rynhard.png",
            ),
            _developerCard(context,
              name: "Dave Estoce",
              role: "Developer",
              email: "daveestoce0@gmail.com",
              facebook: "Dave Estoce",
              imgPath: "assets/images/dave.jpg",

            ),
            _developerCard(context,
              name: "John Clark Logroño", 
              role: "Developer",
              email: "logronoclark2@gmail.com",
              facebook: "Clark Logroño",
              imgPath: "assets/images/Clark.png",
            ),
            _developerCard(context,
              name: "Maricar Hagutin",
              role: "Developer",
              email: "maricarhagutin13@gmail.com ",
              facebook: "Maricar M. Hagutin",
              imgPath: "assets/images/maricar.jpg",
            ),
            _developerCard(context,
              name: "Charlyn Gay Mencede",
              role: "Developer",
              email: "gayledecnem26@gmail.com",
              facebook: "Lyn Basillote Mencede BSIT-IV DJANGO ",
              imgPath: "assets/images/Charlyn.jpg",
            ),
            _developerCard(context,
              name: "Jomel Logroño",
              role: "Developer",
              email: "jomellogronio6@gmail.com",
              facebook: "Jomel Logroño",
              imgPath: "assets/images/jomel.jpg",
            ),
            _developerCard(context,
              name: "Justine Manatad",
              role: "Developer",
              email: "justinemanatad59@gmail.com",
              facebook: "Justine Manatad ",
              imgPath: "assets/images/justine.jpg",
            ),
            _developerCard(context,
              name: "Judy Mae Petalcorin",
              role: "Developer",
              email: "judypetalcorin041@gmail.com",
              facebook: "Judy Mae Petalcorin",
              imgPath: "assets/images/judy.jpg",
            ),
            _developerCard(context,
              name: "Ashley Bentulan",
              role: "Developer",
              email: "Ashleybentulan15@gmail.com",
              facebook: "Ashley Sagario Bentulan",
              imgPath: "assets/images/ashley.jpg",
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,

        ),
      ),
    );
  }


  Widget _developerCard(BuildContext context, {
    required String name,
    required String role,
    required String email,
    required String facebook,
    String? imgPath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
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

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey[300],
            backgroundImage:
                imgPath != null ? AssetImage(imgPath) : null,
            child: imgPath == null
                ? const Icon(Icons.person, size: 35, color: Colors.black54)
                : null,
          ),

          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,

                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 14,

                  ),
                ),

                const SizedBox(height: 14),

                //email
                _socialTile(
                  icon: Icons.email_outlined,
                  label: email,
                ),

                const SizedBox(height: 8),

                //facebook
                _socialTile(
                  icon: Icons.facebook,
                  label: facebook,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //social tile - ma copy
  Widget _socialTile({required IconData icon, required String label}) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: label));
      },
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,

              ),
            ),
          ),
          const Icon(Icons.copy, size: 18, color: Colors.black45),
        ],
      ),
    );
  }
}
