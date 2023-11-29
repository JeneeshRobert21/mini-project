// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:audiobooktest/custom_play.dart';
import 'package:audiobooktest/mybooks.dart';
import 'package:audiobooktest/mybooks_customplayer.dart';
import 'package:audiobooktest/mybooks_play.dart';
import 'package:audiobooktest/play.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;

class MyBooksPagesList extends StatefulWidget {
  Book book;
  // final String insuranceID;
  MyBooksPagesList({super.key, required this.book});

  @override
  State<MyBooksPagesList> createState() => _MyBooksPagesListState();
}

class _MyBooksPagesListState extends State<MyBooksPagesList> {
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
    // final documentSnapshot =
    //     await _firestore.collection('insurances').doc(widget.insuranceID).get();
    // for (var x in documentSnapshot.data()!['interested']) {
    //   if (x != null) {
    //     participantIDs.add(x);
    //   }
    // }
    participantIDs = List.generate(document.pages.count, (index) => index + 1);
  }

  Future<List<Map<String, dynamic>>> fetchNames(int index) async {
    print('fetching names... of $index in outer loop.');
    List<Map<String, dynamic>> names = [];
    final docSnapshot = await FirebaseFirestore.instance
        .collection('store')
        .doc(widget.book.bookId)
        .collection('voices')
        .doc(index.toString())
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
      // final names = docSnapshot.docs.map((doc) => doc['name'] as String).toList();
      return names;
    } else {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    participantIDs = [];
    return FutureBuilder(
      future: getParticipantIDs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
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
          body:
              // ExpansionPanelList(
              //   children: [
              //     ExpansionPanel(
              //         headerBuilder: (context, isExpanded) {
              //           return Text('Heading');
              //         },
              //         body: Text('Open body'),
              //         isExpanded: _isOpen[0]),
              //   ],
              //   expansionCallback: (panelIndex, isExpanded) => setState(() {
              //     _isOpen[i] = !_isOpen[i];
              //   }),
              // )

              ListView.builder(
            scrollDirection: Axis.vertical,
            itemCount: participantIDs.length,
            itemBuilder: (BuildContext context, int pageIndex) {
              return Container(
                width: MediaQuery.of(context).size.width,
                child: ExpansionTile(
                  title: Container(
                    height: 80,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 228, 228, 228),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                        backgroundColor:
                                            Color.fromARGB(255, 224, 223, 223),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        'Page $pageIndex',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 200,
                                      child: Text(
                                        '$pageIndex out of ${participantIDs.length}',
                                        style: const TextStyle(fontSize: 12),
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
                  trailing: Container(
                    width: 0,
                  ),
                  children: [
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: fetchNames(pageIndex),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
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

                          // Document exists, display names in a ListView.builder
                          return SizedBox(
                            height: 150,
                            child: ListView.builder(
                              itemCount: names.length + 1,
                              itemBuilder: (BuildContext context, int index) {
                                if (index == names.length) {
                                  print('index is $index');
                                  print('default ');
                                  print('page number is $pageIndex');
                                  return ListTile(
                                    title: Text('Default voice'),
                                    trailing: IconButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => MyBooksPlayer(
                                              pageNumber: pageIndex,
                                              book: widget.book,
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.play_arrow),
                                    ),
                                  );
                                } else {
                                  print('index is $index');
                                  print('accessing ');
                                  print(names[index]);
                                  return ListTile(
                                    title: Text(names[index]['email']),
                                    trailing: IconButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => MyBooksCustomPlayer(
                                              voiceIndex: index,
                                              pageNumber: pageIndex,
                                              book: widget.book,
                                              voiceUrl: names[index]
                                                  ['voiceUrl'],
                                            ),
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.play_arrow),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
