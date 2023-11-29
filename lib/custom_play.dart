// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'dart:async';
import 'dart:ui';
import 'package:audio_wave/audio_wave.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/language/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:like_button/like_button.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
import 'books_store.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'firebase/user_provider.dart';

Future<String> _getTempOutputFilePath() async {
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final tempOutputFileName = 'temp_output.wav';
  final tempOutputFilePath = '${appDocumentsDir.path}/$tempOutputFileName';
  return tempOutputFilePath;
}

class CustomPlayer extends StatefulWidget {
  int pageNumber;
  Book book;
  final String voiceUrl;
  int voiceIndex;
  CustomPlayer({
    super.key,
    required this.book,
    required this.pageNumber,
    required this.voiceUrl,
    required this.voiceIndex,
  });

  @override
  State<CustomPlayer> createState() => _CustomPlayerState();
}

class _CustomPlayerState extends State<CustomPlayer> {
  final FlutterTts flutterTts = FlutterTts();

  String img_cover_url =
      "https://i.pinimg.com/736x/a7/a9/cb/a7a9cbcefc58f5b677d8c480cf4ddc5d.jpg";

  bool isPlaying = false;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  final audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _timer?.cancel();
    audioPlayer.dispose();
    super.dispose();
  }

  String formatTime(
    Duration duration,
  ) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [
      if (duration.inHours > 0) hours,
      minutes,
      seconds,
    ].join(':');
  }

  double value = 0;
  AudioPlayer Customplayer = AudioPlayer();
  List<Sentence> lines = [];
  PdfDocument? document;
  int Sleeperduration = 5;
  Timer? _timer;
  int sleepIndex = 0;
  AudioCache? audioCache;

  int speedIndex = 1;
  String line = "";
  double speedF = 1;

  void startTimer() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {
        if (Sleeperduration > 0) {
          Sleeperduration--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  List<String> speedOptions = ['0.5x', '1x', '2x'];
  List<double> speeds = [0.5, 1, 2];

  void cycleSpeed() {
    setState(() {
      speedIndex = (speedIndex + 1) % speedOptions.length;
      print(speeds[speedIndex]);
    });
    audioPlayer.setPlaybackRate(speeds[speedIndex]);
  }

  List<String> sleepOptions = [
    'off',
    '1 min',
    '5 min',
    '10 min',
    '20 min',
    '30 min',
    '60 min'
  ];

  void sleepCycleSpeed() {
    setState(() {
      sleepIndex = (sleepIndex + 1) % sleepOptions.length;
      if (sleepOptions[sleepIndex] != 'off') {
        Sleeperduration =
            (int.parse(sleepOptions[sleepIndex].toString().split(" ")[0]));
        startTimer();
      } else {
        Sleeperduration = 0;
        _timer?.cancel();
      }
      if (Sleeperduration != 0) {}
    });
  }

  Future<List<int>> _fetchDocumentData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print("got pdf");
      print('hi');
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load PDF document from $url');
    }
  }

  Future setAudio() async {
    audioPlayer.setReleaseMode(ReleaseMode.stop);
    String url = widget.voiceUrl;

    await audioPlayer.play(UrlSource(url));
  }

  //init the Customplayer
  @override
  void initState() {
    super.initState();
    setAudio();
    audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        isPlaying = state == PlayerState.playing;
      });
    });

    audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        duration = newDuration;
      });
    });

    audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        position = newPosition;
      });
    });
    // final audioCustomPlayer = AudioCustomPlayer();
    // audioCustomPlayer.setUrl(
    //     '/storage/emulated/0/Android/data/com.example.audiobooktest/files/audio3.wav',
    //     isLocal: true);
    // print('url set');
    // audioCustomPlayer.resume();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = FirebaseAuth.instance.currentUser!;

    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              constraints: BoxConstraints.expand(),
              height: 200.0,
              width: 200.0,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.book.coverUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //setting the music cover
                // AudioWave(
                //   animation: true,
                //   height: 180,
                //   beatRate: Duration(milliseconds: 150),
                //   width: MediaQuery.of(context).size.width,
                //   spacing: 2.5,
                //   bars: [
                //     AudioWaveBar(
                //         heightFactor: 0.1,
                //         radius: 150,
                //         color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.2, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.3, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.4),
                //     AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                //     AudioWaveBar(
                //         heightFactor: 0.6, color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.7, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.8, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.9),
                //     AudioWaveBar(heightFactor: 1, color: Colors.orange),
                //     AudioWaveBar(
                //         heightFactor: 0.9, color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.8, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.7, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.6),
                //     AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                //     AudioWaveBar(
                //         heightFactor: 0.4, color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.3, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.2, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.1),
                //     AudioWaveBar(heightFactor: 0.2, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.3, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.4),
                //     AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                //     AudioWaveBar(
                //         heightFactor: 0.6, color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.7, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.8, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.9),
                //     AudioWaveBar(heightFactor: 1, color: Colors.orange),
                //     AudioWaveBar(
                //         heightFactor: 0.9, color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.8, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.7, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.6),
                //     AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                //     AudioWaveBar(
                //         heightFactor: 0.4, color: Colors.lightBlueAccent),
                //     AudioWaveBar(heightFactor: 0.3, color: Colors.blue),
                //     AudioWaveBar(heightFactor: 0.2, color: Colors.black),
                //     AudioWaveBar(heightFactor: 0.1),
                //   ],
                // ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    widget.book.coverUrl,
                    width: double.infinity,
                    height: 350,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Column(
                  children: [
                    Text(
                      widget.book.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Page ${widget.pageNumber}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('store')
                                .doc(widget.book.bookId)
                                .collection('voices')
                                .doc((widget.pageNumber + 1).toString())
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (!snapshot.hasData) {
                                return CircularProgressIndicator();
                              }
                              Map<String, dynamic> datas =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              print(
                                  datas['voices'][widget.voiceIndex]['likes']);
                              print(
                                  "datas['voices'][widget.pageNumber]['voices'][widget.voiceIndex]['likes']");
                              int likesCount = datas['voices']
                                          [widget.voiceIndex]['likes'] !=
                                      null
                                  ? datas['voices'][widget.voiceIndex]['likes']
                                      .length
                                  : 0;
                              bool isLiked = datas['voices'][widget.voiceIndex]
                                          ['likes'] !=
                                      null
                                  ? datas['voices'][widget.voiceIndex]['likes']
                                      .contains(userProvider.email)
                                  : false;
                              return Row(
                                children: [
                                  IconButton(
                                    onPressed: () async {
                                      DocumentReference postRef =
                                          FirebaseFirestore.instance
                                              .collection('store')
                                              .doc(widget.book.bookId)
                                              .collection('voices')
                                              .doc((widget.pageNumber + 1)
                                                  .toString());

                                      DocumentSnapshot postSnapshot =
                                          await postRef.get();
                                      final data = postSnapshot.data()
                                          as Map<String, dynamic>;
                                      List<dynamic> voicesArray =
                                          data['voices'];

                                      int index = widget.voiceIndex;
                                      if (index >= 0 &&
                                          index < voicesArray.length) {
                                        Map<String, dynamic> selectedVoice =
                                            voicesArray[index];
                                        List<dynamic> likesArray =
                                            selectedVoice['likes'] ?? [];

                                        String email = userProvider.email!;
                                        if (likesArray.contains(email)) {
                                          likesArray.remove(email);
                                        } else {
                                          likesArray.add(email);
                                        }

                                        selectedVoice['likes'] = likesArray;
                                        voicesArray[index] = selectedVoice;
                                        await postRef
                                            .update({'voices': voicesArray});
                                      }
                                    },
                                    icon: Icon(
                                      CupertinoIcons.hand_thumbsup,
                                      color:
                                          isLiked ? Colors.green : Colors.black,
                                    ),
                                  ),
                                  Text('$likesCount')
                                ],
                              );
                            }),
                      ],
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.all(8.0),
                    //   child: SizedBox(
                    //     width: 400,
                    //     child: Center(
                    //       child: Text(
                    //         line,
                    //         style: TextStyle(
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
                //Setting the seekbar
                SizedBox(
                  height: 50.0,
                ),
                Slider(
                  min: 0,
                  max: duration.inSeconds.toDouble(),
                  value: position.inSeconds.toDouble(),
                  onChanged: (value) async {
                    final position = Duration(seconds: value.toInt());
                    await audioPlayer.seek(position);

                    await audioPlayer.resume();
                  },
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatTime(position)),
                      Text(formatTime(duration - position)),
                    ],
                  ),
                ),

                SizedBox(
                  height: 60.0,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60.0),
                        color: Colors.black87,
                        border: Border.all(color: Colors.white38),
                      ),
                      width: 70.0,
                      height: 70.0,
                      child: InkWell(
                        child: IconButton(
                          icon: Text(
                            sleepOptions[sleepIndex],
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () {
                            sleepCycleSpeed();
                          },
                          tooltip: 'Sleep Timer',
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 20.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60.0),
                        color: Colors.black87,
                        border: Border.all(color: Colors.pink),
                      ),
                      width: 70.0,
                      height: 70.0,
                      child: InkWell(
                        onTap: () async {
                          if (isPlaying) {
                            await audioPlayer.pause();
                          } else {
                            await audioPlayer.resume();
                          }
                        },
                        child: Center(
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60.0),
                        color: Colors.black87,
                        border: Border.all(color: Colors.white38),
                      ),
                      width: 60.0,
                      height: 60.0,
                      child: InkWell(
                        child: Center(
                          child: IconButton(
                            icon: Text(
                              speedOptions[speedIndex],
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () {
                              cycleSpeed();
                            },
                            tooltip: 'Playback Speed',
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
