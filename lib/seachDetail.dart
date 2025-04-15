import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/common/constData.dart';
import 'dart:async';


class SeachDetailPage extends StatefulWidget {
  const SeachDetailPage({super.key});

  @override
  State<SeachDetailPage> createState() => _SeachDetailPageState();
}

class _SeachDetailPageState extends State<SeachDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreenAccent.shade700,
        title: Row(
          children: [
            Container(
                margin: const EdgeInsets.only(right: 10),
                child: Icon(Icons.filter_list_alt,color: Colors.white,)),
            const Text(constData.engineerSearchDitail,style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: const Center(
    ));
  }
}
