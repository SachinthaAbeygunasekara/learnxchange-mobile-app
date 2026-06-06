import 'package:flutter/material.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/models/session_model.dart';
import 'package:learnxchange/models/request_model.dart';
import 'package:learnxchange/models/review_model.dart';
import 'package:learnxchange/services/user_service.dart';
import 'package:learnxchange/services/session_service.dart';
import 'package:learnxchange/services/request_service.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF6366F1),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF6366F1),
            tabs: [
              Tab(text: 'Users', icon: Icon(Icons.people_rounded)),
              Tab(text: 'Sessions', icon: Icon(Icons.event_note_rounded)),
              Tab(text: 'Requests', icon: Icon(Icons.swap_horiz_rounded)),
              Tab(text: 'Reviews', icon: Icon(Icons.rate_review_rounded)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AdminUsersView(),
            AdminSessionsView(),
            AdminRequestsView(),
            AdminReviewsView(),
          ],
        ),
      ),
    );
  }
}

class AdminUsersView extends StatelessWidget {
  const AdminUsersView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: UserService().getAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withAlpha(20),
                  child: Text(user.name[0], style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                ),
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.email} • ${user.role}'),
                trailing: Switch(
                  value: !user.isSuspended,
                  onChanged: (active) async {
                    await UserService().toggleUserSuspension(user.uid, !active);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(active ? 'User reactivated' : 'User suspended'), backgroundColor: active ? Colors.green : Colors.red),
                      );
                    }
                  },
                  activeColor: Colors.green,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminSessionsView extends StatelessWidget {
  const AdminSessionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SessionModel>>(
      stream: SessionService().getAllSessions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final sessions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${DateFormat('MMM d, hh:mm a').format(session.scheduledDateTime)} • ${session.status.name}'),
                trailing: Icon(
                  session.status == SessionStatus.completed ? Icons.check_circle : Icons.pending,
                  color: session.status == SessionStatus.completed ? Colors.green : Colors.orange,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class AdminRequestsView extends StatelessWidget {
  const AdminRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RequestModel>>(
      stream: RequestService().getAllRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${request.senderName} ➔ ${request.receiverName}'),
                subtitle: Text('Exchange: ${request.skillWanted} for ${request.skillOffered}\nStatus: ${request.status.name}'),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}

class AdminReviewsView extends StatelessWidget {
  const AdminReviewsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: UserService().getAllReviews(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Note: Admin must enable Collection Group Index for "reviews" in Firebase Console.\n\nError: ${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final reviews = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.star_rounded, color: Colors.amber),
                title: Text('${review.rating} Stars from ${review.reviewerName}'),
                subtitle: Text(review.comment),
              ),
            );
          },
        );
      },
    );
  }
}
