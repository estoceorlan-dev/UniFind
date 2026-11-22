import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

typedef _RankedPost = ({
  Map<String, dynamic> post,
  bool pinned,
  int score,
  int created,
  String id,
});

/// Rank the loaded window, merging active announcements with recent reports.
List<Map<String, dynamic>> rankFeed(
  Iterable<Map<String, dynamic>> posts,
  DateTime now,
) {
  final cutoff = now.subtract(const Duration(days: 30));
  final unique = {for (final post in posts) post['id'] as String: post};
  final ranked = <_RankedPost>[];
  for (final entry in unique.entries) {
    final post = entry.value;
    final timestamp = post['createdAt'];
    final created = timestamp is Timestamp ? timestamp.toDate() : now;
    final announced =
        post['isAnnouncement'] == true ||
        (post['typeKey'] ?? post['type'])?.toString().toLowerCase() ==
            'announcement';
    final expires = post['expiresAt'];
    final active =
        announced && expires is Timestamp && expires.toDate().isAfter(now);
    if ((announced && expires is Timestamp && !active) ||
        (!active && created.isBefore(cutoff))) {
      continue;
    }
    final likes = post['likesCount'];
    // Each doubling buys 90 minutes of recency, up to a six-hour advantage.
    final bonus = likes is num && likes > 0 && !active
        ? (math.min(4, math.log(1 + likes) / math.ln2) *
                  90 *
                  Duration.millisecondsPerMinute)
              .round()
        : 0;
    final time = created.millisecondsSinceEpoch;
    ranked.add((
      post: post,
      pinned: active,
      score: time + bonus,
      created: time,
      id: entry.key,
    ));
  }
  ranked.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final time = b.created.compareTo(a.created);
    return time != 0 ? time : a.id.compareTo(b.id);
  });
  return [for (final row in ranked) row.post];
}
