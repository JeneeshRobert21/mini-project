// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, prefer_const_literals_to_create_immutables

import 'dart:io';

import 'package:audiobooktest/details_page.dart';
import 'package:audiobooktest/firebase/google_signin.dart';
import 'package:audiobooktest/mybooks_details.dart';
import 'package:audiobooktest/pdf_view.dart';
import 'package:boxicons/boxicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'firebase/user_provider.dart';

class Book {
  final String title;
  final String pdfUrl;
  final String coverUrl;
  final String bookId;
  final String genre;

  Book({
    required this.title,
    required this.pdfUrl,
    required this.coverUrl,
    required this.bookId,
    required this.genre,
  });
}

class BookGrid extends StatefulWidget {
  final String userEmail;

  BookGrid({required this.userEmail});

  @override
  State<BookGrid> createState() => _BookGridState();
}

class _BookGridState extends State<BookGrid> {
  bool _isUploading = false;

  TextEditingController _fileNameController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? title;

  String? genreR;

  final List<String> booksGenre = [
    'All',
    'Fiction',
    'Nature',
    'Romance',
    'Adventure',
    'Psychology',
  ];

  void uploadFileAndStoreUrl(File file, String fileName, String email) async {
    Reference storageReference =
        FirebaseStorage.instance.ref().child('pdfs/$fileName.pdf');
    UploadTask uploadTask = storageReference.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    Map<String, dynamic> pdfData = {
      'name': fileName,
      'url': downloadUrl,
    };

    await FirebaseFirestore.instance.collection('users').doc(email).set({
      'pdf': pdfData,
    }, SetOptions(merge: true));
  }

  Future<List<Book>> fetchBooks(String userEmail) async {
    List<Book> books = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users/$userEmail/books')
        .get();
    snapshot.docs.forEach((doc) {
      books.add(
        Book(
          title: doc.get('title'),
          pdfUrl: doc.get('url'),
          coverUrl: doc.get('cover'),
          bookId: doc.get('bookid'),
          genre: doc.get('genre'),
        ),
      );
    });
    return books;
  }

  String selected = "All";

