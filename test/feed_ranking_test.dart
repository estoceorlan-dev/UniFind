import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unifind/repositories/feed_ranking.dart';

void main() {
  final now = DateTime.utc(2026, 11, 22, 12);
  Map<String, dynamic> post(
    String id,
    int hours, {
    int likes = 0,
    int? expires,
  }) => {
    'id': id,
    'likesCount': likes,
    'createdAt': Timestamp.fromDate(now.subtract(Duration(hours: hours))),
    if (expires != null) ...{
      'type': 'Announcement',
      'expiresAt': Timestamp.fromDate(now.add(Duration(hours: expires))),
    },
  };
  List<String> ids(List<Map<String, dynamic>> posts) =>
      rankFeed(posts, now).map((p) => p['id'] as String).toList();
  test(
    'Pins active announcements once and removes expired and stale posts',
    () {
      final pinned = post('notice', 720, likes: 6, expires: 1);
      expect(
        ids([
          post('report', 0),
          pinned,
          post('expired', 1, expires: 0),
          pinned,
          post('old', 721),
        ]),
        ['notice', 'report'],
      );
    },
  );
  test('Engagement can lift a recent item but caps out at six hours', () {
    expect(
      ids([
        post('popular', 2, likes: 7),
        post('latest', 0),
        post('older', 7, likes: 999999),
      ]),
      ['popular', 'latest', 'older'],
    );
  });
  test('Breaks score ties by recency, then ID even if input order changes', () {
    final posts = [post('b', 0), post('boosted', 3, likes: 3), post('a', 0)];
    expect(ids(posts), ['a', 'b', 'boosted']);
    expect(ids(posts.reversed.toList()), ids(posts));
  });
}
