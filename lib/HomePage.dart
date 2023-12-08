import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'model.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Model>> data;

  Future<Iterable> fetchNamesFromAPi() async {
    final response =
        await http.get(Uri.parse("https://jsonplaceholder.typicode.com/users"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      List<String> namesList = [];

      for (var userData in data) {
        String name = userData['name'];
        namesList.add(name);
        // Upload each name to Firestore
        await uploadNamesTOFireBaseCollection([name]);
      }

      return namesList;
      //  return data.map((dynamic item) => item['names'].toString());
    } else {
      throw Exception('Failed to load names');
    }
  }

  Future<void> uploadNamesTOFireBaseCollection(List<String> names) async {
    final CollectionReference namesCollection =
        FirebaseFirestore.instance.collection('names');
    // for (var name in names) {
    await namesCollection.add({'names': names});
    // }
  }

  @override
  void initState() {
    // TODO: implement initState
    fetchNamesFromAPi();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Names from Firebase'),
      ),
      body: StreamBuilder(
          stream: FirebaseFirestore.instance.collection('names').snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              final names = snapshot.data!.docs
                  .map((document) => document['name'].toString())
                  .toList();
              return ListView.builder(
                itemCount: names.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(names[index]),
                ),
              );
            }
          }),
    );
  }
}
