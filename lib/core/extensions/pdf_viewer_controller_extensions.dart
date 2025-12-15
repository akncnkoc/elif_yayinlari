import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

extension PdfViewerControllerExtensions on PdfViewerController {
  void nextPage({Duration? duration, Curve? curve}) {
    if (isReady && pageNumber != null) {
      if (pageNumber! < pageCount) {
        goToPage(pageNumber: pageNumber! + 1);
      }
    }
  }

  void previousPage({Duration? duration, Curve? curve}) {
    if (isReady && pageNumber != null && pageNumber! > 1) {
      goToPage(pageNumber: pageNumber! - 1);
    }
  }

  void jumpToPage(int page) {
    if (isReady) {
      goToPage(pageNumber: page);
    }
  }

  void animateToPage(int page, {Duration? duration, Curve? curve}) {
    jumpToPage(page);
  }

  int? get pagesCount {
    return pageCount;
  }

  int? get page {
    return pageNumber;
  }

  ValueNotifier<int?> createPageNotifier() {
    final notifier = ValueNotifier<int?>(pageNumber);

    void listener() {
      if (notifier.value != pageNumber) {
        notifier.value = pageNumber;
      }
    }

    addListener(listener);

    return notifier;
  }
}
