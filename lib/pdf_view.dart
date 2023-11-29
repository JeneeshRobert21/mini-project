// ignore_for_file: sort_child_properties_last, prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'package:boxicons/boxicons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

import 'firebase/user_provider.dart';

class ReadPdf extends StatefulWidget {
  ReadPdf({Key? key, required this.url, required this.bookId})
      : super(key: key);
  final String url;
  final String bookId;

  @override
  _ReadPdfState createState() => _ReadPdfState();
}

class _ReadPdfState extends State<ReadPdf> {
  final FlutterTts flutterTts = FlutterTts();
  bool isRecording = false;
  String currentText = "";
  int currentPage = 1;
  bool isRecorderInit = false;

  FlutterSoundRecorder? _soundRecorder;

  @override
  void initState() {
    super.initState();
    _soundRecorder = FlutterSoundRecorder();
    openAudio();
  }

  void uploadMessage(String email) async {
    print('entering function');
    var tempDir = await getTemporaryDirectory();
    var path = '${tempDir.path}/flutter_sound.aac';
    if (!isRecorderInit) {
      return;
    }
    if (isRecording) {
      await _soundRecorder!.stopRecorder();
      //upload audio
      print("path");
      print(path);
      await uploadAudioFile(path, widget.bookId, currentPage.toString(), email);
    } else {
      await _soundRecorder!.startRecorder(
        toFile: path,
      );
    }

    setState(() {
      isRecording = !isRecording;
    });
  }

  Future<void> uploadAudioFile(String filePath, String storeDocId,
      String voiceDocId, String email) async {
    File audioFile = File(filePath);
    String fileName = audioFile.path.split('/').last;
    String storagePath = 'voices/$storeDocId/$voiceDocId/$fileName';

    try {
      // Upload the audio file to Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      UploadTask uploadTask = storageRef.putFile(audioFile);
      TaskSnapshot storageSnapshot = await uploadTask.whenComplete(() => null);

      // Get the download URL of the uploaded file
      String downloadURL = await storageSnapshot.ref.getDownloadURL();

      // Store the download URL in Firestore
      CollectionReference storeCollectionRef =
          FirebaseFirestore.instance.collection('store');
      DocumentReference storeDocRef = storeCollectionRef.doc(storeDocId);
      CollectionReference voicesCollectionRef =
          storeDocRef.collection('voices');
      DocumentReference voiceDocRef = voicesCollectionRef.doc(voiceDocId);
      await voiceDocRef.set(
        {
          'voices': FieldValue.arrayUnion([
            {
              'userId': email,
              'voiceUrl': downloadURL,
              'likes': [],
            }
          ])
        },
        SetOptions(merge: true),
      );

      print('Audio uploaded successfully!');
    } catch (error) {
      print('Error uploading audio: $error');
    }
  }

  Future stopRecord() async {
    await _soundRecorder!.stopRecorder();
  }

