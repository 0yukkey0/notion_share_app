import 'dart:async';

import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:notion_share_app/notion_client.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page add'),
    );
  }
}

class NotionEntity {
  String? title;
  String? url;
  List<String>? tags;

  NotionEntity({this.title, this.url, this.tags});
}

class Tag {
  final int id;
  final String name;

  Tag({
    required this.id,
    required this.name,
  });
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static List<Tag> _tags = [
    Tag(id: 1, name: "仕事"),
    Tag(id: 2, name: "趣味"),
    Tag(id: 3, name: "開発"),
    Tag(id: 4, name: "flutter"),
    Tag(id: 5, name: "ネタ"),
  ];
  final _formKey = GlobalKey<FormState>();
  final _items =
      _tags.map((animal) => MultiSelectItem<Tag>(animal, animal.name)).toList();
  List<Tag> _selectedTags = [];

  NotionEntity _entity = NotionEntity();

  late StreamSubscription _intentDataStreamSubscription;

  final TextEditingController _text_controller = TextEditingController();
  final TextEditingController _url_controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStreamAsUri().listen((Uri value) {
      setState(() async {
        String url = value.toString();
        var data = await MetadataFetch.extract(url); // returns a Metadata object
        _text_controller.text =  data?.title ?? "";
        _url_controller.text = url;
      });
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      setState(() {
        _url_controller.text = value ?? "";
      });
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      controller: _text_controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "タイトル",
                      ),
                      onSaved: (title) {
                        _entity.title = title;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                        controller: _url_controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "URL",
                        ),
                        onSaved: (url) {
                          _entity.url = url;
                        }),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        labelText: 'タグ',
                      ),
                      child: MultiSelectBottomSheetField<Tag?>(
                        initialChildSize: 0.4,
                        listType: MultiSelectListType.CHIP,
                        searchable: true,
                        buttonText: Text("select tags"),
                        title: Text("Tags"),
                        items: _items,
                        onConfirm: (values) {
                          _selectedTags = values.cast();
                        },
                        onSaved: (values) {
                          _entity.tags = values
                              ?.map((e) => e?.name)
                              .cast<String>()
                              .toList();
                        },
                        chipDisplay: MultiSelectChipDisplay(
                          onTap: (value) {
                            setState(() {
                              _selectedTags.remove(value);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    child: Text('Save'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    onPressed: () {
                      this._formKey.currentState?.save();
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: Column(
                              children: [
                                Text(_entity.title!),
                                Text(_entity.url!),
                                Text(_entity.tags?.first ?? ""),
                              ],
                            ),
                          );
                        },
                      );
                      NotionClient.createDatabasePage(_entity.title!,_entity.tags!,_entity.url!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
