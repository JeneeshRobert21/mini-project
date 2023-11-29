import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

GoogleSignInAccount? _currentAccount;

Future<String> uploadPdf(String filename, File file) async {
  GoogleSignInAccount? user = _currentAccount;
  final reference =
      FirebaseStorage.instance.ref().child("pdfs/${user!.email}/$filename.pdf");
  final uploadTask = reference.putFile(file);
  await uploadTask.whenComplete(() {});
  final pdfUrl = await reference.getDownloadURL();
  return pdfUrl;
}
