import 'package:flutter/material.dart';
import 'db_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> tags = [];

  @override
  void initState() {
    super.initState();
    loadTags();
  }

  Future<void> loadTags() async {
    final data = await DBHelper.getTags();
    setState(() {
      tags = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan History")),
      body:
          tags.isEmpty
              ? const Center(child: Text("No Data"))
              : ListView.builder(
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return Card(
                    child: ListTile(
                      title: Text(tag['tagId']),
                      subtitle: Text(tag['data']),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await DBHelper.deleteTag(tag['id']);
                          loadTags();
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
