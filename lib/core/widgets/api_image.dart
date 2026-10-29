import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../network/api_client.dart';
import '../theme/app_colors.dart';

/// Loads an image stored through the backend's file service.
///
/// Stored values are either a bare `fileName` (UUID.ext) or the (broken)
/// `fileUrl` returned by the upload endpoint. The preview endpoint needs a
/// bearer token with `file:read`, so the bytes are fetched through
/// [ApiClient] and cached in memory.
class ApiImage extends StatefulWidget {
  const ApiImage({
    super.key,
    required this.source,
    required this.bucket,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.radius = 12,
  });

  final String? source;
  final String bucket;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final double radius;

  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  /// Resolve the stored value to a request path + query for the preview endpoint.
  static ({String path, Map<String, dynamic> query})? resolve(String? source, String bucket) {
    if (source == null || source.trim().isEmpty) return null;
    var value = source.trim();
    var bucketName = bucket;
    // Absolute URL from the upload response: keep the file name and any
    // bucketName query, drop the rest (the host/version prefix is unreliable).
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final uri = Uri.tryParse(value);
      if (uri == null) return null;
      if (uri.queryParameters['bucketName'] != null) {
        bucketName = uri.queryParameters['bucketName']!;
      }
      value = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
      if (value.isEmpty) return null;
    }
    return (path: '/files/preview-file/$value', query: {'bucketName': bucketName});
  }

  static Future<Uint8List?> load(String? source, String bucket) {
    final target = resolve(source, bucket);
    if (target == null) return Future.value(null);
    final key = '${target.path}?${target.query['bucketName']}';
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);
    final pending = _inFlight[key];
    if (pending != null) return pending;
    final future = ApiClient.instance.getBytes(target.path, query: target.query).then((bytes) {
      if (bytes != null && bytes.isNotEmpty) _cache[key] = bytes;
      return bytes;
    }).whenComplete(() => _inFlight.remove(key));
    _inFlight[key] = future;
    return future;
  }

  @override
  State<ApiImage> createState() => _ApiImageState();
}

class _ApiImageState extends State<ApiImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiImage.load(widget.source, widget.bucket);
  }

  @override
  void didUpdateWidget(covariant ApiImage old) {
    super.didUpdateWidget(old);
    if (old.source != widget.source || old.bucket != widget.bucket) {
      _future = ApiImage.load(widget.source, widget.bucket);
    }
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.placeholder ??
        Container(
          width: widget.width,
          height: widget.height,
          color: AppColors.neutralSoft,
          child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
        );
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: FutureBuilder<Uint8List?>(
        future: _future,
        builder: (context, snapshot) {
          final bytes = snapshot.data;
          if (bytes == null || bytes.isEmpty) return placeholder;
          return Image.memory(
            bytes,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => placeholder,
          );
        },
      ),
    );
  }
}
