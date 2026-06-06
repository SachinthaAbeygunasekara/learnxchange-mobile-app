import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:learnxchange/models/session_model.dart';
import 'package:learnxchange/services/session_service.dart';
import 'package:learnxchange/models/user_model.dart';
import 'package:learnxchange/services/user_service.dart';
import 'package:learnxchange/models/request_model.dart';
import 'package:learnxchange/widgets/rating_dialog.dart';
import 'package:intl/intl.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final sessionService = SessionService();
    final userService = UserService();

    return StreamBuilder<UserModel>(
      stream: userService.getUserData(uid),
      builder: (context, userSnapshot) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('My Sessions', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: StreamBuilder<List<SessionModel>>(
            stream: sessionService.getUserSessions(uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }
              if (snapshot.connectionState == ConnectionState.waiting || !userSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final sessions = snapshot.data!;
              if (sessions.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _SessionCard(
                    session: session, 
                    currentUser: userSnapshot.data!,
                  );
                },
              );
            },
          ),
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No sessions scheduled yet.', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong.\n\n$error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final SessionModel session;
  final UserModel currentUser;
  const _SessionCard({required this.session, required this.currentUser});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _isLoading = false;

  Future<void> _completeAndRate() async {
    setState(() => _isLoading = true);
    try {
      // 1. Mark session as completed
      await SessionService().updateSessionStatus(widget.session.id, SessionStatus.completed);
      
      // 2. Fetch request to check rating status
      final requestSnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.session.requestId)
          .get();
      
      if (!requestSnapshot.exists) return;
      
      final request = RequestModel.fromMap(requestSnapshot.data()!);
      final isSender = widget.currentUser.uid == request.senderId;
      final alreadyRated = isSender ? request.isRatedBySender : request.isRatedByReceiver;

      if (!alreadyRated && mounted) {
        final partnerId = isSender ? request.receiverId : request.senderId;
        final partnerName = isSender ? request.receiverName : request.senderName;

        final rated = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => RatingDialog(
            currentUser: widget.currentUser,
            partnerId: partnerId,
            partnerName: partnerName,
            requestId: request.id,
            isSender: isSender,
          ),
        );

        if (rated == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session completed and rated!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPast = widget.session.scheduledDateTime.isBefore(DateTime.now());
    final statusColor = _getStatusColor(widget.session.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.session.status.name.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              if (isPast && widget.session.status == SessionStatus.scheduled)
                const Icon(Icons.history, color: Colors.grey, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.session.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(widget.session.scheduledDateTime),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                DateFormat('hh:mm a').format(widget.session.scheduledDateTime),
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
          if (widget.session.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.session.notes,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.session.status == SessionStatus.scheduled) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => SessionService().updateSessionStatus(widget.session.id, SessionStatus.cancelled),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _completeAndRate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Complete'),
                  ),
                ),
              ],
              if (widget.session.status == SessionStatus.completed)
                Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('requests').doc(widget.session.requestId).get(),
                    builder: (context, reqSnapshot) {
                      if (!reqSnapshot.hasData) return const SizedBox();
                      final request = RequestModel.fromMap(reqSnapshot.data!.data() as Map<String, dynamic>);
                      final isSender = widget.currentUser.uid == request.senderId;
                      final alreadyRated = isSender ? request.isRatedBySender : request.isRatedByReceiver;

                      if (alreadyRated) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.blue, size: 16),
                              SizedBox(width: 8),
                              Text('Experience Rated', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }

                      return ElevatedButton.icon(
                        onPressed: _completeAndRate,
                        icon: const Icon(Icons.star_rounded),
                        label: const Text('Rate Experience'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled: return const Color(0xFF6366F1);
      case SessionStatus.completed: return Colors.green;
      case SessionStatus.cancelled: return Colors.red;
    }
  }
}
