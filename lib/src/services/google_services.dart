import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gdrive/src/services/secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as g_drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

const _clientID =
    '375464346507-j2clgn6au259bnvjc9lgphfijjuh1pom.apps.googleusercontent.com';
// const _clientSecret = '3U6ignn3dsH5H9UuMPXgptFb';
const _scopes = [g_drive.DriveApi.driveFileScope];

class GoogleDriveService {
  final secureStorage = SecureStorage();

  Future<http.Client> getHttpClient() async {
    final credential = await secureStorage.getCredentials();
    if (credential == null) {
      final authClient =
          await clientViaUserConsent(ClientId(_clientID, null), _scopes, (url) {
        launch(url);
      });
      await secureStorage.saveCredentials(
        authClient.credentials.accessToken,
        authClient.credentials.refreshToken!,
      );
      return authClient;
    } else {
      debugPrint(credential["expiry"].toString());
      return authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            credential["type"].toString(),
            credential["data"].toString(),
            DateTime.tryParse(credential["expiry"].toString())!,
          ),
          credential["refreshToken"].toString(),
          _scopes,
        ),
      );
    }
  }

  Future upload(PlatformFile file) async {
    final client = await getHttpClient();
    final drive = g_drive.DriveApi(client);
    debugPrint("Uploading file");
    final response = await drive.files.create(
      g_drive.File()..name = p.basename(file.path),
      uploadMedia: g_drive.Media(file.readStream!, file.size),
    );

    debugPrint("Result ${response.toJson()}");
  }
}
