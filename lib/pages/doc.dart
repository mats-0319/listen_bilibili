import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:markdown_widget/markdown_widget.dart';

enum DocItemE {
  manual(name: "使用手册", path: "doc/manual.md"),
  tech(name: "技术文档", path: "doc/tech.md");

  const DocItemE({required this.name, required this.path});

  final String name;
  final String path;
}

class DocPage extends StatelessWidget {
  const DocPage({super.key, required this.doc});

  final DocItemE doc;

  Widget content() => FutureBuilder(
    future: rootBundle.loadString(doc.path),
    builder: (BuildContext context, AsyncSnapshot snapshot) {
      if (snapshot.hasData) {
        return MarkdownWidget(data: snapshot.data as String);
      } else if (snapshot.hasError) {
        return Center(child: Text("加载失败：${snapshot.error.toString()}"));
      } else {
        return Center(child: Text("加载中......"));
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subpageAppBar(context, doc.name),
      body: Padding(padding: EdgeInsets.all(40), child: content()),
    );
  }
}
