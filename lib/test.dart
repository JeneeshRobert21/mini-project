import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  final String userEmail;

  HomePage(this.userEmail);
  String? title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My App"),
      ),
      body: Center(
        child: ElevatedButton(
          child: Text("Upload PDF"),
          onPressed: () async {
            // Show dialog box to enter book title
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Enter book title"),
                  content: TextField(
                    decoration: InputDecoration(
                      hintText: "Title",
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      child: Text("CANCEL"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text("OK"),
                      onPressed: () {
                        Navigator.pop(context, title);
                      },
                    ),
                  ],
                );
              },
            );

            if (title == null || title == "") {
              // Book title is required
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Please enter book title."),
                ),
              );
              return;
            }

            // Select PDF file
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
            );

            if (result == null) {
              // No file selected
              return;
            }

            // Upload PDF file to Firebase Storage
            Reference ref = FirebaseStorage.instance
                .ref()
                .child('users/$userEmail/${result.files.first.name}');
            UploadTask task = ref.putData(result.files.first.bytes!);

            // Show progress dialog box
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text("Uploading..."),
                  content: StreamBuilder<TaskSnapshot>(
                    stream: task.snapshotEvents,
                    builder: (context, snapshot) {
                      var progress = 0.0;
                      if (snapshot.hasData) {
                        progress = snapshot.data!.bytesTransferred /
                            snapshot.data!.totalBytes;
                      }
                      return LinearProgressIndicator(value: progress);
                    },
                  ),
                );
              },
            );

            // Wait for upload to complete
            await task.whenComplete(() => Navigator.pop(context));

            // Get download URL of uploaded file
            String url = await ref.getDownloadURL();

            // Store book title and URL in Firestore
            CollectionReference booksRef =
                FirebaseFirestore.instance.collection('users/$userEmail/books');
            booksRef.add({
              'title': title,
              'url': url,
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("PDF uploaded successfully."),
              ),
            );
          },
        ),
      ),
    );
  }
}
