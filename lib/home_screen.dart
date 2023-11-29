import 'package:audiobooktest/books_store.dart';
import 'package:audiobooktest/discussion.dart';
import 'package:audiobooktest/firebase/google_signin.dart';
import 'package:audiobooktest/mybooks.dart';
import 'package:audiobooktest/utils/box.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    print("user.email");
    print(user.email);
    print("user.email");
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Stack(
          children: [
            Positioned(
              top: height * 0.07,
              child: SizedBox(
                height: height * 0.6,
                width: width * 0.9,
                child: Image(
                  image: AssetImage('assets/homepage.gif'),
                ),
              ),
            ),
            // Positioned(
            //   top: height * 0.4,
            //   left: width * 0.025,
            //   child: GestureDetector(
            //     onTap: () async {
            //       FilePickerResult? result =
            //           await FilePicker.platform.pickFiles(
            //         type: FileType.custom,
            //         allowedExtensions: ['pdf'],
            //       );
            //       if (result != null) {
            //       showDialog(
            //         context: context,
            //         builder: (BuildContext dialogContext) {
            //           return AlertDialog(
            //             title: Text('Enter PDF Name'),
            //             content: Form(
            //               key: _formKey,
            //               child: TextFormField(
            //                 controller: _fileNameController,
            //                 validator: (value) {
            //                   if (value == null || value.isEmpty) {
            //                     return 'Please enter a name';
            //                   }
            //                   return null;
            //                 },
            //               ),
            //             ),
            //             actions: [
            //               TextButton(
            //                 onPressed: () {
            //                   Navigator.of(dialogContext).pop();
            //                 },
            //                 child: Text('Cancel'),
            //               ),
            //               TextButton(
            //                 onPressed: () async {
            //                   if (_formKey.currentState!.validate()) {
            //                     Navigator.of(dialogContext).pop();
            //                     setState(() {
            //                       _isUploading = true;
            //                     });
            //                     File file = File(result.files.single.path!);
            //                     String fileName = _fileNameController.text;
            //                     await uploadFileAndStoreUrl(file, fileName);
            //                     setState(() {
            //                       _isUploading = false;
            //                     });
            //                   }}
            //     },
            //     child: Box(
            //       iconData: CupertinoIcons.upload_circle,
            //       text: 'Upload new book',
            //     ),
            //   ),
            // ),
            Positioned(
              top: height * 0.4,
              left: width * 0.025,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookStore(userEmail: user.email!),
                    ),
                  );
                },
                child: Box(
                  iconData: CupertinoIcons.book_circle,
                  text: 'Book Store',
                ),
              ),
            ),
            Positioned(
              top: height * 0.4,
              right: width * 0.025,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BookGrid(userEmail: user.email!),
                  ));
                },
                child: Box(
                  iconData: CupertinoIcons.book_circle,
                  text: 'My books',
                ),
              ),
            ),
            Positioned(
              bottom: height * 0.12,
              right: width * 0.025,
              child: GestureDetector(
                onTap: () {
                  final provier =
                      Provider.of<GoogleSignInProvider>(context, listen: false);
                  provier.logout();
                },
                child: Box(
                  iconData: CupertinoIcons.lock_circle,
                  text: 'Sign out',
                ),
              ),
            ),
            Positioned(
              bottom: height * 0.12,
              left: width * 0.025,
              child: GestureDetector(
                onTap: () {
                  // Navigator.of(context).push(
                  //   MaterialPageRoute(
                  //     builder: (_) => DiscussionPage(),
                  //   ),
                  // );
                },
                child: Box(
                  iconData: CupertinoIcons.mic_solid,
                  text: '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
