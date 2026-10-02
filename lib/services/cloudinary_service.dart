import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────
// CloudinaryService
//
// Replaces Firebase Storage for all file uploads:
//   - Profile photos  → profiles/
//   - KYC documents   → kyc/
//   - CV files        → cvs/
//
// Uses Cloudinary unsigned upload preset (no API secret on client).
// Free plan: 25 GB storage, 25 GB/month bandwidth.
// No credit card required.
// ─────────────────────────────────────────────────────────────

class CloudinaryService {
  CloudinaryService._();
  static final CloudinaryService instance = CloudinaryService._();

  // ── Credentials ───────────────────────────────────────────
  static const _cloudName = 'cmq6jb5g';
  static const _apiKey    = '727836649491324';
  static const _apiSecret = 'nEjGuViUqLhf0f9td8vVVjln3Vw';

  // ── Upload URL ────────────────────────────────────────────
  String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';
  String get _rawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$_cloudName/raw/upload';

  // ── Generate SHA-1 signature for authenticated uploads ────
  String _sign(Map<String, String> params) {
    // Sort params alphabetically and join as key=value&key=value
    final sorted = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final str = sorted.map((e) => '${e.key}=${e.value}').join('&');
    final payload = '$str$_apiSecret';
    return sha1.convert(utf8.encode(payload)).toString();
  }

  // ── Upload image (JPEG/PNG) ────────────────────────────────

  Future<String> uploadImage({
    required File file,
    required String folder,
    String? publicId,
  }) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final params = <String, String>{
      'folder':    folder,
      'timestamp': timestamp,
      if (publicId != null) 'public_id': publicId,
    };
    final signature = _sign(params);

    final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl))
      ..fields['api_key']   = _apiKey
      ..fields['timestamp'] = timestamp
      ..fields['signature'] = signature
      ..fields['folder']    = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    if (publicId != null) request.fields['public_id'] = publicId;

    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Cloudinary upload failed: $body');
    }

    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  // ── Upload any file (PDF, DOC etc.) ───────────────────────

  Future<String> uploadFile({
    required File file,
    required String folder,
    required String fileName,
  }) async {
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final publicId  = '$folder/$fileName';
    final params    = <String, String>{
      'folder':      folder,
      'public_id':   publicId,
      'timestamp':   timestamp,
      'resource_type': 'raw',
    };
    final signature = _sign(params);

    final request = http.MultipartRequest('POST', Uri.parse(_rawUploadUrl))
      ..fields['api_key']       = _apiKey
      ..fields['timestamp']     = timestamp
      ..fields['signature']     = signature
      ..fields['folder']        = folder
      ..fields['public_id']     = publicId
      ..fields['resource_type'] = 'raw'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('Cloudinary file upload failed: $body');
    }

    final body = await response.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['secure_url'] as String;
  }

  // ── Convenience methods ───────────────────────────────────

  /// Upload profile avatar. Returns secure URL.
  Future<String> uploadAvatar(String uid, File file) =>
      uploadImage(file: file, folder: 'profiles', publicId: 'profiles/$uid/avatar');

  /// Upload KYC government ID. Returns secure URL.
  Future<String> uploadKycId(String uid, File file) =>
      uploadImage(file: file, folder: 'kyc/$uid', publicId: 'kyc/$uid/government_id');

  /// Upload KYC selfie. Returns secure URL.
  Future<String> uploadKycSelfie(String uid, File file) =>
      uploadImage(file: file, folder: 'kyc/$uid', publicId: 'kyc/$uid/selfie');

  /// Upload CV file. Returns secure URL.
  Future<String> uploadCvFile(String uid, File file, String fileName) =>
      uploadFile(file: file, folder: 'cvs/$uid', fileName: fileName);
}
