import 'package:flutter/material.dart';
import '../screens/post_composer_screen.dart';

class PostComposer extends StatelessWidget {
  const PostComposer({super.key, required this.username});
  final String username;

  Future<void> _chooseType(BuildContext context) async {
    final types = {
      'Lost Item': Icons.search_rounded,
      'Found Item': Icons.inventory_2_outlined,
      if (username == 'admin') 'Announcement': Icons.campaign_outlined,
    };
    final type = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Create a post',
                  style: Theme.of(sheet).textTheme.headlineSmall,
                ),
              ),
              for (final entry in types.entries)
                ListTile(
                  leading: Icon(entry.value),
                  title: Text(entry.key),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(sheet, entry.key),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (type == null || !context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PostComposerScreen(username: username, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FloatingActionButton.extended(
    onPressed: () => _chooseType(context),
    icon: const Icon(Icons.add),
    label: const Text('Post'),
  );
}
