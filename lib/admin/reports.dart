import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../screens/tap_notif_page.dart';
import '../screens/user_profile_2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({Key? key}) : super(key: key);

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String? _currentAdmin;

  @override
  void initState() {
    super.initState();
    _loadCurrentAdmin();
  }

  Future<void> _loadCurrentAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentAdmin = prefs.getString('username') ?? 'admin';
    });
  }

  Future<List<Map<String, dynamic>>> _fetchReports() async {
    final query = await FirebaseFirestore.instance
        .collection('reports')
        .orderBy('reportedAt', descending: true)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'postId': data['postId'], // null if user report
        'reportedUser': data['reportedUser'], // null if post report
        'reportedBy': data['reportedBy'],
        'reason': data['reason'],
        'timestamp': data['reportedAt'],
      };
    }).toList();
  }

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '';
    final d = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${d.month}/${d.day}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 218, 218, 218),
      appBar: AppBar(
        title: const Text("Reports"),
        elevation: 1,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _currentAdmin == null
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag_outlined,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('No reports found',
                            style: theme.textTheme.bodyMedium!
                                .copyWith(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                final reports = snapshot.data!;

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final r = reports[i];
                      final isUserReport = r['reportedUser'] != null;

                      return Material(
                        color: Colors.white,
                        elevation: 1,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            if (isUserReport) {
                              // Navigate to user profile
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfile2(
                                      username: r['reportedUser']!),
                                ),
                              );
                            } else if (r['postId'] != null) {
                              // Navigate to TapNotifPage with postId & admin username
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TapNotifPage(
                                    postId: r['postId']!,
                                    currentUser: _currentAdmin!,
                                  ),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(Icons.flag, color: Colors.red),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Reported by ${r['reportedBy']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 4),
                                      if (isUserReport)
                                        Text(
                                          'Reported User: ${r['reportedUser']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            height: 1.4,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Post ID: ${r['postId']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            height: 1.4,
                                          ),
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Reason: ${r['reason']}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatDate(r['timestamp']),
                                        style: theme.textTheme.bodyMedium!.copyWith(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                if (!isUserReport)
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
