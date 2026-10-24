import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class GitHubSettings {
  const GitHubSettings({
    required this.owner,
    required this.repository,
    required this.token,
  });

  final String owner;
  final String repository;
  final String token;

  bool get isComplete =>
      owner.trim().isNotEmpty &&
      repository.trim().isNotEmpty &&
      token.trim().isNotEmpty;
}

class GitHubConnectionResult {
  const GitHubConnectionResult({
    required this.success,
    required this.message,
    this.repositoryFullName,
    this.isPrivate,
  });

  final bool success;
  final String message;
  final String? repositoryFullName;
  final bool? isPrivate;
}



class GitHubFileUpdateResult {
  const GitHubFileUpdateResult({
    required this.success,
    required this.message,
    this.commitSha,
    this.fileUrl,
  });

  final bool success;
  final String message;
  final String? commitSha;
  final String? fileUrl;
}

class GitHubReleaseCreateResult {
  const GitHubReleaseCreateResult({
    required this.success,
    required this.message,
    this.releaseUrl,
    this.releaseId,
    this.tagName,
    this.alreadyExists = false,
  });

  final bool success;
  final String message;
  final String? releaseUrl;
  final int? releaseId;
  final String? tagName;
  final bool alreadyExists;
}


class GitHubAssetUploadResult {
  const GitHubAssetUploadResult({
    required this.success,
    required this.message,
    this.assetUrl,
    this.assetName,
    this.alreadyExists = false,
  });

  final bool success;
  final String message;
  final String? assetUrl;
  final String? assetName;
  final bool alreadyExists;
}


class GitHubPublicationVerificationResult {
  const GitHubPublicationVerificationResult({
    required this.versionJsonReady,
    required this.releaseReady,
    required this.assetReady,
    required this.message,
    this.releaseUrl,
    this.assetUrl,
  });

  final bool versionJsonReady;
  final bool releaseReady;
  final bool assetReady;
  final String message;
  final String? releaseUrl;
  final String? assetUrl;

  bool get success => versionJsonReady && releaseReady && assetReady;
}

class GitHubSettingsService {
  const GitHubSettingsService();

  File get _settingsFile {
    final appData = Platform.environment['APPDATA'];
    final base = appData == null || appData.trim().isEmpty
        ? Directory.systemTemp.path
        : appData;
    return File(path.join(
      base,
      'STAVBY_PRO_RELEASE_MANAGER',
      'github_settings.json',
    ));
  }

  Future<GitHubSettings?> load() async {
    final file = _settingsFile;
    if (!await file.exists()) return null;

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map) return null;
    final data = Map<String, dynamic>.from(decoded);
    final encryptedToken = data['encryptedToken']?.toString() ?? '';
    final token = encryptedToken.isEmpty
        ? ''
        : await _runDpapi(encryptedToken, decrypt: true);

