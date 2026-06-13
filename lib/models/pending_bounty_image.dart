import 'dart:typed_data';

class PendingBountyImage {
  final Uint8List bytes;
  final String name;
  final int size;
  final String contentType;

  const PendingBountyImage({
    required this.bytes,
    required this.name,
    required this.size,
    required this.contentType,
  });
}
