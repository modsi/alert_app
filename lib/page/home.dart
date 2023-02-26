import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'send_alert.dart';
import 'login_screen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = GetStorage();
  NotificationService notificationService = NotificationService();

  final int maxTitleLength = 60;
  TextEditingController _textEditingController =
      TextEditingController(text: "รายการแจ้งเหตุได้รับการตรวจสอบแล้ว");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emergency Accident Alert"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              box.remove('email');
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(title: 'Login UI'),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('alert')
            .where('alertby', isEqualTo: box.read('email'))
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              if (data["is_alert"] == null && data["status"] == 1) {
                notificationService.showNotification(
                  DateTime.now().microsecond,
                  _textEditingController.text,
                  "ประเภทการแจ้งเหตุ : " + data["type"],
                  jsonEncode({
                    "title": _textEditingController.text,
                  }),
                );
                String doc_id = document.id.toString();
                CollectionReference alert =
                    FirebaseFirestore.instance.collection('alert');
                alert.doc(doc_id).update({'is_alert': 1});
              }
              return Card(
                  elevation: 50,
                  shadowColor: Colors.black,
                  color: Colors.white,
                  child: SizedBox(
                      child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("ประเภทการแจ้งเหตุ : " + data["type"],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text("หน่วยงาน : " + data["agency"],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text("สถานที่ : " + data["address"],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text("รายละเอียด : " + data["detail"],
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black)),
                                Text(
                                    "สถานะ : " +
                                        (data["status"] == 0
                                            ? "รอตรวจสอบ"
                                            : "ตรวจสอบแล้ว"),
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black))
                              ]))));
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AlertPage(title: 'Alert UI'),
            ),
          );
        },
      ),
    );
  }
}