    return GitHubSettings(
      owner: data['owner']?.toString() ?? '',
      repository: data['repository']?.toString() ?? '',
      token: token,
    );
  }

  Future<void> save(GitHubSettings settings) async {
    final file = _settingsFile;
    await file.parent.create(recursive: true);
    final encryptedToken = await _runDpapi(settings.token, decrypt: false);
    final data = <String, dynamic>{
      'owner': settings.owner.trim(),
      'repository': settings.repository.trim(),
      'encryptedToken': encryptedToken,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await file.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(data)}\n',
      flush: true,
    );
  }

  Future<void> clear() async {
    final file = _settingsFile;
    if (await file.exists()) await file.delete();
  }

  Future<String> _runDpapi(String value, {required bool decrypt}) async {
    if (!Platform.isWindows) {
      throw UnsupportedError(
        'Bezpečné uloženie GitHub tokenu je podporované iba vo Windows.',
      );
    }

    final command = decrypt
        ? r'''$encrypted=[Console]::In.ReadToEnd(); $secure=ConvertTo-SecureString $encrypted; $ptr=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure); try {[Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)} finally {[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)}'''
        : r'''$value=[Console]::In.ReadToEnd(); ConvertTo-SecureString $value -AsPlainText -Force | ConvertFrom-SecureString''';

    final process = await Process.start(
      'powershell.exe',
      <String>['-NoProfile', '-NonInteractive', '-Command', command],
      runInShell: false,
    );
    process.stdin.write(value);
    await process.stdin.close();
    final output = await process.stdout.transform(utf8.decoder).join();
    final error = await process.stderr.transform(utf8.decoder).join();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw FileSystemException(
        'Windows nedokázal bezpečne spracovať GitHub token.',
        error.trim(),
      );
    }
    return output.trim();
  }

  Future<GitHubConnectionResult> testConnection(
    GitHubSettings settings,
  ) async {
    if (!settings.isComplete) {
      return const GitHubConnectionResult(
        success: false,
        message: 'Vyplň vlastníka, repozitár aj prístupový token.',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final uri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}',
      );
      final request = await client.getUrl(uri);
      _applyGitHubHeaders(request, settings.token);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      Map<String, dynamic> json = <String, dynamic>{};
      if (body.trim().isNotEmpty) {
        final decoded = jsonDecode(body);
        if (decoded is Map) json = Map<String, dynamic>.from(decoded);
      }

      if (response.statusCode == HttpStatus.ok) {
        final fullName = json['full_name']?.toString() ??
            '${settings.owner.trim()}/${settings.repository.trim()}';
        return GitHubConnectionResult(
          success: true,
          message: 'Pripojenie je funkčné a repozitár je dostupný.',
          repositoryFullName: fullName,
          isPrivate: json['private'] == true,
        );
      }
      if (response.statusCode == HttpStatus.unauthorized) {
        return const GitHubConnectionResult(
          success: false,
          message: 'Token je neplatný, expirovaný alebo nebol prijatý.',
        );
      }
      if (response.statusCode == HttpStatus.forbidden) {
        return const GitHubConnectionResult(
          success: false,
          message: 'GitHub odmietol prístup. Skontroluj oprávnenia tokenu.',
        );
      }
      if (response.statusCode == HttpStatus.notFound) {
        return const GitHubConnectionResult(
          success: false,
          message: 'Repozitár neexistuje alebo k nemu token nemá prístup.',
        );
      }
      return GitHubConnectionResult(
        success: false,
        message: 'GitHub vrátil chybu HTTP ${response.statusCode}.',
      );
    } on SocketException {
      return const GitHubConnectionResult(
        success: false,
        message: 'Nepodarilo sa pripojiť na internet alebo GitHub.',
      );
    } on HandshakeException {
      return const GitHubConnectionResult(
        success: false,
        message: 'Zlyhalo zabezpečené HTTPS spojenie s GitHubom.',
      );
    } on FormatException {
      return const GitHubConnectionResult(
        success: false,
        message: 'GitHub vrátil neočakávanú odpoveď.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<GitHubFileUpdateResult> updateVersionJson({
    required GitHubSettings settings,
    required String jsonContent,
  }) async {
    if (!settings.isComplete) {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'GitHub pripojenie nie je úplne nastavené.',
      );
    }

    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return const GitHubFileUpdateResult(
          success: false,
          message: 'Obsah version.json nie je platný JSON objekt.',
        );
      }
    } on FormatException {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'Obsah version.json nie je platný JSON.',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final fileUri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}/contents/version.json',
      );

      String? existingSha;
      final getRequest = await client.getUrl(fileUri);
      _applyGitHubHeaders(getRequest, settings.token);
      final getResponse = await getRequest.close();
      final getBody = await getResponse.transform(utf8.decoder).join();

      if (getResponse.statusCode == HttpStatus.ok) {
        final decoded = jsonDecode(getBody);
        if (decoded is Map) {
          existingSha = decoded['sha']?.toString();
        }
        if (existingSha == null || existingSha.isEmpty) {
          return const GitHubFileUpdateResult(
            success: false,
            message: 'GitHub nevrátil SHA existujúceho súboru version.json.',
          );
        }
      } else if (getResponse.statusCode != HttpStatus.notFound) {
        return _fileUpdateHttpError(getResponse.statusCode, getBody);
      }

      final putRequest = await client.putUrl(fileUri);
      _applyGitHubHeaders(putRequest, settings.token);
      putRequest.headers.contentType = ContentType.json;
      final payload = <String, Object>{
        'message': 'Aktualizácia version.json cez STAVBY PRO Release Manager',
        'content': base64Encode(utf8.encode('$jsonContent\n')),
        if (existingSha != null) 'sha': existingSha,
      };
      putRequest.write(jsonEncode(payload));
      final putResponse = await putRequest.close();
      final putBody = await putResponse.transform(utf8.decoder).join();

      if (putResponse.statusCode == HttpStatus.ok ||
          putResponse.statusCode == HttpStatus.created) {
        final decoded = jsonDecode(putBody);
        final data = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
        final commit = data['commit'];
        final content = data['content'];
        return GitHubFileUpdateResult(
          success: true,
          message: existingSha == null
              ? 'version.json bol na GitHube vytvorený.'
              : 'version.json bol na GitHube úspešne aktualizovaný.',
          commitSha: commit is Map ? commit['sha']?.toString() : null,
          fileUrl: content is Map ? content['html_url']?.toString() : null,
        );
      }
      return _fileUpdateHttpError(putResponse.statusCode, putBody);
    } on SocketException {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'Nepodarilo sa pripojiť na internet alebo GitHub.',
      );
    } on HandshakeException {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'Zlyhalo zabezpečené HTTPS spojenie s GitHubom.',
      );
    } on FormatException {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'GitHub vrátil neočakávanú odpoveď.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<GitHubReleaseCreateResult> createRelease({
    required GitHubSettings settings,
    required String tagName,
    required String releaseName,
    required String body,
  }) async {
    if (!settings.isComplete) {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'GitHub pripojenie nie je úplne nastavené.',
      );
    }
    if (tagName.trim().isEmpty || releaseName.trim().isEmpty) {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'Tag a názov GitHub Release nesmú byť prázdne.',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    try {
      final encodedTag = Uri.encodeComponent(tagName.trim());
      final existingUri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}/releases/tags/$encodedTag',
      );
      final existingRequest = await client.getUrl(existingUri);
      _applyGitHubHeaders(existingRequest, settings.token);
      final existingResponse = await existingRequest.close();
      final existingBody =
          await existingResponse.transform(utf8.decoder).join();

      if (existingResponse.statusCode == HttpStatus.ok) {
        String? url;
        try {
          final decoded = jsonDecode(existingBody);
          if (decoded is Map) url = decoded['html_url']?.toString();
        } catch (_) {
          // Existencia Release je potvrdená aj bez spracovania tela.
        }
        return GitHubReleaseCreateResult(
          success: false,
          message: 'GitHub Release pre tag ${tagName.trim()} už existuje.',
          releaseUrl: url,
          tagName: tagName.trim(),
          alreadyExists: true,
        );
      }
      if (existingResponse.statusCode != HttpStatus.notFound) {
        return _releaseHttpError(
          existingResponse.statusCode,
          existingBody,
        );
      }

      final createUri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}/releases',
      );
      final request = await client.postUrl(createUri);
      _applyGitHubHeaders(request, settings.token);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(<String, Object>{
        'tag_name': tagName.trim(),
        'name': releaseName.trim(),
        'body': body,
        'draft': false,
        'prerelease': false,
        'generate_release_notes': false,
      }));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode == HttpStatus.created) {
        final decoded = jsonDecode(responseBody);
        final data = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};
        return GitHubReleaseCreateResult(
          success: true,
          message: 'GitHub Release bol úspešne vytvorený.',
          releaseUrl: data['html_url']?.toString(),
          releaseId: data['id'] is int ? data['id'] as int : null,
          tagName: data['tag_name']?.toString() ?? tagName.trim(),
        );
      }
      return _releaseHttpError(response.statusCode, responseBody);
    } on SocketException {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'Nepodarilo sa pripojiť na internet alebo GitHub.',
      );
    } on HandshakeException {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'Zlyhalo zabezpečené HTTPS spojenie s GitHubom.',
      );
    } on FormatException {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'GitHub vrátil neočakávanú odpoveď.',
      );
    } finally {
      client.close(force: true);
    }
  }



  Future<GitHubPublicationVerificationResult> verifyPublishedRelease({
    required GitHubSettings settings,
    required String tagName,
    required String assetName,
    required String expectedVersionJson,
    required int expectedAssetSize,
  }) async {
    if (!settings.isComplete) {
      return const GitHubPublicationVerificationResult(
        versionJsonReady: false,
        releaseReady: false,
        assetReady: false,
        message: 'GitHub pripojenie nie je úplne nastavené.',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    var versionJsonReady = false;
    var releaseReady = false;
    var assetReady = false;
    String? releaseUrl;
    String? assetUrl;
    try {
      final expectedDecoded = jsonDecode(expectedVersionJson);
      if (expectedDecoded is! Map) {
        throw const FormatException('Očakávaný version.json nie je JSON objekt.');
      }
      final expected = Map<String, dynamic>.from(expectedDecoded);

      final fileUri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}/contents/version.json',
      );
      final fileRequest = await client.getUrl(fileUri);
      _applyGitHubHeaders(fileRequest, settings.token);
      final fileResponse = await fileRequest.close();
      final fileBody = await fileResponse.transform(utf8.decoder).join();
      if (fileResponse.statusCode == HttpStatus.ok) {
        final decoded = jsonDecode(fileBody);
        if (decoded is Map) {
          final encodedContent = decoded['content']?.toString().replaceAll('\n', '') ?? '';
          if (encodedContent.isNotEmpty) {
            final onlineDecoded = jsonDecode(utf8.decode(base64Decode(encodedContent)));
            if (onlineDecoded is Map) {
              final online = Map<String, dynamic>.from(onlineDecoded);
              const keys = <String>['channel', 'version', 'build', 'apkUrl', 'sizeBytes', 'sha256'];
              versionJsonReady = keys.every((key) => online[key] == expected[key]);
            }
          }
        }
      }

      final encodedTag = Uri.encodeComponent(tagName.trim());
      final releaseUri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}/releases/tags/$encodedTag',
      );
      final releaseRequest = await client.getUrl(releaseUri);
      _applyGitHubHeaders(releaseRequest, settings.token);
      final releaseResponse = await releaseRequest.close();
      final releaseBody = await releaseResponse.transform(utf8.decoder).join();
      if (releaseResponse.statusCode == HttpStatus.ok) {
        final decoded = jsonDecode(releaseBody);
        if (decoded is Map) {
          final data = Map<String, dynamic>.from(decoded);
          releaseReady = data['tag_name']?.toString() == tagName &&
              data['draft'] != true &&
              data['prerelease'] != true;
          releaseUrl = data['html_url']?.toString();
          final assets = data['assets'];
          if (assets is List) {
            for (final item in assets) {
              if (item is! Map) continue;
              final asset = Map<String, dynamic>.from(item);
              if (asset['name']?.toString() != assetName) continue;
              final size = asset['size'];
              assetUrl = asset['browser_download_url']?.toString();
              assetReady = size is int &&
                  size == expectedAssetSize &&
                  assetUrl != null &&
                  assetUrl!.isNotEmpty;
              break;
            }
          }
        }
      }

      final message = versionJsonReady && releaseReady && assetReady
          ? 'Online publikovanie bolo overené: version.json, GitHub Release aj APK sú pripravené.'
          : 'Online verifikácia nie je kompletná: version.json=${versionJsonReady ? 'OK' : 'CHÝBA/NESÚHLASÍ'}, '
              'Release=${releaseReady ? 'OK' : 'CHÝBA/NESÚHLASÍ'}, APK=${assetReady ? 'OK' : 'CHÝBA/NESÚHLASÍ'}.';
      return GitHubPublicationVerificationResult(
        versionJsonReady: versionJsonReady,
        releaseReady: releaseReady,
        assetReady: assetReady,
        message: message,
        releaseUrl: releaseUrl,
        assetUrl: assetUrl,
      );
    } on SocketException {
      return GitHubPublicationVerificationResult(
        versionJsonReady: versionJsonReady,
        releaseReady: releaseReady,
        assetReady: assetReady,
        message: 'Online verifikácia zlyhala: nie je dostupné internetové spojenie alebo GitHub.',
        releaseUrl: releaseUrl,
        assetUrl: assetUrl,
      );
    } on HandshakeException {
      return GitHubPublicationVerificationResult(
        versionJsonReady: versionJsonReady,
        releaseReady: releaseReady,
        assetReady: assetReady,
        message: 'Online verifikácia zlyhala na HTTPS spojení s GitHubom.',
        releaseUrl: releaseUrl,
        assetUrl: assetUrl,
      );
    } on FormatException {
      return GitHubPublicationVerificationResult(
        versionJsonReady: versionJsonReady,
        releaseReady: releaseReady,
        assetReady: assetReady,
        message: 'Online verifikácia dostala neočakávanú odpoveď z GitHubu.',
        releaseUrl: releaseUrl,
        assetUrl: assetUrl,
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<GitHubAssetUploadResult> uploadReleaseAsset({
    required GitHubSettings settings,
    required String tagName,
    required File file,
    void Function(int sentBytes, int totalBytes)? onProgress,
    bool overwriteExisting = false,
    String? assetName,
  }) async {
    if (!settings.isComplete) {
      return const GitHubAssetUploadResult(
        success: false,
        message: 'GitHub pripojenie nie je úplne nastavené.',
      );
    }
    if (!await file.exists()) {
      return const GitHubAssetUploadResult(
        success: false,
        message: 'Vybraný súbor sa nenašiel.',
      );
    }

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final encodedTag = Uri.encodeComponent(tagName.trim());
      final releaseUri = Uri.https(
        'api.github.com',
        '/repos/${settings.owner.trim()}/${settings.repository.trim()}/releases/tags/$encodedTag',
      );
      final releaseRequest = await client.getUrl(releaseUri);
      _applyGitHubHeaders(releaseRequest, settings.token);
      final releaseResponse = await releaseRequest.close();
      final releaseBody = await releaseResponse.transform(utf8.decoder).join();
      if (releaseResponse.statusCode != HttpStatus.ok) {
        if (releaseResponse.statusCode == HttpStatus.notFound) {
          return GitHubAssetUploadResult(
            success: false,
            message: 'GitHub Release pre tag ${tagName.trim()} neexistuje. Najprv ho vytvor.',
          );
        }
        final error = _releaseHttpError(releaseResponse.statusCode, releaseBody);
        return GitHubAssetUploadResult(success: false, message: error.message);
      }

      final decoded = jsonDecode(releaseBody);
      final data = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
      final uploadTemplate = data['upload_url']?.toString() ?? '';
      if (uploadTemplate.isEmpty) {
        return const GitHubAssetUploadResult(
          success: false,
          message: 'GitHub neposkytol adresu na nahratie súboru.',
        );
      }

      final resolvedAssetName = (assetName == null || assetName.trim().isEmpty)
          ? path.basename(file.path)
          : path.basename(assetName.trim());
      final assets = data['assets'];
      Map<dynamic, dynamic>? existingAsset;
      if (assets is List) {
        for (final asset in assets) {
          if (asset is Map && asset['name']?.toString() == resolvedAssetName) {
            existingAsset = asset;
            break;
          }
        }
      }

      if (existingAsset != null && !overwriteExisting) {
        return GitHubAssetUploadResult(
          success: false,
          message: 'Súbor s názvom $resolvedAssetName už v tomto Release existuje.',
          assetUrl: existingAsset['browser_download_url']?.toString(),
          assetName: resolvedAssetName,
          alreadyExists: true,
        );
      }

      if (existingAsset != null && overwriteExisting) {
        final assetId = existingAsset['id'];
        if (assetId == null) {
          return const GitHubAssetUploadResult(
            success: false,
            message: 'Existujúci súbor sa nepodarilo identifikovať na odstránenie.',
          );
        }
        final deleteUri = Uri.https(
          'api.github.com',
          '/repos/${settings.owner.trim()}/${settings.repository.trim()}/releases/assets/$assetId',
        );
        final deleteRequest = await client.deleteUrl(deleteUri);
        _applyGitHubHeaders(deleteRequest, settings.token);
        final deleteResponse = await deleteRequest.close();
        final deleteBody = await deleteResponse.transform(utf8.decoder).join();
        if (deleteResponse.statusCode != HttpStatus.noContent) {
          final error = _releaseHttpError(deleteResponse.statusCode, deleteBody);
          return GitHubAssetUploadResult(
            success: false,
            message: 'Starý súbor sa nepodarilo odstrániť: ${error.message}',
          );
        }
      }

      final baseUploadUrl = uploadTemplate.split('{').first;
      final uploadUri = Uri.parse(baseUploadUrl).replace(
        queryParameters: <String, String>{'name': resolvedAssetName},
      );
      final request = await client.postUrl(uploadUri);
      _applyGitHubHeaders(request, settings.token);
      request.headers.contentType = resolvedAssetName.toLowerCase().endsWith('.zip')
          ? ContentType('application', 'zip')
          : ContentType('application', 'vnd.android.package-archive');
      final totalBytes = await file.length();
      request.contentLength = totalBytes;
      var sentBytes = 0;
      onProgress?.call(sentBytes, totalBytes);
      await for (final chunk in file.openRead()) {
        request.add(chunk);
        sentBytes += chunk.length;
        onProgress?.call(sentBytes, totalBytes);
      }
      await request.flush();

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      if (response.statusCode == HttpStatus.created) {
        final responseDecoded = jsonDecode(responseBody);
        final responseData = responseDecoded is Map
            ? Map<String, dynamic>.from(responseDecoded)
            : <String, dynamic>{};
        return GitHubAssetUploadResult(
          success: true,
          message: 'Súbor bol úspešne nahraný do GitHub Release.',
          assetUrl: responseData['browser_download_url']?.toString(),
          assetName: responseData['name']?.toString() ?? resolvedAssetName,
        );
      }
      if (response.statusCode == 422) {
        return GitHubAssetUploadResult(
          success: false,
          message: 'GitHub odmietol súbor. Súbor s rovnakým názvom už môže existovať.',
        );
      }
      final error = _releaseHttpError(response.statusCode, responseBody);
      return GitHubAssetUploadResult(success: false, message: error.message);
    } on SocketException {
      return const GitHubAssetUploadResult(
        success: false,
        message: 'Nepodarilo sa pripojiť na internet alebo GitHub.',
      );
    } on HandshakeException {
      return const GitHubAssetUploadResult(
        success: false,
        message: 'Zlyhalo zabezpečené HTTPS spojenie s GitHubom.',
      );
    } on FormatException {
      return const GitHubAssetUploadResult(
        success: false,
        message: 'GitHub vrátil neočakávanú odpoveď.',
      );
    } finally {
      client.close(force: true);
    }
  }

  GitHubReleaseCreateResult _releaseHttpError(int statusCode, String body) {
    String? apiMessage;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) apiMessage = decoded['message']?.toString();
    } catch (_) {
      // HTTP stav je dostatočný aj pri neplatnom tele odpovede.
    }

    if (statusCode == HttpStatus.unauthorized) {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'Token je neplatný alebo expirovaný.',
      );
    }
    if (statusCode == HttpStatus.forbidden) {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'GitHub odmietol vytvorenie Release. Skontroluj oprávnenie Contents: Read and write.',
      );
    }
    if (statusCode == HttpStatus.notFound) {
      return const GitHubReleaseCreateResult(
        success: false,
        message: 'Repozitár sa nenašiel alebo token k nemu nemá prístup.',
      );
    }
    if (statusCode == HttpStatus.conflict || statusCode == 422) {
      return GitHubReleaseCreateResult(
        success: false,
        message: 'GitHub odmietol vytvorenie Release pre konflikt alebo neplatné údaje${apiMessage == null ? '.' : ': $apiMessage'}',
      );
    }
    return GitHubReleaseCreateResult(
      success: false,
      message: 'GitHub vrátil chybu HTTP $statusCode${apiMessage == null ? '.' : ': $apiMessage'}',
    );
  }

  void _applyGitHubHeaders(HttpClientRequest request, String token) {
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${token.trim()}');
    request.headers.set(HttpHeaders.userAgentHeader, 'STAVBY-PRO-Release-Manager');
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
  }

  GitHubFileUpdateResult _fileUpdateHttpError(int statusCode, String body) {
    String? apiMessage;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) apiMessage = decoded['message']?.toString();
    } catch (_) {
      // HTTP stav je dostatočný aj pri neplatnom tele odpovede.
    }

    if (statusCode == HttpStatus.unauthorized) {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'Token je neplatný alebo expirovaný.',
      );
    }
    if (statusCode == HttpStatus.forbidden) {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'GitHub odmietol zápis. Token musí mať pre tento repozitár oprávnenie Contents: Read and write.',
      );
    }
    if (statusCode == HttpStatus.notFound) {
      return const GitHubFileUpdateResult(
        success: false,
        message: 'Repozitár sa nenašiel alebo token k nemu nemá prístup.',
      );
    }
    if (statusCode == HttpStatus.conflict || statusCode == 422) {
      return GitHubFileUpdateResult(
        success: false,
        message: 'GitHub odmietol aktualizáciu pre konflikt alebo neplatné údaje${apiMessage == null ? '.' : ': $apiMessage'}',
      );
    }
    return GitHubFileUpdateResult(
      success: false,
      message: 'GitHub vrátil chybu HTTP $statusCode${apiMessage == null ? '.' : ': $apiMessage'}',
    );
  }

}
