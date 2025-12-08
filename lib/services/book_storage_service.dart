import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/downloaded_book.dart';

class BookStorageService {
  static const String _key = 'downloaded_books';

  Future<List<DownloadedBook>> getBooks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? booksJson = prefs.getString(_key);
    if (booksJson == null) {
      return [];
    }
    final List<dynamic> decoded = jsonDecode(booksJson);
    return decoded.map((e) => DownloadedBook.fromJson(e)).toList();
  }

  Future<void> addBook(DownloadedBook book) async {
    final books = await getBooks();
    // Remove if already exists (update)
    books.removeWhere((b) => b.id == book.id);
    books.add(book);
    await _saveBooks(books);
  }

  Future<void> removeBook(String id) async {
    final books = await getBooks();
    books.removeWhere((b) => b.id == id);
    await _saveBooks(books);
  }

  Future<bool> isBookDownloaded(String id) async {
    final books = await getBooks();
    return books.any((b) => b.id == id);
  }

  Future<DownloadedBook?> getBook(String id) async {
    final books = await getBooks();
    try {
      return books.firstWhere((b) => b.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveBooks(List<DownloadedBook> books) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(books.map((b) => b.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
