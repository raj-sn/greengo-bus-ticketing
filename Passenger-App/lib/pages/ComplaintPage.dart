import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Send complaint to Firestore
  void _sendComplaint() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final timestamp = Timestamp.now();

    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final formattedTime = DateFormat('HH:mm:ss').format(DateTime.now());

    // Complaint document ID = username + timestamp
    final docId = "${user?.displayName ?? 'User'}_${DateTime.now().millisecondsSinceEpoch}";

    await FirebaseFirestore.instance.collection('complaints').doc(docId).set({
      'username': user?.displayName ?? 'Anonymous',
      'message': message,
      'date': formattedDate,
      'time': formattedTime,
      'timestamp': timestamp,
    });

    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complaints',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('complaints')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                final complaints = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    return ListTile(
                      leading: Icon(Icons.person, color: Colors.green),
                      title: Text(
                        complaint['username'],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(complaint['message']),
                      trailing: Text(
                        '${complaint['date']} ${complaint['time']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your complaint...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.green),
                  onPressed: _sendComplaint,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
