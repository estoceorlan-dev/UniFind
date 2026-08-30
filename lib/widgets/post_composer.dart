import 'package:flutter/material.dart';
import '../screens/post_composer_screen.dart';

class PostComposer extends StatefulWidget {
  final String username; // keep only username ✅

  const PostComposer({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  State<PostComposer> createState() => _PostComposerState();
}

class _PostComposerState extends State<PostComposer> {
  bool _showOptions = false;

  /// Open post creation dialog
  void _openPostDialog(BuildContext context, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PostComposerScreen(
          username: widget.username, // pass only username ✅
          type: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            // Slide + Fade transition
            final offsetAnimation = Tween<Offset>(
              begin: const Offset(0.1, 0.2),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ));
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: _showOptions
              ? Column(
                  key: const ValueKey("options"),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 6),
                    if (widget.username == "admin")  // only show Announcement option for admin 
                    _buildOptionButton(
                      icon: Icons.campaign,
                      label: "Announcement",
                      color: const Color(0xFF143675),
                      onTap: () => _openPostDialog(context, "Announcement"),
                    ),
                     if (widget.username == "admin") const SizedBox(height: 6),
                    _buildOptionButton(
                      icon: Icons.search,
                      label: "Lost Item",
                      color: Colors.orange,
                      onTap: () => _openPostDialog(context, "Lost Item"),
                    ),
                    const SizedBox(height: 6),
                    _buildOptionButton(
                      icon: Icons.inventory,
                      label: "Found Item",
                      color: Colors.green,
                      onTap: () => _openPostDialog(context, "Found Item"),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.extended(
          backgroundColor: const Color(0xFF143675),
          icon: Icon(_showOptions ? Icons.close : Icons.add),
          label: Text(_showOptions ? "Close" : "Post"),
          onPressed: () {
            setState(() => _showOptions = !_showOptions);
          },
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        setState(() => _showOptions = false);
        onTap();
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