  @override
  Widget build(BuildContext context) {
    final data = FirebaseAuth.instance.currentUser!;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Books'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Wrap(
              spacing: 6.0,
              children: booksGenre.map((genre) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selected = genre;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Chip(
                      backgroundColor: selected == genre
                          ? Color(0xFFACBCFF)
                          : Color.fromARGB(255, 220, 242, 253),
                      label: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          genre,
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Expanded(
              child: FutureBuilder<List<Book>>(
                future: fetchBooks(data.email!),
                builder:
                    (BuildContext context, AsyncSnapshot<List<Book>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print(snapshot.error.toString());
                    return Center(child: Text('Error loading books.'));
                  } else {
                    List<Book> books = snapshot.data!;

                    List<Book> filteredBooks = books
                        .where((book) =>
                            book.genre.toLowerCase() ==
                                selected.toLowerCase() ||
                            selected == 'All')
                        .toList();

                    return GridView.builder(
                        itemCount: filteredBooks.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          Book book = books[index];
                          return Stack(
                            children: [
                              Positioned(
                                top: 100,
                                left: 10,
                                child: Container(
                                  width: width * 0.45,
                                  height: height * 0.2,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Color(0xFFACBCFF),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromARGB(
                                              255, 188, 209, 219),
                                          spreadRadius: 1,
                                          blurRadius: 2,
                                          offset: Offset(0, 2),
                                        )
                                      ]),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                        child: Container(
                                      width: MediaQuery.of(context).size.width /
                                          2 /
                                          2,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.network(
                                          book.coverUrl,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )),
                                    SizedBox(height: 10),
                                    Text(
                                      book.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        // color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(),
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    MyBooksDetailsPage(
                                                  book: books[index],
                                                ),
                                              ),
                                            );
                                          },
                                          child: Center(
                                            child: Icon(
                                                CupertinoIcons.right_chevron),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: CircleBorder(),
                                          ),
                                          onPressed: () async {
                                            CollectionReference globalRef =
                                                FirebaseFirestore.instance
                                                    .collection('store');
                                            DocumentSnapshot snapshot =
                                                await globalRef
                                                    .doc(book.bookId)
                                                    .get();

                                            if (snapshot.exists) {
                                              // Document already exists, show snackbar
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "You have already published this book."),
                                                ),
                                              );
                                            } else {
                                              // Document doesn't exist, add it to the collection
                                              globalRef.doc(book.bookId).set({
                                                'title': book.title,
                                                'url': book.pdfUrl,
                                                'bookid': book.bookId,
                                                'userid': widget.userEmail,
                                                'cover': book.coverUrl,
                                                'genre': book.genre,
                                              });

                                              // Show success message
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      "Book shared to store successfully."),
                                                ),
                                              );
                                            }
                                          },
                                          child: Center(
                                            child: Icon(Boxicons.bx_store),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ],
                          );
                          return Container(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                    child: Container(
                                  width:
                                      MediaQuery.of(context).size.width / 2 / 2,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey[300],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      book.coverUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )),
                                SizedBox(height: 10),
                                Text(
                                  book.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => ReadPdf(
                                              url: book.pdfUrl,
                                              bookId: book.bookId,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('Read'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        String bookID = Uuid().v4();

                                        CollectionReference globalRef =
                                            FirebaseFirestore.instance
                                                .collection('store');
                                        globalRef.doc(bookID).set({
                                          'title': book.title,
                                          'url': book.pdfUrl,
                                          'bookid': bookID,
                                          'userid': widget.userEmail,
                                          'cover': book.coverUrl,
                                        });

                                        // Show success message
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Book shared to store successfully.",
                                            ),
                                          ),
                                        );
                                      },
                                      child: Text('Publish'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        });
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFACBCFF),
        onPressed: () async {
          title = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Enter book title"),
                content: TextField(
                  controller: _fileNameController,
                  decoration: InputDecoration(
                    hintText: "Title",
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text("CANCEL"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      title = _fileNameController.text;
                      Navigator.pop(context, title);
                    },
                  ),
                ],
              );
            },
          );

          if (title == null || title == "") {
            // Book title is required
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Please enter book title."),
              ),
            );
            return;
          }

          //
          //genre
          genreR = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Choose Genre"),
                content: Wrap(
                  spacing: 6.0,
                  children: booksGenre.map((genre) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context, genre);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Chip(
                          backgroundColor: Color.fromARGB(255, 220, 242, 253),
                          label: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              genre,
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text("CANCEL"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.pop(context, title);
                    },
                  ),
                ],
              );
            },
          );
          //

          // Select PDF file
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf'],
          );

          if (result == null) {
            return;
          }

          File file = File(result.files[0].path!);

          // Upload PDF file to Firebase Storage

          final reference = FirebaseStorage.instance.ref().child(
              "pdfs/${widget.userEmail}/${_fileNameController.text}.pdf");
          final task = reference.putFile(file);
          print("pdfs/${widget.userEmail}/${_fileNameController.text}.pdf");

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Uploading..."),
                content: StreamBuilder<TaskSnapshot>(
                  stream: task.snapshotEvents,
                  builder: (context, snapshot) {
                    var progress = 0.0;
                    if (snapshot.hasData) {
                      progress = snapshot.data!.bytesTransferred /
                          snapshot.data!.totalBytes;
                    }
                    return LinearProgressIndicator(value: progress);
                  },
                ),
              );
            },
          );

          // Wait for upload to complete
          await task.whenComplete(() => Navigator.pop(context));

          // Get download URL of uploaded file
          final pdfUrl = await reference.getDownloadURL();
          print("pdfUrl");
          print(pdfUrl);

//pdf cover
// Select PDF file
          final resultI = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png'],
          );

          if (resultI == null) {
            return;
          }

          File fileI = File(resultI.files[0].path!);

          // Upload PDF file to Firebase Storage

          final referenceI = FirebaseStorage.instance.ref().child(
              "images/${widget.userEmail}/${_fileNameController.text}cover.image");
          final taskI = referenceI.putFile(fileI);
          print('img');
          print(
              "images/${widget.userEmail}/${_fileNameController.text}cover.image");

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Uploading cover image..."),
                content: StreamBuilder<TaskSnapshot>(
                  stream: taskI.snapshotEvents,
                  builder: (context, snapshot) {
                    var progress = 0.0;
                    if (snapshot.hasData) {
                      progress = snapshot.data!.bytesTransferred /
                          snapshot.data!.totalBytes;
                    }
                    return LinearProgressIndicator(value: progress);
                  },
                ),
              );
            },
          );

          await taskI.whenComplete(() => Navigator.pop(context));

          final pdfUrlI = await referenceI.getDownloadURL();
          String bookID = Uuid().v4();
          CollectionReference booksRef = FirebaseFirestore.instance
              .collection('users/${widget.userEmail}/books');
          booksRef.doc(bookID).set({
            'title': title,
            'url': pdfUrl,
            'bookid': bookID,
            'cover': pdfUrlI,
            'genre': genreR,
          });

          DocumentReference emailRef = FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userEmail);
          emailRef.set({
            'set': 1,
          }, SetOptions(merge: true));

          CollectionReference globalRef =
              FirebaseFirestore.instance.collection('books');
          String genreFiltered = genreR!.toLowerCase();
          globalRef.doc(bookID).set({
            'title': title,
            'url': pdfUrl,
            'bookid': bookID,
            'cover': pdfUrlI,
            'genre': genreFiltered,
          });

          Navigator.popUntil(context, (route) => route.isFirst);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("PDF uploaded successfully.✅"),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
