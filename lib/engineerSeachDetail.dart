import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/common/constData.dart';
import 'dart:async';


class EngineerSeachDetailPage extends StatefulWidget {
  const EngineerSeachDetailPage({super.key});

  @override
  State<EngineerSeachDetailPage> createState() => _EngineerSeachDetailPageState();
}

class _EngineerSeachDetailPageState extends State<EngineerSeachDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.lime.shade700,
          title: Row(
            children: [
              Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Icon(Icons.article,color: Colors.white,)),
              const Text(constData.engineerDetail,style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      body: const Center(
    ));
  }
}
