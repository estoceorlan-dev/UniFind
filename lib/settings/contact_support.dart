import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactSupport extends StatelessWidget {
  const ContactSupport({Key? key}) : super(key: key);

  void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$text" copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        elevation: 0,


        title: const Text(
          'Contact Support',
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
            // HEADER CARD
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
                      "Need Help?",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "We're here to assist you anytime.",
                      style: TextStyle(
                        fontSize: 16,

                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // CONTACT INFO CARD
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

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Contact Information",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,

                    ),
                  ),
                  const SizedBox(height: 20),

                  // EMAIL
                  InkWell(
                    onTap: () => copyToClipboard(context, "aunifind@gmail.com"),
                    child: Row(
                      children: const [
                        Icon(Icons.email, size: 28, color: Colors.blueGrey),
                        SizedBox(width: 15),
                        Text(
                          "aunifind@gmail.com",
                          style: TextStyle(
                            fontSize: 16,

                          ),
                        )
                      ],
                    ),
                  ),
           
                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () => copyToClipboard(context, "estoce.orlan@gmail.com"),
                    child: Row(
                      children: const [
                        Icon(Icons.email, size: 28, color: Colors.blueGrey),
                        SizedBox(width: 15),
                        Text(
                          "estoce.orlan@gmail.com",
                          style: TextStyle(
                            fontSize: 16,

                          ),
                        )
                      ],
                    ),
                  ),
           
                  const SizedBox(height: 20),

                  // PHONE
                  InkWell(
                    onTap: () => copyToClipboard(context, "+63 9462562663"),
                    child: Row(
                      children: const [
                        Icon(Icons.phone, size: 28, color: Colors.green),
                        SizedBox(width: 15),
                        Text(
                          "+63 946 256 2663",
                          style: TextStyle(
                            fontSize: 16,

                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () => copyToClipboard(
                        context, "Maricar Hagutin"),
                    child: Row(
                      children: const [
                        Icon(Icons.facebook, size: 28, color: Colors.blue),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "Maricar Hagutin",
                            style: TextStyle(
                              fontSize: 16,

                            ),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () => copyToClipboard(
                        context, "Justine Manatad"),
                    child: Row(
                      children: const [
                        Icon(Icons.facebook, size: 28, color: Colors.blue),
                        SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            "Justine Manatad",
                            style: TextStyle(
                              fontSize: 16,

                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
