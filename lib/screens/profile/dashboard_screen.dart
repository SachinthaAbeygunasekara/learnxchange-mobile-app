import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/models/session_model.dart';
import 'package:learnxchange/models/request_model.dart';
import 'package:learnxchange/services/user_service.dart';
import 'package:learnxchange/services/session_service.dart';
import 'package:learnxchange/services/request_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userService = UserService();
    final sessionService = SessionService();
    final requestService = RequestService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<UserModel>(
        stream: userService.getUserData(uid),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = userSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCard(user),
                const SizedBox(height: 24),
                const Text(
                  'Learning Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildStatsGrid(uid, sessionService, requestService, user),
                const SizedBox(height: 24),
                const Text(
                  'Skill Inventory',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSkillInventory(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF818CF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.role.toUpperCase(),
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${user.rating.toStringAsFixed(1)} Average Rating',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.analytics_outlined, color: Colors.white, size: 64),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(String uid, SessionService ss, RequestService rs, UserModel user) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StreamBuilder<List<SessionModel>>(
          stream: ss.getUserSessions(uid),
          builder: (context, snapshot) {
            final count = snapshot.data?.where((s) => s.status == SessionStatus.completed).length ?? 0;
            return _buildStatCard('Completed', count.toString(), Icons.check_circle_rounded, Colors.green);
          },
        ),
        StreamBuilder<List<SessionModel>>(
          stream: ss.getUserSessions(uid),
          builder: (context, snapshot) {
            final count = snapshot.data?.where((s) => s.status == SessionStatus.scheduled).length ?? 0;
            return _buildStatCard('Upcoming', count.toString(), Icons.event_rounded, Colors.blue);
          },
        ),
        StreamBuilder<List<RequestModel>>(
          stream: rs.getIncomingRequests(uid),
          builder: (context, snapshot) {
            final count = snapshot.data?.where((r) => r.status == RequestStatus.pending).length ?? 0;
            return _buildStatCard('Pending', count.toString(), Icons.pending_actions_rounded, Colors.orange);
          },
        ),
        _buildStatCard('Reviews', user.ratingCount.toString(), Icons.rate_review_rounded, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSkillInventory(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
      ),
      child: Column(
        children: [
          _buildSkillRow('Skills Offered', user.offeredSkills.length.toString(), const Color(0xFF6366F1)),
          const Divider(height: 32),
          _buildSkillRow('Skills Wanted', user.wantedSkills.length.toString(), const Color(0xFFEC4899)),
        ],
      ),
    );
  }

  Widget _buildSkillRow(String label, String count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        Text(
          count,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}
