// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:audiobooktest/pdf_view.dart';
import 'package:audiobooktest/play.dart';
import 'package:audiobooktest/pages.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DetailsPage extends StatefulWidget {
  DetailsPage({super.key, required this.book});
  var book;

  @override
  State<DetailsPage> createState() => _DetailsPageState();
}

class _DetailsPageState extends State<DetailsPage> {
  @override
  Widget build(BuildContext context) {
    final fontSize = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFACBCFF), Color(0xFFf6ecdc)],
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.08,
                left: MediaQuery.of(context).size.width * 0.3,
                child: Column(
                  children: [
                    Container(
                      height: 250,
                      width: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image(
                          fit: BoxFit.cover,
                          image: NetworkImage(widget.book.coverUrl),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      widget.book.title,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height * 0.5,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: fontSize * 0.06,
                      right: fontSize * 0.06,
                      top: fontSize * 0.15,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Chip(
                              label: Text(
                                widget.book.genre,
                                style: TextStyle(
                                  fontSize: fontSize * 0.035,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description',
                              style: TextStyle(
                                fontSize: fontSize * 0.035,
                              ),
                            ),
                            SizedBox(
                              height: fontSize * 0.03,
                            ),
                            Text(
                              "Novels, as a literary form, encompass a vast and diverse range of storytelling. They transport readers to different worlds, times, and perspectives, offering a rich tapestry of experiences and ideas. Novels provide a deep exploration of characters, their motivations, and their interactions, allowing readers to develop a profound connection with the narrative. In general, novels serve as a means of entertainment, education, and enlightenment. They can be fictional or based on real events, and they span various genres such as mystery, adventure, historical fiction, science fiction, fantasy, romance, and many more. Each genre offers its unique elements and appeals to different reader preferences.",
                              style: TextStyle(
                                fontSize: fontSize * 0.03,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.05,
                top: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.1,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Color(0xFFACB1D6),
                    borderRadius: BorderRadius.all(
                      Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: fontSize * 0.03,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ReadPdf(
                                      url: widget.book.pdfUrl,
                                      bookId: widget.book.bookId,
                                    )));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.book,
                                    color: Color(0xFF0C134F),
                                    size: fontSize * 0.06,
                                  ),
                                  SizedBox(
                                    height: fontSize * 0.02,
                                  ),
                                  Text(
                                    'Read',
                                    style: TextStyle(
                                      fontSize: fontSize * 0.03,
                                      color: Color(0xFF0C134F),
                                    ),
                                  )
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => StoreBooksPagesList(
                                            book: widget.book,
                                            // url: widget.book.pdfUrl,
                                          )));
                                },
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.play,
                                      color: Color(0xFF0C134F),
                                      size: fontSize * 0.06,
                                    ),
                                    SizedBox(
                                      height: fontSize * 0.02,
                                    ),
                                    Text(
                                      'Hear Audio',
                                      style: TextStyle(
                                        fontSize: fontSize * 0.03,
                                        color: Color(0xFF0C134F),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 10,
                top: 10,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.back,
                        size: 20,
                        // color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
