// ignore_for_file: prefer_const_constructors

import 'dart:io';

import 'package:audiobooktest/details_page.dart';
import 'package:audiobooktest/pdf_view.dart';
import 'package:boxicons/boxicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';

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

class BookStore extends StatefulWidget {
  final String userEmail;

  BookStore({required this.userEmail});

  @override
  State<BookStore> createState() => _BookStoreState();
}

class _BookStoreState extends State<BookStore> {
  final List<String> booksGenre = [
    'All',
    'Fiction',
    'Nature',
    'Romance',
    'Adventure',
    'Psychology',
  ];

  bool _isUploading = false;

  TextEditingController _fileNameController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  GoogleSignInAccount? _currentAccount;

  String? title;

  Future<List<Book>> fetchBooks() async {
    List<Book> books = [];
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('store').get();
    print(snapshot.docs.length);
    for (int i = 0; i < (snapshot.docs.length); i++) {
      Book? b;
      try {
        b = Book(
          title: snapshot.docs[i].get('title') ?? '',
          pdfUrl: snapshot.docs[i].get('url') ?? '',
          coverUrl: snapshot.docs[i].get('cover') ?? '',
          bookId: snapshot.docs[i].get('bookid') ?? '',
          genre: snapshot.docs[i].get('genre') ?? '',
        );
      } catch (e) {
        print(e.toString());
      }
      if (b != null) {
        print(b);
        books.add(b);
      }
    }

    return books;
  }

  String selected = "All";
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    GoogleSignInAccount? user = _currentAccount;
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: Text('Shop Store')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: CupertinoSearchTextField(
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              borderRadius: BorderRadius.circular(10.0),
              placeholder: 'search genres/title',
            ),
          ),
          Wrap(
            spacing: 6.0,
            children: booksGenre.map((genre) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selected = genre;
                  });
                  print(selected);
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
              future: fetchBooks(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Book>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading books.'));
                } else {
                  List<Book> books = snapshot.data!;

                  List<Book> filteredBooks = books
                      .where((book) =>
                          book.genre.toLowerCase() == selected.toLowerCase() ||
                          selected == 'All')
                      .toList();
                  for (var x in filteredBooks) {
                    print(x.title);
                  }
                  print('--------');

                  List<Book> searchFilteredBooks = filteredBooks
                      .where((book) =>
                          book.title
                              .toString()
                              .toLowerCase()
                              .contains(searchText.toLowerCase()) ||
                          book.genre
                              .toString()
                              .toLowerCase()
                              .contains(searchText.toLowerCase()) ||
                          searchText == '')
                      .toList();
                  for (var x in searchFilteredBooks) {
                    print(x.title);
                  }
                  return GridView.builder(
                    itemCount: searchFilteredBooks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      print("searchText.toLowerCase()");
                      print(searchText.toLowerCase());
                      print("filteredBooks[index].title.toLowerCase()");
                      print(filteredBooks[index].title.toLowerCase());

                      Book book = searchFilteredBooks[index];
                      return Stack(
                        children: [
                          Positioned(
                            top: 70,
                            left: 10,
                            child: Container(
                              width: width * 0.45,
                              height: height * 0.25,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color(0xFFACBCFF),
                              ),
                            ),
                          ),
                          Container(
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
                                            builder: (_) => DetailsPage(
                                              book: searchFilteredBooks[index],
                                            ),
                                          ),
                                        );
                                      },
                                      child: Center(
                                        child:
                                            Icon(CupertinoIcons.right_chevron),
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
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
