// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:io';

import 'package:audiobooktest/books_store.dart';
import 'package:audiobooktest/discussion.dart';
import 'package:audiobooktest/firebase/google_signin.dart';
import 'package:audiobooktest/firebase/user_provider.dart';
import 'package:audiobooktest/home_screen.dart';
import 'package:audiobooktest/mybooks.dart';
import 'package:audiobooktest/test2.dart';
import 'package:audiobooktest/utils/box.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GoogleSignInProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'audiobooktest',
        theme: ThemeData(
          textTheme: TextTheme(
            bodyText1: GoogleFonts.notoSansDisplay(),
            bodyText2: GoogleFonts.notoSansDisplay(),
          ),
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: Color(0xFF6b6bbf),
          ),
        ),
        home: WelcomePage(),
      ),
    );
  }
}

final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: [
  'email',
]);

class WelcomePage extends StatefulWidget {
  WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool _isUploading = false;
  TextEditingController _fileNameController = TextEditingController();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GoogleSignInAccount? _currentAccount;
  String? title;

  @override
  void initState() {
    // _googleSignIn.onCurrentUserChanged.listen((event) {
    //   setState(() {
    //     _currentAccount = event;
    //   });
    // });
    // signIn();
    // _googleSignIn.signInSilently();
    super.initState();
  }

  @override
  void dispose() {
    // _fileNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Future<void> signOut() async {
      try {
        await FirebaseAuth.instance.signOut();

        GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();

        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyApp()));
      } catch (e) {
        print('Error signing out: $e');
      }
    }

    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    // GoogleSignInAccount? user = _currentAccount;
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasData) {
          return HomeScreen();
        } else if (snapshot.hasError) {
          return Center(
            child: Text('Something went wrong!'),
          );
        } else {
          return Scaffold(
            body: Padding(
              padding: EdgeInsets.only(bottom: height * 0.1),
              child: Column(
                children: [
                  Expanded(
                    child: Image(
                      image: AssetImage('assets/welcome.gif'),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: height * 0.05),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'Experience the magic🪄\n',
                          ),
                          TextSpan(text: 'of storytelling.'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: height * 0.1),
                    child: ElevatedButton(
                      onPressed: () {
                        final provider = Provider.of<GoogleSignInProvider>(
                            context,
                            listen: false);
                        provider.googleLogin();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Image(
                              image: AssetImage('assets/google.png'),
                            ),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Text('Sign in with google'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
