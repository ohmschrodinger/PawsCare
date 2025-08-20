import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL
  static Future<String> uploadAnimalImage(File file, String animalId, int index) async {
    final ref = _storage.ref().child('animal_photos/$animalId/photo_$index.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
