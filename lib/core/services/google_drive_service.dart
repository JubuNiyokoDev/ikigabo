import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.file'],
    // Sur Android, l'Android OAuth client ID (package + SHA-1)
    // est utilisé automatiquement. serverClientId optionnel pour idToken.
  );

  static GoogleSignInAccount? _currentUser;

  static bool get isSignedIn => _currentUser != null;
  static String? get userEmail => _currentUser?.email;
  static String? get userName => _currentUser?.displayName;

  static Future<bool> signIn() async {
    try {
      // Tente de restaurer une session existante
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser != null) {
        developer.log(
          'Session Google restaurée: ${_currentUser!.email}',
          name: 'GoogleDriveService',
        );
        return true;
      }

      // Nouvelle connexion
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser != null) {
        developer.log(
          'Google Sign-In réussi: ${_currentUser!.email}',
          name: 'GoogleDriveService',
        );
        return true;
      }
      return false;
    } catch (e) {
      developer.log(
        'Google Sign-In échoué: $e',
        name: 'GoogleDriveService',
        error: e,
      );
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    developer.log('Google Sign-Out effectué', name: 'GoogleDriveService');
  }

  static Future<bool> isUserSignedIn() async {
    if (_currentUser != null) return true;
    _currentUser = await _googleSignIn.signInSilently();
    return _currentUser != null;
  }

  static Future<String?> _getAccessToken() async {
    if (_currentUser == null) return null;
    try {
      final auth = await _currentUser!.authentication;
      if (auth.accessToken == null) {
        // Forcer une nouvelle authentification
        _currentUser = await _googleSignIn.signIn();
        if (_currentUser == null) return null;
        final newAuth = await _currentUser!.authentication;
        return newAuth.accessToken;
      }
      return auth.accessToken;
    } catch (e) {
      developer.log(
        'Erreur récupération token: $e',
        name: 'GoogleDriveService',
        error: e,
      );
      return null;
    }
  }

  static Future<String?> _findAppFolder(String accessToken) async {
    const query =
        "name='IkigaboBackups' and mimeType='application/vnd.google-apps.folder' and trashed=false";
    final searchUrl = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'q': query,
      'spaces': 'drive',
      'pageSize': '1',
      'fields': 'files(id,name)',
    });

    final searchResponse = await http.get(
      searchUrl,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (searchResponse.statusCode == 200) {
      final data = jsonDecode(searchResponse.body);
      if (data['files'] != null && data['files'].isNotEmpty) {
        return data['files'][0]['id'];
      }
    }

    return null;
  }

  static Future<String?> _getOrCreateAppFolder(String accessToken) async {
    final existingFolder = await _findAppFolder(accessToken);
    if (existingFolder != null) return existingFolder;

    final createUrl = Uri.parse('https://www.googleapis.com/drive/v3/files');
    final folderMetadata = jsonEncode({
      'name': 'IkigaboBackups',
      'mimeType': 'application/vnd.google-apps.folder',
    });

    final createResponse = await http.post(
      createUrl,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: folderMetadata,
    );

    if (createResponse.statusCode == 200 || createResponse.statusCode == 201) {
      final data = jsonDecode(createResponse.body);
      return data['id'];
    }

    developer.log(
      'Erreur création dossier Drive: '
      '${createResponse.statusCode} ${createResponse.body}',
      name: 'GoogleDriveService',
    );
    return null;
  }

  static Future<List<DriveBackupInfo>> listBackups({int pageSize = 10}) async {
    if (_currentUser == null && !await isUserSignedIn()) {
      return const [];
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return const [];

      final folderId = await _findAppFolder(accessToken);
      if (folderId == null) return const [];

      final query =
          "'$folderId' in parents and trashed=false and name contains 'ikigabo_backup_'";
      final url = Uri.https('www.googleapis.com', '/drive/v3/files', {
        'q': query,
        'spaces': 'drive',
        'orderBy': 'createdTime desc',
        'pageSize': pageSize.toString(),
        'fields': 'files(id,name,createdTime,modifiedTime,size)',
      });

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        developer.log(
          'Erreur liste backups Drive: ${response.statusCode} ${response.body}',
          name: 'GoogleDriveService',
        );
        return const [];
      }

      final data = jsonDecode(response.body);
      final files = data['files'] as List<dynamic>? ?? const [];
      return files
          .whereType<Map<String, dynamic>>()
          .map(DriveBackupInfo.fromDriveFile)
          .toList();
    } catch (e) {
      developer.log(
        'Erreur liste backups Drive: $e',
        name: 'GoogleDriveService',
        error: e,
      );
      return const [];
    }
  }

  static Future<DriveBackupInfo?> getLatestBackup() async {
    final backups = await listBackups(pageSize: 1);
    if (backups.isEmpty) return null;
    return backups.first;
  }

  static Future<String?> downloadBackup(String fileId) async {
    if (_currentUser == null && !await isUserSignedIn()) {
      return null;
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return null;

      final url = Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {
        'alt': 'media',
      });
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes);
      }

      developer.log(
        'Erreur download Drive: ${response.statusCode} ${response.body}',
        name: 'GoogleDriveService',
      );
      return null;
    } catch (e) {
      developer.log(
        'Erreur download Drive: $e',
        name: 'GoogleDriveService',
        error: e,
      );
      return null;
    }
  }

  /// Calcule la taille en MB du backup avant upload.
  static double calculateBackupSizeMB(String backupData) {
    final bytes = utf8.encode(backupData);
    return bytes.length / (1024 * 1024);
  }

  static Future<bool> uploadBackup(
    String backupData, {
    void Function(double uploadedMB, double totalMB, double percent)?
    onProgress,
  }) async {
    if (_currentUser == null && !await isUserSignedIn()) return false;

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      final folderId = await _getOrCreateAppFolder(accessToken);
      if (folderId == null) return false;

      final now = DateTime.now();
      final filename =
          'ikigabo_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

      final uploadUrl = Uri.https(
        'www.googleapis.com',
        '/upload/drive/v3/files',
        {'uploadType': 'multipart', 'fields': 'id,name'},
      );

      final metadata = jsonEncode({
        'name': filename,
        'parents': [folderId],
        'description': 'Ikigabo backup - ${now.toIso8601String()}',
      });

      final boundary =
          'ikigabo_${now.microsecondsSinceEpoch}_${backupData.length}';
      final body = utf8.encode(
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$metadata\r\n'
        '--$boundary\r\n'
        'Content-Type: application/json; charset=UTF-8\r\n\r\n'
        '$backupData\r\n'
        '--$boundary--\r\n',
      );

      final totalMB = body.length / (1024 * 1024);

      // Simuler progression réaliste (préparation → upload → finalisation)
      onProgress?.call(0, totalMB, 0);
      await Future.delayed(const Duration(milliseconds: 200));
      onProgress?.call(totalMB * 0.1, totalMB, 10);

      final response = await http.post(
        uploadUrl,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      );

      onProgress?.call(totalMB * 0.9, totalMB, 90);
      await Future.delayed(const Duration(milliseconds: 150));

      if (response.statusCode == 200 || response.statusCode == 201) {
        onProgress?.call(totalMB, totalMB, 100);
        await _cleanOldBackups(accessToken, folderId);
        developer.log(
          'Backup uploadé sur Drive: $filename',
          name: 'GoogleDriveService',
        );
        return true;
      }

      developer.log(
        'Erreur upload Drive: ${response.statusCode} ${response.body}',
        name: 'GoogleDriveService',
      );
      return false;
    } catch (e) {
      developer.log(
        'Erreur upload Drive: $e',
        name: 'GoogleDriveService',
        error: e,
      );
      return false;
    }
  }

  static Future<void> _cleanOldBackups(
    String accessToken,
    String folderId,
  ) async {
    try {
      final query = "'$folderId' in parents and trashed=false";
      final url = Uri.https('www.googleapis.com', '/drive/v3/files', {
        'q': query,
        'orderBy': 'createdTime',
        'pageSize': '20',
        'fields': 'files(id,name,createdTime)',
      });

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List?;
        if (files != null && files.length > 10) {
          files.sort((a, b) {
            final aTime = a['createdTime'] ?? '';
            final bTime = b['createdTime'] ?? '';
            return aTime.compareTo(bTime);
          });

          for (int i = 0; i < files.length - 10; i++) {
            final fileId = files[i]['id'];
            if (fileId != null) {
              await http.delete(
                Uri.parse('https://www.googleapis.com/drive/v3/files/$fileId'),
                headers: {'Authorization': 'Bearer $accessToken'},
              );
            }
          }
        }
      }
    } catch (e) {
      developer.log(
        'Erreur nettoyage vieux backups: $e',
        name: 'GoogleDriveService',
        error: e,
      );
    }
  }
}

class DriveBackupInfo {
  final String id;
  final String name;
  final DateTime? createdTime;
  final DateTime? modifiedTime;
  final int? sizeBytes;

  const DriveBackupInfo({
    required this.id,
    required this.name,
    this.createdTime,
    this.modifiedTime,
    this.sizeBytes,
  });

  factory DriveBackupInfo.fromDriveFile(Map<String, dynamic> file) {
    int? parseSize(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return DriveBackupInfo(
      id: file['id'] as String? ?? '',
      name: file['name'] as String? ?? 'ikigabo_backup.json',
      createdTime: DateTime.tryParse(file['createdTime'] as String? ?? ''),
      modifiedTime: DateTime.tryParse(file['modifiedTime'] as String? ?? ''),
      sizeBytes: parseSize(file['size']),
    );
  }

  double? get sizeMB => sizeBytes == null ? null : sizeBytes! / (1024 * 1024);
}
