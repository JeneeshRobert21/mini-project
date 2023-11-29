// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:audiobooktest/books_store.dart';
import 'package:audiobooktest/custom_play.dart';
import 'package:audiobooktest/play.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

import 'firebase/user_provider.dart';

class StoreBooksPagesList extends StatefulWidget {
  Book book;
  StoreBooksPagesList({super.key, required this.book});

  @override
  State<StoreBooksPagesList> createState() => _StoreBooksPagesListState();
}

class _StoreBooksPagesListState extends State<StoreBooksPagesList> {
  final ScrollController _scrollController = ScrollController();
  final int targetElementIndex = 20;
  final ctr = ItemScrollController();
  List<dynamic> participantIDs = [];
  Future<List<int>> _fetchDocumentData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load PDF document from $url');
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // List<bool> _isOpen;

  getParticipantIDs() async {
    PdfDocument document =
        PdfDocument(inputBytes: await _fetchDocumentData(widget.book.pdfUrl));
    participantIDs = List.generate(document.pages.count, (index) => index + 1);
  }

  Future<List<Map<String, dynamic>>> fetchNames(int index) async {
    print('fetching names... of $index in outer loop.');
    List<Map<String, dynamic>> names = [];
    final docSnapshot = await FirebaseFirestore.instance
        .collection('store')
        .doc(widget.book.bookId)
        .collection('voices')
        .doc((index + 1).toString())
        .get();

    if (docSnapshot.data() != null) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<dynamic> name = data['voices'];
      for (var x in name) {
        names.add({
          'email': x['userId'],
          'voiceUrl': x['voiceUrl'],
        });
      }
      print(names);
      return names;
    } else {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
  }

