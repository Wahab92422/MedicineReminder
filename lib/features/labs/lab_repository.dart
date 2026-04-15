import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import 'lab_model.dart';

class PickedLabFile {
  const PickedLabFile({
    required this.path,
    required this.fileName,
    required this.fileExtension,
    required this.mimeType,
    required this.sizeBytes,
  });

  final String path;
  final String fileName;
  final String fileExtension;
  final String mimeType;
  final int sizeBytes;

  File get file => File(path);
}

class LabUploadResult {
  const LabUploadResult({
    required this.downloadUrl,
    required this.storagePath,
    required this.mimeType,
    required this.fileSize,
    required this.fileName,
    required this.fileExtension,
  });

  final String downloadUrl;
  final String storagePath;
  final String mimeType;
  final int fileSize;
  final String fileName;
  final String fileExtension;
}

class LabRepository {
  LabRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String collection = 'lab_reports';

  Future<PickedLabFile?> pickFile() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.any,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final platformFile = result.files.single;
    final path = platformFile.path;
    if (path == null) return null;

    final file = File(path);
    final sizeBytes = await file.length();
    final baseName = platformFile.name;
    var ext = p.extension(baseName).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty) {
      ext = 'bin';
    }

    var mimeType = lookupMimeType(path) ??
        lookupMimeType(baseName) ??
        'application/octet-stream';

    final headerMime = await _mimeFromHeader(file);
    if (headerMime != null) {
      mimeType = headerMime;
    }

    return PickedLabFile(
      path: path,
      fileName: baseName,
      fileExtension: ext,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }

  Future<String?> _mimeFromHeader(File file) async {
    try {
      final raf = await file.open();
      try {
        final header = await raf.read(512);
        return lookupMimeType(file.path, headerBytes: header);
      } finally {
        await raf.close();
      }
    } catch (_) {
      return null;
    }
  }

  String _safeStorageSegment(String name) {
    return name.replaceAll(RegExp(r'[/\\]'), '_').trim();
  }

  Future<LabUploadResult> uploadFileToStorage({
    required String userId,
    required File file,
    required String originalFileName,
    String? mimeType,
  }) async {
    final safeName = _safeStorageSegment(originalFileName);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final storagePath = 'lab_reports/$userId/${ts}_$safeName';

    final resolvedMime = mimeType ??
        lookupMimeType(file.path) ??
        'application/octet-stream';

    final ref = _storage.ref().child(storagePath);
    await ref.putFile(
      file,
      SettableMetadata(contentType: resolvedMime),
    );

    final url = await ref.getDownloadURL();
    final size = await file.length();
    final ext = p.extension(originalFileName).replaceFirst('.', '').toLowerCase();

    return LabUploadResult(
      downloadUrl: url,
      storagePath: storagePath,
      mimeType: resolvedMime,
      fileSize: size,
      fileName: p.basename(originalFileName),
      fileExtension: ext.isEmpty ? 'bin' : ext,
    );
  }

  Future<String> addLabReport(LabReport report) async {
    final doc = await _firestore.collection(collection).add(report.toMap());
    return doc.id;
  }

  Future<void> updateLabReport(LabReport report) async {
    await _firestore.collection(collection).doc(report.id).update(report.toMap());
  }

  Future<void> deleteFileByUrl(String url) async {
    try {
      await _storage.refFromURL(url).delete();
    } catch (_) {}
  }

  Future<void> deleteLabReport(LabReport report) async {
    await deleteFileByUrl(report.fileUrl);
    await _firestore.collection(collection).doc(report.id).delete();
  }

  Stream<List<LabReport>> getUserLabReportsStream(String userId) {
    return _firestore
        .collection(collection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LabReport.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }
}
