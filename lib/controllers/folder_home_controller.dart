import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../google_drive/google_drive_service.dart';
import '../google_drive/models.dart' as gdrive;
import '../models/downloaded_book.dart';
import '../models/app_models.dart';
import '../services/book_storage_service.dart';

class FolderHomeController extends ChangeNotifier {
  final BookStorageService _bookStorageService = BookStorageService();
  GoogleDriveService? googleDriveService;

  // Google Drive State
  List<gdrive.DriveItem> driveItems = [];
  List<BreadcrumbItem> driveBreadcrumbs = [
    BreadcrumbItem(
      name: 'Ana Klasör',
      path: '1U8mbCEY2JzdDngZxL7RyxID5eh8MW2yR',
    ),
  ];
  String? currentDriveFolderId;
  bool isDriveLoading = false;

  // Download State
  List<DownloadedBook> downloadedBooks = [];
  Map<String, double> downloadProgress = {};
  Set<String> downloadingBooks = {};
  Map<String, bool> downloadCancelFlags = {};
  List<gdrive.DriveItem> downloadQueue = [];
  static const int _maxConcurrentDownloads = 2;

  // Temporary UI Callbacks (to show Snackbars/Errors from controller)
  Function(String)? onError;
  Function(String)? onSuccess;

  Future<void> loadDownloadedBooks() async {
    downloadedBooks = await _bookStorageService.getBooks();
    notifyListeners();
  }

  void setGoogleDriveService(GoogleDriveService? service) {
    googleDriveService = service;
    notifyListeners();
  }

  // Google Drive Navigation
  Future<void> loadGoogleDriveFolder(String? folderId) async {
    if (googleDriveService == null) return;

    isDriveLoading = true;
    currentDriveFolderId = folderId;
    notifyListeners();

    try {
      // 1. Load files
      final items = await googleDriveService!.listFiles(folderId: folderId);

      // 2. Load breadcrumbs logic (if available in service, otherwise manual)
      // Assuming service has getBreadcrumbs or we manage it manually.
      // In FolderHomePage it was likely managed manually or via service.
      // Let's assume we fetch breadcrumbs relative to root.
      // For now, let's keep it simple: if folderId is null, reset breadcrumbs.
      // If folderId is not null, we might need to fetch folder metadata to get name.

      // In original code:
      // final files = await googleDriveService!.listDriveFiles(folderId);
      // driveItems = files;
      // ... breadcrumb logic ...

      driveItems = items;

      // Breadcrumb updates - simplified for now, as full recursion needs more context.
      // If we are at root
      if (folderId == null || folderId == '1U8mbCEY2JzdDngZxL7RyxID5eh8MW2yR') {
        driveBreadcrumbs = [
          BreadcrumbItem(
            name: 'Ana Klasör',
            path: '1U8mbCEY2JzdDngZxL7RyxID5eh8MW2yR',
          ),
        ];
      }

      notifyListeners();
    } catch (e) {
      onError?.call('Google Drive yüklenirken hata: $e');
    } finally {
      isDriveLoading = false;
      notifyListeners();
    }
  }

  void navigateToDriveFolder(gdrive.DriveItem folder) {
    if (folder.mimeType == 'application/vnd.google-apps.folder') {
      // Add to breadcrumbs
      driveBreadcrumbs.add(BreadcrumbItem(name: folder.name, path: folder.id));
      loadGoogleDriveFolder(folder.id);
    }
  }

  void navigateToDriveBreadcrumb(BreadcrumbItem item) {
    // Find index and remove after
    final index = driveBreadcrumbs.indexOf(item);
    if (index != -1 && index < driveBreadcrumbs.length - 1) {
      driveBreadcrumbs = driveBreadcrumbs.sublist(0, index + 1);
      loadGoogleDriveFolder(item.path);
    } else if (index == -1) {
      // Root case
      driveBreadcrumbs = [item];
      loadGoogleDriveFolder(item.path);
    } else {
      // Already there, just reload
      loadGoogleDriveFolder(item.path);
    }
  }

