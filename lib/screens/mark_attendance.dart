import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class MarkAttendance extends StatefulWidget {
  final String subject;
  final String labName;

  const MarkAttendance({super.key, required this.subject, required this.labName});

  @override
  State<MarkAttendance> createState() => _MarkAttendanceState();
}

class _MarkAttendanceState extends State<MarkAttendance> {
  bool _isPresent = false;
  bool _isSaving = false;
  DateTime selectedDate = DateTime.now();

  Future<void> _saveAttendance() async {
    setState(() => _isSaving = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final String userId = authService.currentUser!.uid;
    final String dateKey = '${selectedDate.year}-${selectedDate.month}-${selectedDate.day}';

    try {
      final docRef = FirebaseFirestore.instance.collection('attendance').doc(userId);

      await docRef.set({
        widget.subject: {
          widget.labName: {
            dateKey: _isPresent
          }
        }
      }, SetOptions(merge: true));

      if (mounted) {
        // Show success popup
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(_isPresent ? Icons.check_circle : Icons.cancel,
                    color: _isPresent ? Colors.green : Colors.red),
                const SizedBox(width: 10),
                Text(_isPresent ? 'Attendance Marked!' : 'Marked as Absent'),
              ],
            ),
            content: Text(
              '${widget.subject}\n${widget.labName}\n\n'
                  'Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}\n'
                  'Status: ${_isPresent ? "✅ PRESENT" : "❌ ABSENT"}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close popup
                  Navigator.pop(context, true); // Return to dashboard
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.labName} - ${widget.subject}'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    Icon(Icons.edit_calendar, size: 50, color: Colors.blue.shade900),
                    const SizedBox(height: 20),
                    Text(
                      widget.subject,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.labName,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 30),

                    // Date Selector
                    GestureDetector(
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null && picked != selectedDate) {
                          setState(() => selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('📅 Select Date', style: TextStyle(fontSize: 16)),
                            Text(
                              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Present/Absent Switch
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _isPresent ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _isPresent ? Colors.green : Colors.red, width: 2),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _isPresent ? '✅ PRESENT' : '❌ ABSENT',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Switch(
                            value: _isPresent,
                            onChanged: (val) {
                              setState(() => _isPresent = val);
                            },
                            activeColor: Colors.green,
                            inactiveThumbColor: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveAttendance,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('SUBMIT ATTENDANCE', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}