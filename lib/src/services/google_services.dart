import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gdrive/src/services/secure_storage.dart';
import 'package:googleapis/drive/v3.dart' as g_drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

const _scopes = [g_drive.DriveApi.driveScope];

class GoogleDriveService {
  final secureStorage = SecureStorage();

  Future<http.Client> getHttpClient() async {
    final credential = await secureStorage.getCredentials();
    if (credential == null) {
      final serviceAccountCredential = ServiceAccountCredentials(
        "SERVICE_EMAIL",
        ClientId.serviceAccount("SERVICE_CLIENT_ID"),
        "PRIVATE_KEY",
      );
      final authClient =
          await clientViaServiceAccount(serviceAccountCredential, _scopes);
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

  Future upload(File file) async {
    final client = await getHttpClient();
    final drive = g_drive.DriveApi(client);
    debugPrint("Uploading file");
    final streamedFile = file.openRead();
    final response = await drive.files.create(
      g_drive.File(
        name: p.basename(file.path),
        parents: ["FOLDER_ID"],
      ),
      uploadMedia: g_drive.Media(streamedFile, file.lengthSync()),
      supportsAllDrives: true,
      supportsTeamDrives: true,
    );
    debugPrint("Result ${response.toJson()}");
  }
}
