// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:audiobooktest/addpost.dart';
import 'package:audiobooktest/comment_modal_sheet.dart';
import 'package:audiobooktest/firebase/user_provider.dart';
import 'package:audiobooktest/model/post.dart';
import 'package:boxicons/boxicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DiscussionPage extends StatefulWidget {
  const DiscussionPage({super.key});

  @override
  State<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends State<DiscussionPage> {
  String formatDateTime(DateTime dateTime) {
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inHours < 1) {
      return 'Less than an hour ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('dd-MM-yyyy').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        title: Text(
          'Discussions',
        ),
        actions: [
          Icon(CupertinoIcons.search),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => AddPost()));
              },
              child: Container(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.pencil_outline,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Start a discussion'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('posts').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No posts found'));
                  }

                  List<Post> posts = snapshot.data!.docs.map((doc) {
                    return Post.fromMap(doc.data() as Map<String, dynamic>);
                  }).toList();

                  return ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      Post post = posts[index];
                      String timeAgo = formatDateTime(post.time);

                      return Padding(
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
                                      label: Text(
                                        post.title,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Chip(
                                      backgroundColor: Colors.purple[900],
                                      label: Text(
                                        post.author,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage:
                                          NetworkImage(post.propic),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(post.name),
                                        Text(timeAgo),
                                      ],
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    post.subjectTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Text(
                                  post.description,
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          StreamBuilder<DocumentSnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('posts')
                                                  .doc(post.postId)
                                                  .snapshots(),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<
                                                          DocumentSnapshot>
                                                      snapshot) {
                                                if (!snapshot.hasData) {
                                                  return CircularProgressIndicator();
                                                }
                                                Map<String, dynamic> datas =
                                                    snapshot.data!.data()
                                                        as Map<String, dynamic>;
                                                int likesCount =
                                                    datas['likes'] != null
                                                        ? datas['likes'].length
                                                        : 0;
                                                bool isLiked = datas['likes'] !=
                                                        null
                                                    ? datas['likes']
                                                        .contains(data.email)
                                                    : false;
                                                return Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        DocumentReference
                                                            postRef =
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'posts')
                                                                .doc(post
                                                                    .postId);
                                                        if (isLiked) {
                                                          postRef.update({
                                                            'likes': FieldValue
                                                                .arrayRemove([
                                                              data.email
                                                            ])
                                                          });
                                                        } else {
                                                          postRef.update({
                                                            'likes': FieldValue
                                                                .arrayUnion([
                                                              data.email
                                                            ])
                                                          });
                                                        }
                                                      },
                                                      icon: Icon(
                                                        CupertinoIcons
                                                            .hand_thumbsup,
                                                        color: isLiked
                                                            ? Colors.green
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                    Text('$likesCount')
                                                  ],
                                                );
                                              }),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          StreamBuilder<DocumentSnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('posts')
                                                  .doc(post.postId)
                                                  .snapshots(),
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<
                                                          DocumentSnapshot>
                                                      snapshot) {
                                                if (!snapshot.hasData) {
                                                  return CircularProgressIndicator();
                                                }
                                                Map<String, dynamic> datas =
                                                    snapshot.data!.data()
                                                        as Map<String, dynamic>;
                                                int dislikesCount =
                                                    datas['dislikes'] != null
                                                        ? datas['dislikes']
                                                            .length
                                                        : 0;
                                                bool isLiked =
                                                    datas['dislikes'] != null
                                                        ? datas['dislikes']
                                                            .contains(
                                                                data.email)
                                                        : false;
                                                return Row(
                                                  children: [
                                                    IconButton(
                                                      onPressed: () {
                                                        DocumentReference
                                                            postRef =
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                    'posts')
                                                                .doc(post
                                                                    .postId);
                                                        if (isLiked) {
                                                          postRef.update({
                                                            'dislikes': FieldValue
                                                                .arrayRemove([
                                                              data.email
                                                            ])
                                                          });
                                                        } else {
                                                          postRef.update({
                                                            'dislikes':
                                                                FieldValue
                                                                    .arrayUnion([
                                                              data.email
                                                            ])
                                                          });
                                                        }
                                                      },
                                                      icon: Icon(
                                                        CupertinoIcons
                                                            .hand_thumbsdown,
                                                        color: isLiked
                                                            ? Colors.red
                                                            : Colors.black,
                                                      ),
                                                    ),
                                                    Text('$dislikesCount')
                                                  ],
                                                );
                                              }),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          StreamBuilder<
                                              DocumentSnapshot<
                                                  Map<String, dynamic>>>(
                                            stream: FirebaseFirestore.instance
                                                .collection('comments')
                                                .doc(post.postId)
                                                .snapshots(),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<
                                                        DocumentSnapshot<
                                                            Map<String,
                                                                dynamic>>>
                                                    snapshot) {
                                              if (snapshot.hasData) {
                                                final comments =
                                                    snapshot.data!.data();
                                                if (comments != null &&
                                                    comments.containsKey(
                                                        'comments')) {
                                                  final commentsList =
                                                      comments['comments']
                                                          as List<dynamic>;
                                                  final numComments =
                                                      commentsList.length;
                                                  return Row(
                                                    children: [
                                                      IconButton(
                                                        onPressed: () {
                                                          showModalBottomSheet(
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              10)),
                                                              context: context,
                                                              builder:
                                                                  (context) {
                                                                return CommentModalSheet(
                                                                  postID: post
                                                                      .postId,
                                                                  name:
                                                                      post.name,
                                                                  email: data
                                                                      .email!,
                                                                );
                                                              });
                                                        },
                                                        icon: Icon(Boxicons
                                                            .bx_comment),
                                                      ),
                                                      Text(numComments
                                                          .toString()),
                                                    ],
                                                  );
                                                }
                                              }
                                              // Return a default value if the document does not exist
                                              return Column(
                                                children: [
                                                  IconButton(
                                                    onPressed: () {
                                                      print("what");
                                                      showModalBottomSheet(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                          context: context,
                                                          builder: (context) {
                                                            return CommentModalSheet(
                                                              postID:
                                                                  post.postId,
                                                              name: post.name,
                                                              email:
                                                                  data.email!,
                                                            );
                                                          });
                                                    },
                                                    icon: Icon(
                                                      Boxicons.bx_comment,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
