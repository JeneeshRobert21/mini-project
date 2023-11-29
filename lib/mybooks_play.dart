// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'dart:ui';

import 'package:audio_wave/audio_wave.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_cache_manager/flutter_cache_manager.dart';
// import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/language/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:like_button/like_button.dart';
// import 'package:just_audio/just_audio.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:http/http.dart' as http;
// import 'package:transloadit/transloadit.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'mybooks.dart';

Future<String> _getTempOutputFilePath() async {
  final appDocumentsDir = await getApplicationDocumentsDirectory();
  final tempOutputFileName = 'temp_output.wav';
  final tempOutputFilePath = '${appDocumentsDir.path}/$tempOutputFileName';
  return tempOutputFilePath;
}

class MyBooksPlayer extends StatefulWidget {
  int pageNumber;
  Book book;

  MyBooksPlayer({
    super.key,
    required this.book,
    required this.pageNumber,
  });

  @override
  State<MyBooksPlayer> createState() => _MyBooksPlayerState();
}

class _MyBooksPlayerState extends State<MyBooksPlayer> {
  final FlutterTts flutterTts = FlutterTts();

  String img_cover_url =
      "https://i.pinimg.com/736x/a7/a9/cb/a7a9cbcefc58f5b677d8c480cf4ddc5d.jpg";

  bool isPlaying = false;
  double value = 0;
  AudioPlayer player = AudioPlayer();
  List<Sentence> lines = [];
  PdfDocument? document;
  int sleeperduration = 999;
  Timer? _timer;
  int sleepIndex = 0;
  AudioCache? audioCache;
  Duration position = Duration.zero;
  Duration duration = Duration.zero;
  int speedIndex = 1;
  String line = "";
  double speedF = 1;

  void startTimer() {
    print('starttimer called');
    print('sleep duration: $sleeperduration');
    _timer = Timer.periodic(Duration(minutes: sleeperduration), (timer) {
      setState(() {
        if (sleeperduration > 0) {
          print(sleeperduration);
          print("so decreasing");
          sleeperduration--;
          print(sleeperduration);
          print("so new");
        } else {
          print(sleeperduration);
          print("so it is over now");
          setState(() {
            isPlaying = !isPlaying;
            print(isPlaying);
          });
          _timer?.cancel();
        }
      });
    });
  }

  List<String> speedOptions = ['0.5x', '1x', '2x'];

