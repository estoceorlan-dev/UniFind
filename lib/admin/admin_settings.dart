import '../core/theme/appearance.dart';
import 'package:flutter/material.dart';
import '../settings/about_uni_find.dart';
import '../settings/admin_manual.dart';
import '../settings/app_version.dart';
import '../settings/contact_support.dart';
import '../settings/developers.dart';
import '../settings/faq.dart';
import '../settings/privacy_policy.dart';
import '../settings/terms_and_conditions.dart';




class AdminSettings extends StatelessWidget {
  const AdminSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [AppearanceMenu()],
        title: const Text("Settings"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          //Help & Support
          _buildSectionHeader("Help & Support"),
          _buildItem(
            icon: Icons.help_outline,
            title: "FAQ",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const FAQ()),
              );
            },
          ),
          _buildItem(
            icon: Icons.support_agent_outlined,
            title: "Contact Support",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ContactSupport()),
              );
            },
          ),
          _buildItem(
            icon: Icons.menu_book_outlined,
            title: "Admin Manual",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AdminManual()),
              );
            },
          ),

          const SizedBox(height: 20),

          //About the App
          _buildSectionHeader("About"),
          _buildItem(
            icon: Icons.info_outline,
            title: "About UniFind",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AboutUniFind()),
              );
            },
          ),
          _buildItem(
            icon: Icons.phone_android_outlined,
            title: "App Version",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AppVersion()),
              );
            },
          ),
          _buildItem(
            icon: Icons.people_alt_outlined,
            title: "Developers",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const Developers()),
              );
            },
          ),

          const SizedBox(height: 20),

          // SECTION: Legal
          _buildSectionHeader("Legal"),
          _buildItem(
            icon: Icons.article_outlined,
            title: "Terms & Conditions",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const TermsAndConditions()),
              );
            },
          ),
          _buildItem(
            icon: Icons.lock_outline,
            title: "Privacy Policy",
            onTap: () {
              Navigator.push(
                context, MaterialPageRoute(builder: (_) => const PrivacyPolicy()),
              );
            },
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  //section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,

        ),
      ),
    );
  }

  //Reusable item tile
  Widget _buildItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
