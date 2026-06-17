import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/pending_bounty_image.dart';

const int maxBountyImages = 3;
const int maxBountyImageBytes = 5 * 1024 * 1024;

class BountyImagePickResult {
  final List<PendingBountyImage> images;
  final String? message;

  const BountyImagePickResult({required this.images, this.message});
}

class BountyImageService {
  BountyImageService({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  static const _allowedExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif',
    'bmp',
  };

  Future<BountyImagePickResult> pickImages({
    required int remainingSlots,
  }) async {
    if (remainingSlots <= 0) {
      return const BountyImagePickResult(
        images: [],
        message: 'A bounty can contain up to 3 images',
      );
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions.toList(),
      allowMultiple: true,
      withData: true,
    );
    if (result == null) {
      return const BountyImagePickResult(images: []);
    }

    final accepted = <PendingBountyImage>[];
    var oversizedCount = 0;
    var unreadableCount = 0;

    for (final file in result.files) {
      if (accepted.length >= remainingSlots) break;
      if (file.size > maxBountyImageBytes) {
        oversizedCount++;
        continue;
      }
      final bytes = file.bytes;
      final extension = file.extension?.toLowerCase();
      if (bytes == null ||
          extension == null ||
          !_allowedExtensions.contains(extension)) {
        unreadableCount++;
        continue;
      }
      accepted.add(
        PendingBountyImage(
          bytes: bytes,
          name: file.name,
          size: file.size,
          contentType: _contentType(extension),
        ),
      );
    }

    final messages = <String>[];
    if (result.files.length > remainingSlots) {
      messages.add('Only $remainingSlots more image(s) can be added');
    }
    if (oversizedCount > 0) {
      messages.add('Images larger than 5 MB were rejected');
    }
    if (unreadableCount > 0) {
      messages.add('Some selected files could not be read');
    }

    return BountyImagePickResult(
      images: accepted,
      message: messages.isEmpty ? null : messages.join('. '),
    );
  }

  Future<List<String>> uploadImages({
    required String bountyId,
    required String userId,
    required List<PendingBountyImage> images,
  }) async {
    if (images.isEmpty) return const [];

    final client = await _readyClient();
    final storage = client.storage.from(SupabaseConfig.bucket);
    final supabaseUserId = client.auth.currentUser!.id;
    final urls = <String>[];
    try {
      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        final extension = image.name.split('.').last.toLowerCase();
        final fileName =
            '${DateTime.now().microsecondsSinceEpoch}_${index + 1}.$extension';
        final path = '$supabaseUserId/$userId/$bountyId/$fileName';
        await storage.uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            contentType: image.contentType,
            upsert: false,
          ),
        );
        urls.add(storage.getPublicUrl(path));
      }
    } catch (_) {
      await deleteUrls(urls);
      rethrow;
    }
    return urls;
  }

  Future<void> deleteUrls(Iterable<String> urls) async {
    if (!SupabaseConfig.isConfigured || urls.isEmpty) return;

    final client = await _readyClient();
    final paths = urls.map(_pathFromPublicUrl).whereType<String>().toList();
    if (paths.isEmpty) return;

    try {
      await client.storage.from(SupabaseConfig.bucket).remove(paths);
    } catch (_) {
      // A stale image URL should not prevent the bounty update from finishing.
    }
  }

  Future<SupabaseClient> _readyClient() async {
    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'Supabase is not configured. Start the app with SUPABASE_URL and '
        'SUPABASE_PUBLISHABLE_KEY dart defines.',
      );
    }

    final client = _client ?? Supabase.instance.client;
    if (client.auth.currentUser == null) {
      try {
        await client.auth.signInAnonymously();
      } on AuthException catch (error) {
        throw StateError(
          'Supabase anonymous sign-in failed: ${error.message}. Enable '
          'Anonymous Sign-Ins in Supabase Authentication settings.',
        );
      }
    }
    return client;
  }

  static String? _pathFromPublicUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final marker = ['storage', 'v1', 'object', 'public', SupabaseConfig.bucket];
    final segments = uri.pathSegments;
    for (var index = 0; index <= segments.length - marker.length; index++) {
      if (segments.sublist(index, index + marker.length).join('/') ==
          marker.join('/')) {
        final path = segments.skip(index + marker.length).join('/');
        return path.isEmpty ? null : path;
      }
    }
    return null;
  }

  static List<String> urlsFromData(Map<String, dynamic> data) {
    return (data['imageUrls'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((url) => url.isNotEmpty)
        .take(maxBountyImages)
        .toList();
  }

  static String _contentType(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'bmp' => 'image/bmp',
      _ => 'application/octet-stream',
    };
  }
}
