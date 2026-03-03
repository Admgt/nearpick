import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageImage extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final int maxSizeBytes;

  const StorageImage({
    super.key,
    required this.imagePath,
    required this.width,
    required this.height,
    this.borderRadius = 0,
    this.fit = BoxFit.cover,
    this.maxSizeBytes = 1024 * 1024,
  });

  @override
  State<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends State<StorageImage> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.maxSizeBytes != widget.maxSizeBytes) {
      _future = _load();
    }
  }

  Future<Uint8List?> _load() {
    return FirebaseStorage.instance
        .ref(widget.imagePath)
        .getData(widget.maxSizeBytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        Widget content;
        if (snapshot.connectionState == ConnectionState.waiting) {
          content = const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (snapshot.hasData) {
          content = Image.memory(
            snapshot.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          );
        } else {
          content = const Icon(Icons.image_not_supported);
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            width: widget.width,
            height: widget.height,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: content,
          ),
        );
      },
    );
  }
}