  void _scrollToElement(int index) {
    if (_scrollController.hasClients) {
      final double itemExtent = 450;
      final double scrollOffset = itemExtent * index - itemExtent - 2;
      _scrollController.animateTo(
        scrollOffset,
        duration: Duration(seconds: 4),
        curve: Curves.easeInCirc,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future scrollToIten(int n) async {
    ctr.scrollTo(
      index: n,
      duration: Duration(seconds: 3),
    );
  }

  Future<int> _getBookmark(String user, String bookId) async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('bookmarks').doc(user);
      final bookmarkDoc =
          await userRef.collection('bookmarks').doc(bookId).get();
      if (bookmarkDoc.exists && bookmarkDoc.data() != null) {
        final data = bookmarkDoc.data() as Map<String, dynamic>;
        final pageNumber = data['pageNumber'] as int;
        return pageNumber;
      } else {
        return 0;
      }
    } catch (error) {
      print('Error retrieving bookmark: $error');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = FirebaseAuth.instance.currentUser!;

    print('hixxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');

    participantIDs = [];
    return Scaffold(
      body: FutureBuilder(
        future: getParticipantIDs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          // WidgetsBinding.instance.addPostFrameCallback((_) {
          //   _scrollToElement(targetElementIndex);
          // });
          return FutureBuilder<int>(
              future: _getBookmark(userProvider.email!, widget.book.bookId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  final pageNumber = snapshot.data;
                  return Scaffold(
                    floatingActionButton: FloatingActionButton(
                      backgroundColor: Color.fromARGB(255, 108, 76, 158),
                      onPressed: () {
                        scrollToIten(pageNumber!);
                      },
                      child: Icon(Icons.bookmark),
                    ),
                    appBar: AppBar(
                      // backgroundColor: Colors.white,
                      elevation: 0,
                      title: Text(
                        'Pages',
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                      leading: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    body: ScrollablePositionedList.builder(
                      itemScrollController: ctr,
                      scrollDirection: Axis.vertical,
                      itemCount: participantIDs.length,
                      itemBuilder: (BuildContext context, int pageIndex) {
                        return ExpansionTile(
                          trailing: SizedBox.shrink(),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 20.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 4,
                                        color: Color(0xFFBCCEF8),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                    backgroundColor:
                                                        Color.fromARGB(
                                                            255, 224, 223, 223),
                                                    child: Container(
                                                      height: 20,
                                                      width: 20,
                                                      child: SvgPicture.network(
                                                        'https://avatars.dicebear.com/api/identicon/$pageIndex.svg',
                                                      ),
                                                    ))
                                              ],
                                            ),
                                            const SizedBox(
                                              width: 15,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    'Page ${pageIndex + 1}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    '${pageIndex + 1} out of ${participantIDs.length}',
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FutureBuilder<List<Map<String, dynamic>>>(
                                future: fetchNames(pageIndex),
                                builder: (BuildContext context,
                                    AsyncSnapshot<List<Map<String, dynamic>>>
                                        snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return Center(
                                      child: Text('Error: ${snapshot.error}'),
                                    );
                                  } else {
                                    final names = snapshot.data ?? [];
                                    print("names");
                                    print(names);

                                    return SizedBox(
                                      height: 150,
                                      child: ListView.builder(
                                        itemCount: names.length + 1,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          if (index == names.length) {
                                            print('index is $index');
                                            print('default ');
                                            print('page number is $pageIndex');
                                            return ListTile(
                                              title: Text(
                                                'Default voice',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              trailing: IconButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) => Player(
                                                        pageNumber: pageIndex,
                                                        book: widget.book,
                                                        user:
                                                            userProvider.email!,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            );
                                          } else {
                                            print('index is $index');
                                            print('accessing ');
                                            print(names[index]);
                                            return ListTile(
                                              title: Row(
                                                children: [
                                                  Text(
                                                    names[index]['email'],
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  StreamBuilder<
                                                          DocumentSnapshot>(
                                                      stream: FirebaseFirestore
                                                          .instance
                                                          .collection('store')
                                                          .doc(widget
                                                              .book.bookId)
                                                          .collection('voices')
                                                          .doc((pageIndex + 1)
                                                              .toString())
                                                          .snapshots(),
                                                      builder: (BuildContext
                                                              context,
                                                          AsyncSnapshot<
                                                                  DocumentSnapshot>
                                                              snapshot) {
                                                        if (!snapshot.hasData) {
                                                          return CircularProgressIndicator();
                                                        }
                                                        Map<String, dynamic>
                                                            datas = snapshot
                                                                    .data!
                                                                    .data()
                                                                as Map<String,
                                                                    dynamic>;
                                                        print(datas['voices']
                                                            [index]['likes']);
                                                        print(
                                                            "datas['voices'][pageIndex]['voices'][widget.voiceIndex]['likes']");
                                                        int likesCount = datas[
                                                                            'voices']
                                                                        [index]
                                                                    ['likes'] !=
                                                                null
                                                            ? datas['voices']
                                                                        [index]
                                                                    ['likes']
                                                                .length
                                                            : 0;
                                                        bool isLiked = datas[
                                                                            'voices']
                                                                        [index]
                                                                    ['likes'] !=
                                                                null
                                                            ? datas['voices']
                                                                        [index]
                                                                    ['likes']
                                                                .contains(
                                                                    userProvider
                                                                        .email)
                                                            : false;
                                                        return Row(
                                                          children: [
                                                            IconButton(
                                                              onPressed:
                                                                  () async {
                                                                DocumentReference postRef = FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                        'store')
                                                                    .doc(widget
                                                                        .book
                                                                        .bookId)
                                                                    .collection(
                                                                        'voices')
                                                                    .doc((pageIndex +
                                                                            1)
                                                                        .toString());

                                                                DocumentSnapshot
                                                                    postSnapshot =
                                                                    await postRef
                                                                        .get();
                                                                final data = postSnapshot
                                                                        .data()
                                                                    as Map<
                                                                        String,
                                                                        dynamic>;
                                                                List<dynamic>
                                                                    voicesArray =
                                                                    data[
                                                                        'voices'];

                                                                int Sindex =
                                                                    index;
                                                                if (Sindex >=
                                                                        0 &&
                                                                    Sindex <
                                                                        voicesArray
                                                                            .length) {
                                                                  Map<String,
                                                                          dynamic>
                                                                      selectedVoice =
                                                                      voicesArray[
                                                                          Sindex];
                                                                  List<dynamic>
                                                                      likesArray =
                                                                      selectedVoice[
                                                                              'likes'] ??
                                                                          [];

                                                                  String email =
                                                                      userProvider
                                                                          .email!;
                                                                  if (likesArray
                                                                      .contains(
                                                                          email)) {
                                                                    likesArray
                                                                        .remove(
                                                                            email);
                                                                  } else {
                                                                    likesArray.add(
                                                                        email);
                                                                  }

                                                                  selectedVoice[
                                                                          'likes'] =
                                                                      likesArray;
                                                                  voicesArray[
                                                                          Sindex] =
                                                                      selectedVoice;
                                                                  await postRef
                                                                      .update({
                                                                    'voices':
                                                                        voicesArray
                                                                  });
                                                                }
                                                              },
                                                              icon: Icon(
                                                                CupertinoIcons
                                                                    .hand_thumbsup,
                                                                color: isLiked
                                                                    ? Colors
                                                                        .green
                                                                    : Colors
                                                                        .black,
                                                              ),
                                                            ),
                                                            Text('$likesCount')
                                                          ],
                                                        );
                                                      }),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          CustomPlayer(
                                                        voiceIndex: index,
                                                        pageNumber: pageIndex,
                                                        book: widget.book,
                                                        voiceUrl: names[index]
                                                            ['voiceUrl'],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                icon: Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }
              });
        },
      ),
    );
  }
}