  void cycleSpeed() {
    setState(() {
      speedIndex = (speedIndex + 1) % speedOptions.length;
      print(speedIndex);
    });
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
        sleeperduration =
            (int.parse(sleepOptions[sleepIndex].toString().split(" ")[0]));
        startTimer();
      } else {
        sleeperduration = 0;
        _timer?.cancel();
      }
      if (sleeperduration != 0) {}
    });
  }

  Future<List<int>> _fetchDocumentData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      print("got pdf");
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load PDF document from $url');
    }
  }

  void initPlayer() async {
//     TransloaditClient clientA = TransloaditClient(
//       authKey: 'fe4929e26d6647bea186eb3724b02d02',
//       authSecret: 'add526421f0159c0f2edb344e83debbb41c9157d',
//     );

//     TransloaditAssembly assembly = clientA.newAssembly();

// // Next we add two steps, one to import a file, and another to resize it to 400px tall
//     assembly.addStep("import", "/http/import",
//         {"url": "https://demos.transloadit.com/inputs/chameleon.jpg"});
//     assembly.addStep("resize", "/image/resize", {"height": 400});

// // We then send this assembly to Transloadit to be processed
//     TransloaditResponse response = await assembly.createAssembly();

//     print("response"); // "ASSEMBLY_COMPLETED"
//     print(response.data); // "ASSEMBLY_COMPLETED"

    // List<String> audioFilePaths = [
    //   '/storage/emulated/0/Android/data/com.example.audiobooktest/files/audio2.wav',
    //   '/storage/emulated/0/Android/data/com.example.audiobooktest/files/audio1.wav',
    // ];
    // String mergedAudioFilePath =
    //     '/storage/emulated/0/Android/data/com.example.audiobooktest/files/merged_audio.wav';

    // await mergeAudioFiles(audioFilePaths, mergedAudioFilePath);

    // // final track = await FFmpeg.concatenate([
    // //   "/storage/emulated/0/Android/data/com.example.audiobooktest/files/audio2.wav",
    // //   "assets/audios/test2.mp3",
    // //   "assets/audios/test3.mp3",
    // // ], output: "output.mp3");

    document = PdfDocument(
      inputBytes: await _fetchDocumentData(widget.book.pdfUrl),
    );
    String text = PdfTextExtractor(document!)
        .extractText(startPageIndex: widget.pageNumber);
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final accountCredentials = ServiceAccountCredentials.fromJson(r'''
       {
  "type": "service_account",
  "project_id": "audiobooktest-3ea13",
  "private_key_id": "107fb645003a928bb5b067456107732e2c7b6814",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCzhOVnK+3eWAsA\nweK4nAIOgN8QEXcaAkqropwaHoUvbNZLoZUT+/6A1md0EIAx2Pg2zIb1gP54ZLBb\nYPLFOSFMLGMV/mGGwUcMJzUJDvdy/dhNgngTJWvEhZYiMmP9tWP8deYbtrS8t8mr\nkkgncm59O4ItawZtqMnoZG0cpDHE2g60/VEF844VtT0DVcgQh6sb1VDWZNqB9UQO\nA2MtVIkCa4QvKj9lIflt0o6iRvPrPpR7Y5SYR6917zscdgJa425qrEbWm2mgUN5L\n1/eb1WOwuezXlCv62W6IouItRcAvRk1oifGpdSVZ485oepiZiVT1EbKDgmsaFRwE\nPdQ4djlBAgMBAAECggEABWkss5lisrWbT0szbDZiPCcCPNe/QUIZwhFFUebi7h+t\nAzE8RGfvWdlx23u2gXTKtnbKXT1QGOI1YUELet+n80XQjr8mGAux+oR2rW6NYs09\nPHOBmazNEhVSBcyDBbNL74trg3ZUUu6EiO6rIhU+404XNGCUxwVetenLqCCtfK4Q\n9YJt10M4XRIeb5fit/ezAwB3y/wupv5vBjx1UOaDxA9sSlIizv+nEarYJjdAaXAt\nEOi2JLAeCDO8GYXzZMg02q1RiItm7X3SN3VXab2qRwQHnj4iS1k5AHOLr4lMSQNN\nb+Ifw+z3q3RSE7XssS50QwijMRLwyqa94DvIP5iHCQKBgQDZG9cfJpTSKSyssv2h\nBQ4wDIeUJ/sYkFO7Jx9WwygPbwxTfumV8vT7L1TPeO4wfAMF9FTLq51XMXtqKDBU\nxi7w4mwyy2K+6OzDFBJysfOqKwDO19Rz9UVtnPUiRzcIVPoqfX8k7fsITZ28skmK\nczYnYHpZTR2TpNNhY2Mt05emxwKBgQDTrUXmqLb+7otkdeLeZwDTyXlwErmYD46c\nbXshwIIYpeFC86zF+7/czzh6goBs8jk+uiX553KcTu/YkSqEL+3oCLP/lcU4S3fX\n1WujRaui+GvLXch2QLzTK+N40y5zIBMkJZdUdWYfER0BCFtWqvi0QZ47LtwtC7zd\nlHT7fbz3twKBgBoceRDsCPYFsbPLiyl0fDJXL28oJ9DaeteFawV6TzUb+/WGy/0W\nzVPwa1jQiIUYRRzQN+qO50t3TgqEbtujQj4CXVT2lRe019TWcymMMWwD5AL8fja8\nBu+Z8vl+ayX7YmL92O7OGGT1QMVTA/k8xgSSW+Slm6sIJcwOsfzu98w9AoGBAJIO\n/K2k+ug7Z1mBcnKttkdsvOuVMBT5nxjW/mCSufIR+7Y795qBFKljHwCBreX+2Xsr\n7OpcRpwOZ7cSq7icbdduse0IxhYLFP2L2QLHHyCLs62W36yhDOnVXddQOLvdhPer\nLJltjHKhV1cQEh5iSMvwfyMtOWWntMFcH8AsychPAoGALSvQN+fdzb/F5dEuNkAU\n/CU23Uhh3TNUOMA8KkbwIHA3T09q4MKAmH7LLjFkCxscE6g8lRMMlf38ys5wprH+\nRNk7E0gPnDfVaTp+xquUhwOA9tkCDvsB8PWRbd42CmCNZE7bRUNM481PPOqogJiU\nHs1qan8Na5az9rQ+pY49Sxc=\n-----END PRIVATE KEY-----\n",
  "client_email": "audiobooktest@audiobooktest-3ea13.iam.gserviceaccount.com",
  "client_id": "100425683329347848120",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/audiobooktest%40audiobooktest-3ea13.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}

          ''');

    final _googleSignIn = GoogleSignIn(
      scopes: <String>[CloudNaturalLanguageApi.cloudLanguageScope],
    );

    final client = await clientViaServiceAccount(
        accountCredentials, [CloudNaturalLanguageApi.cloudLanguageScope]);
    final language = CloudNaturalLanguageApi(client);

    final documentApi = Document()
      ..content = text
      ..type = "PLAIN_TEXT";

    final sentiment = await language.documents.analyzeSentiment(
      AnalyzeSentimentRequest()..document = documentApi,
    );

    print("sentiment");
    print(sentiment);
    print("sentiment");

    for (var x in sentiment.sentences!) {
      lines.add(x);
    }

    await speakSentences(lines);
    // preloadAudioFiles(lines);

    // // await player.setSource(AssetSource(text));
    // // duration = Duration(seconds: text.length);
  }

  String getAudioFilePath(int index) {
    String fileName = 'audio$index.wav';
    String directory = 'audio'; // Specify the desired directory name

    getApplicationDocumentsDirectory().then((Directory appDocDir) {
      String audioDirPath = '${appDocDir.path}/$directory';
      Directory audioDir = Directory(audioDirPath);
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }
      return '${audioDir.path}/$fileName';
    });
    return '';
  }

  Future<void> mergeAudioFiles(
      List<String> audioFilePaths, String mergedAudioFilePath) async {
    // final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();

    // Generate a temporary file path for intermediate output
    final tempOutputFilePath = mergedAudioFilePath + '.temp.wav';

    // Build the FFmpeg command to merge the audio files
    final command =
        '-i "concat:${audioFilePaths.join('|')}" -c copy $tempOutputFilePath';

    // Execute the FFmpeg command
    // await _flutterFFmpeg.execute(command);

    // Rename the temporary file to the final output file path
    final tempOutputFile = File(tempOutputFilePath);
    await tempOutputFile.rename(mergedAudioFilePath);
  }

  Future<void> preloadAudioFiles(List<Sentence> sentences) async {
    String? audioFilePath;
    for (int i = 0; i < sentences.length; i++) {
      Sentence sentence = sentences[i];
      // String audioFilePath = getAudioFilePath(i);
      audioFilePath = await synthesizeSentence(sentence, i,
          '/storage/emulated/0/Android/data/com.example.audiobooktest/files/');
      // await audioCache!.load(
      //     '/storage/emulated/0/Android/data/com.example.audiobooktest/files/$audioFilePath');
    }
    // player.setSourceAsset(
    //     '/storage/emulated/0/Android/data/com.example.audiobooktest/files/$audioFilePath');
    player.resume();
  }

  Future<String> synthesizeSentence(
      Sentence sentence, int index, String path) async {
    String audioFileName = 'audio$index.wav';

    var pitch = 1.0;
    if (sentence.sentiment!.score! >= 0 && sentence.sentiment!.score! < 0.3) {
      pitch = 1.0;
    } else if (sentence.sentiment!.score! >= 0.3 &&
        sentence.sentiment!.score! < 0.6) {
      pitch = 1.2;
    } else if (sentence.sentiment!.score! >= 0.6 &&
        sentence.sentiment!.score! < 0.8) {
      pitch = 1.5;
    } else if (sentence.sentiment!.score! >= 0.8 &&
        sentence.sentiment!.score! <= 1.0) {
      pitch = 1.8;
    }

    await flutterTts.setPitch(pitch);
    var audioFileP = await flutterTts.synthesizeToFile(
        sentence.text!.content!, audioFileName);
    await flutterTts.awaitSynthCompletion(true);
    // final p = AudioCache();
    // p.play(
    //     '/storage/emulated/0/Android/data/com.example.audiobooktest/files/audio5.wav');
    // player.resume();
    return audioFileName;
  }

  Future<void> speakSentences(List<Sentence> sentences) async {
    if (sentences.isEmpty) return;
    var pitch = 1.0;

    for (var x in sentences) {
      setState(() {
        value += 1;
      });
      if (x.sentiment!.score! >= 0 && x.sentiment!.score! < 0.3) {
        pitch = 1.0;
      } else if (x.sentiment!.score! >= 0.3 && x.sentiment!.score! < 0.6) {
        pitch = 1.2;
      } else if (x.sentiment!.score! >= 0.6 && x.sentiment!.score! < 0.8) {
        pitch = 1.5;
      } else if (x.sentiment!.score! >= 0.8 && x.sentiment!.score! <= 1.0) {
        pitch = 1.8;
      }
      if (speedIndex == 0) {
        setState(() {
          speedF = 0.1;
        });
      }
      if (speedIndex == 1) {
        setState(() {
          speedF = 0.5;
        });
      }
      if (sleepIndex == 2) {
        setState(() {
          speedF = 1.0;
        });
      }
      if (isPlaying) {
        print('playing at $pitch and $speedF');
        flutterTts.setPitch(pitch);
        flutterTts.setSpeechRate(speedF);
        setState(() {
          line = x.text!.content!;
        });
        await flutterTts.awaitSpeakCompletion(true);
        await flutterTts.speak(x.text!.content!);
      }
    }
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> playAudio(String audioFilePath) async {
    await player.stop();
    await audioCache!.load(audioFilePath);
  }

  //init the player
  @override
  void initState() {
    super.initState();

    initPlayer();

    // final audioPlayer = AudioPlayer();
    // audioPlayer.setUrl(
    //     '/storage/emulated/0/Android/data/com.example.audiobooktest/files/audio3.wav',
    //     isLocal: true);
    // print('url set');
    // audioPlayer.resume();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            constraints: BoxConstraints.expand(),
            height: 300.0,
            width: 300.0,
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
              AudioWave(
                animation: true,
                height: 180,
                beatRate: Duration(milliseconds: 150),
                width: MediaQuery.of(context).size.width,
                spacing: 2.5,
                bars: [
                  AudioWaveBar(
                      heightFactor: 0.1,
                      radius: 150,
                      color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.2, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.3, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.4),
                  AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                  AudioWaveBar(
                      heightFactor: 0.6, color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.7, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.8, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.9),
                  AudioWaveBar(heightFactor: 1, color: Colors.orange),
                  AudioWaveBar(
                      heightFactor: 0.9, color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.8, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.7, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.6),
                  AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                  AudioWaveBar(
                      heightFactor: 0.4, color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.3, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.2, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.1),
                  AudioWaveBar(heightFactor: 0.2, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.3, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.4),
                  AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                  AudioWaveBar(
                      heightFactor: 0.6, color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.7, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.8, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.9),
                  AudioWaveBar(heightFactor: 1, color: Colors.orange),
                  AudioWaveBar(
                      heightFactor: 0.9, color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.8, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.7, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.6),
                  AudioWaveBar(heightFactor: 0.5, color: Colors.orange),
                  AudioWaveBar(
                      heightFactor: 0.4, color: Colors.lightBlueAccent),
                  AudioWaveBar(heightFactor: 0.3, color: Colors.blue),
                  AudioWaveBar(heightFactor: 0.2, color: Colors.black),
                  AudioWaveBar(heightFactor: 0.1),
                ],
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
                    ],
                  ),
                  // SizedBox(width: 50, height: 50, child: LikeButton()),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: 400,
                      child: Center(
                        child: Text(
                          line,
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              //Setting the seekbar
              SizedBox(
                height: 50.0,
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: [
              //     Text(
              //       "${value}",
              //       style: TextStyle(color: Colors.white),
              //     ),
              //     Container(
              //       width: 260.0,
              //       child: Slider.adaptive(
              //         onChangeEnd: (new_value) async {
              //           setState(() {
              //             value = new_value;
              //             print(new_value);
              //           });
              //           await player.seek(Duration(seconds: new_value.toInt()));
              //         },
              //         min: 0.0,
              //         value: value,
              //         max: 214.0,
              //         onChanged: (value) {},
              //         activeColor: Colors.white,
              //       ),
              //     ),
              //     // Text(
              //     // "20 : 60",
              //     // "${document!.pages.count}",
              //     // style: TextStyle(color: Colors.white),
              //     // ),
              //   ],
              // ),
              //setting the player controller
              SizedBox(
                height: 60.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
                        setState(() {
                          isPlaying = !isPlaying;
                          print(isPlaying);
                        });
                        //setting the play function
                        await speakSentences(lines);

                        // await player.resume();
                        // player.onPositionChanged.listen(
                        //   (Duration d) {
                        //     setState(() {
                        //       value = d.inSeconds.toDouble();

                        //       print(value);
                        //     });
                        //   },
                        // );
                        // print(duration);
                      },
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
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
    );
  }
}
