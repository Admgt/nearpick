import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

abstract class ProductSessionGateway {
  String? get currentUserId;
}

abstract class ProductRepositoryGateway {
  String nextProductId();

  Future<void> saveProduct({
    required String productId,
    required Map<String, dynamic> data,
  });

  Future<void> incrementInterestCount({
    required String productId,
    required int delta,
  });

  int readInterestCount(String productId);
}

abstract class ProductInterestGateway {
  Future<bool> exists({required String userId, required String productId});

  Future<void> save({required String userId, required String productId});
}

class ProductImageUploadResult {
  final String downloadUrl;
  final String imagePath;

  const ProductImageUploadResult({
    required this.downloadUrl,
    required this.imagePath,
  });
}

abstract class ProductImageGateway {
  Future<ProductImageUploadResult> upload({
    required String ownerId,
    required String productId,
    required Uint8List imageBytes,
  });
}

class ProductWorkflow {
  final ProductSessionGateway sessionGateway;
  final ProductRepositoryGateway productRepository;
  final ProductInterestGateway interestGateway;
  final ProductImageGateway? imageGateway;

  const ProductWorkflow({
    required this.sessionGateway,
    required this.productRepository,
    required this.interestGateway,
    this.imageGateway,
  });

  Future<String> createProductWithOptionalImage({
    required String name,
    required String category,
    required int originalPrice,
    required int discountedPrice,
    required int quantity,
    required DateTime expiresAt,
    GeoPoint? location,
    Uint8List? imageBytes,
  }) async {
    final userId = sessionGateway.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final productId = productRepository.nextProductId();
    final data = <String, dynamic>{
      'ownerId': userId,
      'name': name,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'quantityAvailable': quantity,
      'expiresAt': expiresAt,
      'interestCount': 0,
      'status': 'active',
      'isDeleted': false,
      'archivedAt': null,
      'deletedAt': null,
      'hasImage': false,
    };

    if (location != null) {
      data['location'] = location;
    }

    if (imageBytes != null && imageGateway != null) {
      final upload = await imageGateway!.upload(
        ownerId: userId,
        productId: productId,
        imageBytes: imageBytes,
      );
      data['imageUrl'] = upload.downloadUrl;
      data['imagePath'] = upload.imagePath;
      data['hasImage'] = true;
    }

    await productRepository.saveProduct(productId: productId, data: data);
    return productId;
  }

  Future<void> markInterest({required String productId}) async {
    final userId = sessionGateway.currentUserId;
    if (userId == null || userId.isEmpty) {
      throw Exception('Nincs bejelentkezett felhasznalo.');
    }

    final exists = await interestGateway.exists(
      userId: userId,
      productId: productId,
    );
    if (exists) {
      return;
    }

    await interestGateway.save(userId: userId, productId: productId);
    await productRepository.incrementInterestCount(
      productId: productId,
      delta: 1,
    );
  }
}