  void openAudio() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Mic permission not allowed!');
    }
    await _soundRecorder!.openRecorder();
    _soundRecorder!.setSubscriptionDuration(const Duration(milliseconds: 500));
    isRecorderInit = true;
  }

  Future<List<int>> _fetchDocumentData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load PDF document from $url');
    }
  }

  @override
  void dispose() {
    super.dispose();
    _soundRecorder!.closeRecorder();
    isRecorderInit = false;
  }

  // Future<void> _speak() async {
  //   await flutterTts.setLanguage("en-US");
  //   await flutterTts.setPitch(1.0);
  //   await flutterTts.setSpeechRate(0.5);

  //   if (!isRecording) {
  //     setState(() {
  //       print('setting to true...');

  //       isRecording = true;
  //     });
  //   } else {
  //     print('setting to false...');
  //     setState(() {
  //       isRecording = false;
  //     });
  //     await flutterTts.stop();
  //   }

  //   if (isRecording) {
  //     PdfDocument document =
  //         PdfDocument(inputBytes: await _fetchDocumentData(widget.url));
  //     for (int i = 0; i < document.pages.count; i++) {
  //       if (!isRecording) {
  //         break;
  //       }
  //       // print('page $i');

  //       String text = PdfTextExtractor(document).extractText(startPageIndex: i);
  //       text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  //       print(text.characters.length);

  //       if (text.characters.length > 1500) {
  //         final accountCredentials = ServiceAccountCredentials.fromJson(r'''
  //         {
  //           "type": "service_account",
  //           "project_id": "audio-book-22d77",
  //           "private_key_id": "d6b985ac6f8984a89d1d5eeaf56d4b48459691b0",
  //           "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDMOkZOd1bFpCmB\nADffjo6lShISMTqr7jhv0qeJOu2xVvRqIugKp/bJ62Ot8d3sRqXSo7bST+CuXS1A\ngS7zSdlLIjjOSgreXrWKNdpr06t9nPhjs+H2V9ETzbJ8jCISZMKNsZw9xHCNa+Ll\n345DUy9xsx3p+gyV+gG+6ujOObJK9Hhf1gwZ4TNULZjrO/P10V+MAK9W4oIv9brU\nAqkXJvJNWMv0laNd62vNfByIVHt/bIGEQcfCRJoZQ4r8/FL+DDfJQ8xRJwbG0SqC\n0MTHQ+kT0RpMzR3z1oT9HrBwf6VvoI7hX89AixSFlh1M61NoDM+T6kil3pAbaRHb\nKzeGMFu5AgMBAAECggEAJeo/uTuQoXq7tdZbiSaHNwqMVlJLaTX9xkzei6ykCkNx\ndu7qE2hhedU4mUeJAt+O049PVrY7qUNlLk+Nbt9r9vXwg+PdJrGAlJsw5MnUUaq9\ntozjy388MqgClfrSLIYGVJX/wrvghXDdG/4oBDnCWiJ90D167rEOd+pWtEqj3iQ1\nmel16XKZSfMZzpNsYVdCIpmH4HAOFshw67G4Te+MXHWNvhK5BLvAQRcFkTUWkI9U\nb428i/oopf37sKVXiSfHWubI8JBJOO344W8VkXFBzJpBOTDsl0pYerHxjsXrmEJH\nGpoZol35wVvK05oCklFUjhw3/35zqlco8GH/6r8ELQKBgQD7OeqygqC/BdDM1d68\nQqtr4meLhUA/PlYJtqSrmEWEITKUpN6Wc6IB0vl5K6x9eLLBlx/wyu47LhEuZGFR\nsZp8sFWc8Jh1NzILi1UD1XEcxjN/XxUe9mY1E3ViDCa/7maIez00nBfa+QK/ackY\nbxD8dNCHIC1Vk+CKEpI2Mi5BPwKBgQDQG7wDM0xuklCu2AwWFP6IbAUGkr7CpGTZ\nBpZ76hBoWBVr5kVuAfDwWL63TbQjMPTEudpSJLT6EX+LhjckmBlvIHXAojLWIKZX\ng93S0WdWy3qY8P95rDlBA+PV64Bhvss9MOX7OsWTJ1aTqJTVnQ9KM5lNIdMUWGKc\nCMBjAOutBwKBgA2ZyRb483LkAbXVLkXK5jTlAO4QvLWvzkCgXrHbgIfytCZP9qz2\nfaLTpSXmM2RnkGXipJwIoHUbvVphnNMrZk2xzjC85cQSxObTGDso5wLDyC3xG9ed\nR1NARm6UcdSaN3rUETAz8yarrHZoZ7am7Kh+OnvWRh4H73QKJVhBxzdJAoGACGB1\navOPqgu9r6wGoITr0fX3JdKWVyNi49F+ETLUwj55bkRwmwL8/c+0rZA1Jg18bMbG\nYPQVTNOTfLxET/bHX0/BLaXZwgDCcVdfgHLpY/cA0lMxFWa3T0Sm0R+PpV+Wsrnb\nKAevmELHG153zzlpOiVlkFNCOdls7rbzd4i789UCgYEA6M9UVzLX+fZSKD1zG4nq\nA4r4mgBIO4md+ucf0R018nvpk6171P2416yBx0Wk1LNAJLwGxC39S6lkiTgpIIG5\nHPo2MReUVhsY8veIQL/qp9iil2KmBW/4q/l7LaO7YfjrVPFHPRAkY40s9cDr/3nW\nwsOUrbjX1ZJQPzGzrND5Qq0=\n-----END PRIVATE KEY-----\n",
  //           "client_email": "audio-book-sentiment@audio-book-22d77.iam.gserviceaccount.com",
  //           "client_id": "103396866412429728125",
  //           "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  //           "token_uri": "https://oauth2.googleapis.com/token",
  //           "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  //           "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/audio-book-sentiment%40audio-book-22d77.iam.gserviceaccount.com"
  //         }
  //         ''');

  //         final _googleSignIn = GoogleSignIn(
  //           scopes: <String>[CloudNaturalLanguageApi.cloudLanguageScope],
  //         );

  //         final client = await clientViaServiceAccount(
  //             accountCredentials, [CloudNaturalLanguageApi.cloudLanguageScope]);
  //         final language = CloudNaturalLanguageApi(client);

  //         final documentApi = Document()
  //           ..content = text
  //           ..type = "PLAIN_TEXT";

  //         final sentiment = await language.documents.analyzeSentiment(
  //           AnalyzeSentimentRequest()..document = documentApi,
  //         );

  //         List<Sentence> lines = [];
  //         for (var x in sentiment.sentences!) {
  //           lines.add(x);
  //         }

  //         await speakSentences(lines);
  //       }
  //     }
  //   }
  // }

  // Future<void> speakSentences(List<Sentence> sentences) async {
  //   if (sentences.isEmpty) return;
  //   var pitch = 1.0;
  //   for (var x in sentences) {
  //     if (x.sentiment!.score! >= 0 && x.sentiment!.score! < 0.3) {
  //       pitch = 1.0;
  //     } else if (x.sentiment!.score! >= 0.3 && x.sentiment!.score! < 0.6) {
  //       pitch = 1.2;
  //     } else if (x.sentiment!.score! >= 0.6 && x.sentiment!.score! < 0.8) {
  //       pitch = 1.5;
  //     } else if (x.sentiment!.score! >= 0.8 && x.sentiment!.score! <= 1.0) {
  //       pitch = 1.8;
  //     }

  //     if (isRecording) {
  //       flutterTts.setPitch(pitch);
  //       // print('pitch $pitch');
  //       await flutterTts.awaitSpeakCompletion(true);
  //       await flutterTts.speak(x.text!.content!);
  //     }
  //   }
  // }

  void _showConfirmationDialog(BuildContext context, String email) {
    if (isRecording) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Alert'),
            content: Text('This will upload your audio. Continue?'),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Ok'),
                onPressed: () {
                  stopRecord();

                  uploadMessage(email);
                  Navigator.of(context)
                      .pop(true); // Dismiss the dialog and pass true
                },
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text(
                'Are you sure you want to record this page in your voice? This will be the uploaded into the store for corresponding page.'),
            actions: <Widget>[
              ElevatedButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context)
                      .pop(false); // Dismiss the dialog and pass false
                },
              ),
              ElevatedButton(
                child: Text('Record'),
                onPressed: () {
                  uploadMessage(email);
                  Navigator.of(context)
                      .pop(true); // Dismiss the dialog and pass true
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _onTextSelectionChanged(PdfTextSelectionChangedDetails details) {
    if (details.selectedText != null && details.selectedText!.isNotEmpty) {
      setState(() {
        currentText = details.selectedText!;
      });
      if (currentText.isNotEmpty) {
        _showModalSheet(context, currentText);
      }
    } else {
      currentText = "";
    }
  }

  void _onPageSelectionChanged(PdfPageChangedDetails details) {
    currentPage = details.newPageNumber;
    print(currentPage);
  }

  void _showModalSheet(BuildContext context, String searchText) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        late InAppWebViewController webViewController;
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: Uri.parse(
                        "https://www.google.com/search?q=$searchText+meaning"),
                  ),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser!.displayName;

    print("userEmail");
    print(userEmail);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SfPdfViewer.network(
              widget.url,
              onTextSelectionChanged: (details) {
                print(details);
                if (details.selectedText != "") {
                  _onTextSelectionChanged(details);
                }
              },
              onPageChanged: (details) {
                _onPageSelectionChanged(details);
              },
            ),
            Positioned(
              child: Row(
                children: [
                  isRecording
                      ? ElevatedButton(
                          onPressed: () {
                            stopRecord();
                            setState(() {
                              isRecording = false;
                            });
                          },
                          child: Icon(Boxicons.bx_collapse),
                        )
                      : Container(),
                  SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(context, userEmail!);
                    },
                    child: Column(
                      children: [
                        // isRecording ? Icon(Boxicons.bx_skip_next) : Container(),
                        isRecording
                            ? StreamBuilder<RecordingDisposition>(
                                stream: _soundRecorder!.onProgress,
                                builder: (context, snapshot) {
                                  final duration = snapshot.hasData
                                      ? snapshot.data!.duration
                                      : Duration.zero;

                                  String formattime(int n) =>
                                      n.toString().padLeft(2);
                                  final min = formattime(
                                          duration.inMinutes.remainder(60))
                                      .padLeft(2);
                                  final sec = formattime(
                                          duration.inSeconds.remainder(60))
                                      .padLeft(2);
                                  return Text('$min:$sec');
                                },
                              )
                            : Container(),

                        isRecording
                            ? Icon(Boxicons.bx_upload)
                            : Icon(Boxicons.bx_user_voice),
                      ],
                    ),
                  ),
                ],
              ),
              bottom: 20,
              right: 20,
            ),
          ],
        ),
      ),
    );
  }
}
