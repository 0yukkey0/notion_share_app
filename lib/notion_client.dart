import 'dart:convert';
import 'package:http/http.dart';

class NotionApiParms {}

class NotionClient {
  static const notionAccessToken =
      String.fromEnvironment('NOTION_ACCESS_TOKEN');
  static const databaseId = String.fromEnvironment('NOTION_DATABASE_ID');

  static void createDatabasePage(
      String title, List<String> tags, String url) async {
    const baseUrl = "https://api.notion.com/v1/pages";

    List<Map<String, String>> tagsParams =
        tags.map((e) => Map.of({"name": e})).toList();

    Map<String, String> headers = {
      'Authorization': 'Bearer ' + notionAccessToken,
      'Notion-Version': '2021-05-13',
      'Content-Type': 'application/json',
    };
    String body = json.encode({
      'parent': {
        'database_id': databaseId,
      },
      'properties': {
        '名前': {
          'title': [
            {
              'text': {'content': title}
            }
          ]
        },
        'タグ': {"multi_select": tagsParams},
        'URL': {'url': url}
      }
    });

    print(body);
    Response resp = await post(Uri.parse(baseUrl), headers: headers, body: body);
    print(resp.statusCode);
  }
}
