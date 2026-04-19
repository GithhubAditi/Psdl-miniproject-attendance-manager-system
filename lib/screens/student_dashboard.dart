import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'mark_attendance.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final List<String> subjects = [
    'Deep Learning',
    'Cloud Computing',
    'PSDL',
    'ICS',
    'JFST',
  ];

  // 1 lab per subject
  final Map<String, String> labs = {
    'Deep Learning': 'DL Lab',
    'Cloud Computing': 'Cloud Lab',
    'PSDL': 'PSDL Lab',
    'ICS': 'ICS Lab',
    'JFST': 'JFST Lab',
  };

  double _calculateAttendance(Map<String, dynamic>? data, String subject) {
    if (data == null) return 0.0;

    int total = 0;
    int present = 0;

    if (data.containsKey(subject)) {
      var subjectData = data[subject] as Map<String, dynamic>? ?? {};
      for (var labData in subjectData.values) {
        if (labData is Map<String, dynamic>) {
          total += labData.length;
          present += labData.values.where((v) => v == true).length;
        }
      }
    }

    return total == 0 ? 0.0 : (present / total) * 100;
  }

  double _calculateOverallAttendance(Map<String, dynamic>? data) {
    if (data == null) return 0.0;

    double totalPercentage = 0.0;
    int subjectCount = 0;

    for (String subject in subjects) {
      double percentage = _calculateAttendance(data, subject);
      totalPercentage += percentage;
      subjectCount++;
    }

    return subjectCount == 0 ? 0.0 : totalPercentage / subjectCount;
  }

  void _showAttendanceMessage(BuildContext context, String subject, double percentage, bool isLow) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(isLow ? Icons.warning : Icons.check_circle,
                color: isLow ? Colors.orange : Colors.green, size: 30),
            const SizedBox(width: 10),
            Text(isLow ? '⚠️ Low Attendance!' : '✅ Good Job!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subject: $subject'),
            const SizedBox(height: 10),
            Text(
              'Your attendance: ${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isLow ? Colors.orange : Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isLow
                  ? '⚠️ Below 75%! Please attend more classes.'
                  : '🎉 Keep it up! You\'re above 75%.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .doc(authService.currentUser?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Loading attendance data...'),
                ],
              ),
            );
          }

          Map<String, dynamic>? attendanceData = snapshot.data?.data() as Map<String, dynamic>?;
          double overallPercentage = _calculateOverallAttendance(attendanceData);

          return Column(
            children: [
              // Overall Attendance Card
              Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: overallPercentage >= 75
                        ? [Colors.green.shade400, Colors.green.shade700]
                        : [Colors.orange.shade400, Colors.orange.shade700],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Overall Attendance',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${overallPercentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: overallPercentage / 100,
                      backgroundColor: Colors.white54,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      overallPercentage >= 75
                          ? '✅ Good! Above 75%'
                          : '⚠️ Warning! Below 75%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Subjects List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: subjects.length,
                  itemBuilder: (context, index) {
                    String subject = subjects[index];
                    String labName = labs[subject]!;
                    double percentage = _calculateAttendance(attendanceData, subject);

                    return Card(
                      margin: const EdgeInsets.all(10),
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.book, color: Colors.blue.shade900, size: 30),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    subject,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: percentage >= 75 ? Colors.green.shade100 : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: percentage >= 75 ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                percentage >= 75 ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Icon(Icons.science, color: Colors.purple.shade700, size: 20),
                                const SizedBox(width: 10),
                                Text(labName, style: const TextStyle(fontSize: 14)),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    bool? refreshed = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MarkAttendance(
                                          subject: subject,
                                          labName: labName,
                                        ),
                                      ),
                                    );
                                    if (refreshed == true && mounted) {
                                      setState(() {});
                                    }
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Mark'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade700,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}