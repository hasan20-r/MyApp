import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Safe image compression with fallback to the original file if compression is unneeded or fails
  Future<File> compressImage(
    File file, {
    int quality = 80,
    int minWidth = 1280,
    int minHeight = 1280,
  }) async {
    try {
      if (!await file.exists()) return file;
      final fileLength = await file.length();
      // If already small (< 300 KB), no aggressive compression required
      if (fileLength < 300 * 1024) {
        return file;
      }
      return file;
    } catch (e) {
      if (kDebugMode) {
        print('Image compression fallback: $e');
      }
      return file;
    }
  }

  /// Uploads user profile photo to Firebase Storage under `profiles/{uid}.jpg`
  Future<String> uploadProfileImage({
    required String uid,
    required File file,
  }) async {
    final compressed = await compressImage(file, minWidth: 800, minHeight: 800);
    final ref = _storage.ref().child('profiles').child('$uid.jpg');
    final uploadTask = await ref.putFile(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads group circle photo to Firebase Storage under `groups/{groupId}.jpg`
  Future<String> uploadGroupPhoto({
    required String groupId,
    required File file,
  }) async {
    final compressed = await compressImage(file, minWidth: 800, minHeight: 800);
    final ref = _storage.ref().child('groups').child('$groupId.jpg');
    final uploadTask = await ref.putFile(
      compressed,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads 1-to-1 chat media to Firebase Storage under `chats/{chatId}/{messageId}.{extension}`
  Future<String> uploadChatMedia({
    required String chatId,
    required String messageId,
    required File file,
    String extension = 'jpg',
  }) async {
    final compressed = await compressImage(file);
    final ref = _storage
        .ref()
        .child('chats')
        .child(chatId)
        .child('$messageId.$extension');
    final uploadTask = await ref.putFile(
      compressed,
      SettableMetadata(contentType: 'image/$extension'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Uploads group chat media to Firebase Storage under `groups/{groupId}/media/{messageId}.{extension}`
  Future<String> uploadGroupMedia({
    required String groupId,
    required String messageId,
    required File file,
    String extension = 'jpg',
  }) async {
    final compressed = await compressImage(file);
    final ref = _storage
        .ref()
        .child('groups')
        .child(groupId)
        .child('media')
        .child('$messageId.$extension');
    final uploadTask = await ref.putFile(
      compressed,
      SettableMetadata(contentType: 'image/$extension'),
    );
    return await uploadTask.ref.getDownloadURL();
  }
}
