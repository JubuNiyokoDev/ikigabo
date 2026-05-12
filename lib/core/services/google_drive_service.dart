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

  static Future<String?> _getOrCreateAppFolder(String accessToken) async {
    const query =
        "name='IkigaboBackups' and mimeType='application/vnd.google-apps.folder' and trashed=false";
    final searchUrl = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}&spaces=drive',
    );

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

    if (createResponse.statusCode == 200) {
      final data = jsonDecode(createResponse.body);
      return data['id'];
    }

    developer.log(
      'Erreur création dossier Drive: ${createResponse.statusCode}',
      name: 'GoogleDriveService',
    );
    return null;
  }

  static Future<bool> uploadBackup(String backupData) async {
    if (_currentUser == null && !await isUserSignedIn()) return false;

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) return false;

      final folderId = await _getOrCreateAppFolder(accessToken);
      if (folderId == null) return false;

      final now = DateTime.now();
      final filename =
          'ikigabo_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.json';

      await _cleanOldBackups(accessToken, folderId);

      final uploadUrl = Uri.parse(
        'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
      );

      final metadata = jsonEncode({
        'name': filename,
        'parents': [folderId],
        'description': 'Ikigabo backup - ${now.toIso8601String()}',
      });

      final request = http.MultipartRequest('POST', uploadUrl);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['metadata'] = metadata;
      request.files.add(
        http.MultipartFile.fromString('media', backupData),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        developer.log(
          'Backup uploadé sur Drive: $filename',
          name: 'GoogleDriveService',
        );
        return true;
      }

      developer.log(
        'Erreur upload Drive: ${response.statusCode} $responseBody',
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
      final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}&orderBy=createdTime&pageSize=20',
      );

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
                Uri.parse(
                  'https://www.googleapis.com/drive/v3/files/$fileId',
                ),
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
