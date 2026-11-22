import 'package:flutter/material.dart';

bool usesCampusRail(Size size) => size.width >= 720 && size.height >= 500;

class CampusScaffold extends StatelessWidget {
  const CampusScaffold({
    super.key,
    required this.appBar,
    required this.body,
    required this.navigation,
    this.floatingActionButton,
  });
  final PreferredSizeWidget appBar;
  final Widget body, navigation;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final wide = usesCampusRail(MediaQuery.sizeOf(context));
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: SizedBox.expand(child: body),
      ),
    );
    return Scaffold(
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: wide ? null : navigation,
      body: wide
          ? Row(
              children: [
                navigation,
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