  // Download Logic
  void startDownloadOrQueue(gdrive.DriveItem item) {
    // Check if already in queue
    if (downloadQueue.any((i) => i.id == item.id)) {
      onError?.call('Bu kitap zaten kuyrukta.');
      return;
    }

    // If max concurrent downloads reached, add to queue
    if (downloadingBooks.length >= _maxConcurrentDownloads) {
      downloadQueue.add(item);
      notifyListeners();
      onSuccess?.call('${item.name} indirme kuyruğuna eklendi');
    } else {
      _downloadBook(item);
    }
  }

  void processQueue() {
    if (downloadQueue.isNotEmpty &&
        downloadingBooks.length < _maxConcurrentDownloads) {
      final nextItem = downloadQueue.removeAt(0);
      _downloadBook(nextItem);
    }
  }

  void removeFromQueue(String bookId) {
    downloadQueue.removeWhere((item) => item.id == bookId);
    notifyListeners();
  }

  void cancelDownload(String bookId) {
    downloadCancelFlags[bookId] = true;
    downloadingBooks.remove(bookId);
    downloadProgress.remove(bookId);
    notifyListeners();

    onSuccess?.call('İndirme iptal ediliyor...');
    processQueue();
  }

  Future<void> _downloadBook(gdrive.DriveItem item) async {
    if (googleDriveService == null) return;

    // Check if already downloaded
    if (downloadedBooks.any((b) => b.id == item.id)) {
      onError?.call('Bu kitap zaten indirilmiş.');
      processQueue();
      return;
    }

    // Check if already downloading
    if (downloadingBooks.contains(item.id)) {
      onError?.call('Bu kitap zaten indiriliyor.');
      return;
    }

    // Mark as downloading
    downloadingBooks.add(item.id);
    downloadProgress[item.id] = 0.0;
    downloadCancelFlags[item.id] = false;
    notifyListeners();

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final booksDir = Directory('${appDir.path}/books');
      if (!await booksDir.exists()) {
        await booksDir.create(recursive: true);
      }

      final fileName = item.name;
      // Download to temp first with progress callback
      final tempFile = await googleDriveService!.downloadFile(
        item.id,
        fileName,
        fileSize: item.size,
        onProgress: (progress) {
          // Check for cancellation
          if (downloadCancelFlags[item.id] == true) {
            throw Exception('Download cancelled by user');
          }

          downloadProgress[item.id] = progress;
          // Notify listeners occasionally or throttling?
          // Constant notifyListeners might be heavy if high freq.
          // For now, direct notify. Use throttling if UI stutters.
          notifyListeners();
        },
      );

      // Check if cancelled before moving file
      if (downloadCancelFlags[item.id] == true) {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        return;
      }

      // Move file to permanent location
      final newPath = '${booksDir.path}/$fileName';
      await tempFile.copy(newPath);
      await tempFile.delete(); // Delete temp file

      final downloadedBook = DownloadedBook(
        id: item.id,
        name: item.name,
        localPath: newPath,
        size: item.size ?? 0,
        downloadedAt: DateTime.now(),
      );

      await _bookStorageService.addBook(downloadedBook);
      await loadDownloadedBooks();

      onSuccess?.call('Kitap başarıyla indirildi: ${item.name}');
    } catch (e) {
      if (e.toString().contains('cancelled')) {
        onSuccess?.call('İndirme iptal edildi');
      } else {
        onError?.call('İndirme hatası: $e');
      }
    } finally {
      // Remove from downloading state
      downloadingBooks.remove(item.id);
      downloadProgress.remove(item.id);
      downloadCancelFlags.remove(item.id);
      notifyListeners();

      // Process next item in queue
      processQueue();
    }
  }

  // Dispose logic if needed
}
