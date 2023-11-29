// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'firebase/user_provider.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _subjecttitleController = TextEditingController();

  bool _isloading = false;

  Future CreatePost(User data) async {
    setState(() {
      _isloading = true;
    });
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    DocumentSnapshot snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(data.email)
        .get();

    String postId = const Uuid().v1();
    try {
      await _firestore.collection('posts').doc(postId).set({
        'postId': postId,
        'email': data.email,
        'name': data.displayName,
        'time': DateTime.now(),
        'description': _textController.text,
        'title': _titleController.text,
        'author': _authorController.text,
        'subjectTitle': _subjecttitleController.text,
        'proPic': data.photoURL!,
        'likes': [],
        'dislikes': [],
      });
    } catch (e) {
      print(e.toString());
    }

    try {
      await _firestore.collection('users').doc(data.email).update({
        'posts': FieldValue.arrayUnion([postId])
      });
    } catch (e) {
      print(e.toString());
    }
    setState(() {
      _isloading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Post',
        ),
        actions: [
          GestureDetector(
            onTap: () async {
              await CreatePost(data);
              Navigator.popUntil(context, (route) => route.isFirst);

              final snackBar = SnackBar(
                /// need to set following properties for best effect of awesome_snackbar_content
                elevation: 0,
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.transparent,
                content: AwesomeSnackbarContent(
                  title: 'Yay',
                  message: 'Post Added',

                  /// change contentType to ContentType.success, ContentType.warning or ContentType.help for variants
                  contentType: ContentType.success,
                ),
              );

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(snackBar);
            },
            child: Row(
              children: [
                Text('Create post'),
                Icon(
                  Icons.post_add,
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(CupertinoIcons.tag),
                            SizedBox(
                              width: 5,
                            ),
                            Chip(
                              backgroundColor: Colors.purple[900],
                              label: SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                height: 25,
                                child: TextField(
                                  style: TextStyle(color: Colors.white),
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Book title',
                                      hintStyle: TextStyle(
                                        color: Colors.white,
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(CupertinoIcons.tag),
                            SizedBox(
                              width: 5,
                            ),
                            Chip(
                              backgroundColor: Colors.purple[900],
                              label: SizedBox(
                                width: MediaQuery.of(context).size.width - 100,
                                height: 25,
                                child: TextField(
                                  controller: _authorController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Author',
                                      hintStyle: TextStyle(
                                        color: Colors.white,
                                      )),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(data.photoURL!),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data.displayName!),
                                Text(DateFormat('dd-MM-yyyy')
                                    .format(DateTime.now())),
                              ],
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _subjecttitleController,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Title',
                                hintStyle: TextStyle(
                                    // color: Colors.white,
                                    )),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Description',
                              hintStyle: TextStyle(
                                  // color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
