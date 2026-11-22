import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  const LoadingSkeleton({super.key, this.posts = false});
  final bool posts;
  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: .55,
    upperBound: 1,
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      pulse.stop();
      pulse.value = 1;
    } else if (!pulse.isAnimating) {
      pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget block(double height, [double? width]) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    return Semantics(
      label: widget.posts ? 'Loading posts' : 'Loading list',
      liveRegion: true,
      child: ExcludeSemantics(
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12),
          itemCount: widget.posts ? 3 : 8,
          itemBuilder: (_, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: pulse,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: colors.surfaceContainerHighest,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              block(12, 126),
                              const SizedBox(height: 8),
                              block(9, 86),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.posts) ...[
                      const SizedBox(height: 16),
                      block(12),
                      const SizedBox(height: 12),
                      block(110),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
