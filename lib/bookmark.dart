import 'package:cloud_firestore/cloud_firestore.dart';

class BookmarksService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;
  final String bookId;

  BookmarksService({required this.userId, required this.bookId});

  void setPageNumber(int pageNumber) async {
    print(userId);
    print(bookId);

    final userDocRef = _firestore.collection('bookmarks').doc(userId);
    await userDocRef.set({'set': 1});
    final bookmarksColRef = userDocRef.collection('bookmarks');
    final bookDocRef = bookmarksColRef.doc(bookId);

    await bookDocRef.set({'pageNumber': pageNumber});
  }

  void incrementPageNumber() async {
    final userDocRef = _firestore.collection('bookmarks').doc(userId);
    final bookmarksColRef = userDocRef.collection('bookmarks');
    final bookDocRef = bookmarksColRef.doc(bookId);

    final docSnapshot = await bookDocRef.get();
    final currentPageNumber = docSnapshot.get('pageNumber') ?? 0;
    final newPageNumber = currentPageNumber + 1;

    await bookDocRef.update({'pageNumber': newPageNumber});
  }
}
