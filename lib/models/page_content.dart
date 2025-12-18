import 'dart:convert';

class PageContent {
  final Map<int, List<PageItem>> pages;

  PageContent({required this.pages});

  factory PageContent.fromJson(Map<String, dynamic> json) {
    final Map<int, List<PageItem>> pages = {};

    if (json.containsKey('pages')) {
      final pagesMap = json['pages'] as Map<String, dynamic>;
      pagesMap.forEach((key, value) {
        final pageNum = int.tryParse(key);
        if (pageNum != null &&
            value is Map<String, dynamic> &&
            value.containsKey('items')) {
          final itemsList = value['items'] as List;
          final items = itemsList
              .map((item) => PageItem.fromJson(item))
              .whereType<PageItem>()
              .toList();
          if (items.isNotEmpty) {
            pages[pageNum] = items;
          }
        }
      });
    }

    return PageContent(pages: pages);
  }

  factory PageContent.fromJsonString(String jsonString) {
    return PageContent.fromJson(json.decode(jsonString));
  }
}

enum PageItemType { link, video, unknown }

abstract class PageItem {
  final String id;
  final PageItemType type;

  PageItem({required this.id, required this.type});

  factory PageItem.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    if (typeStr == 'link') {
      return LinkItem.fromJson(json);
    } else if (typeStr == 'video') {
      return VideoItem.fromJson(json);
    }
    return UnknownItem(id: json['id'] ?? 'unknown', type: PageItemType.unknown);
  }
}

class LinkItem extends PageItem {
  final String url;
  final String title;

  LinkItem({required String id, required this.url, required this.title})
    : super(id: id, type: PageItemType.link);

  factory LinkItem.fromJson(Map<String, dynamic> json) {
    return LinkItem(
      id: json['id'],
      url: json['url'],
      title: json['title'] ?? 'Link',
    );
  }
}

class VideoItem extends PageItem {
  final String filename;
  final String path;

  VideoItem({required String id, required this.filename, required this.path})
    : super(id: id, type: PageItemType.video);

  factory VideoItem.fromJson(Map<String, dynamic> json) {
    return VideoItem(
      id: json['id'],
      filename: json['filename'],
      path: json['path'],
    );
  }
}

class UnknownItem extends PageItem {
  UnknownItem({required String id, required PageItemType type})
    : super(id: id, type: type);
}
