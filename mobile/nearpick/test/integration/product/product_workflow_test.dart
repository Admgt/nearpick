import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/product/product_workflow.dart';

import '../../test_helpers/in_memory_workflow_fakes.dart';

void main() {
  test(
    'ProductWorkflow.createProductWithOptionalImage requires auth',
    () async {
      final session = FakeProductSessionGateway();
      final repository = InMemoryProductRepository();
      final interestGateway = InMemoryInterestGateway();
      final workflow = ProductWorkflow(
        sessionGateway: session,
        productRepository: repository,
        interestGateway: interestGateway,
        imageGateway: FakeProductImageGateway(),
      );

      await expectLater(
        workflow.createProductWithOptionalImage(
          name: 'Bagel',
          category: 'Pekseg',
          originalPrice: 1000,
          discountedPrice: 500,
          quantity: 2,
          expiresAt: DateTime(2026, 3, 7),
        ),
        throwsException,
      );
    },
  );

  test(
    'ProductWorkflow.markInterest is idempotent for the same user and product',
    () async {
      final session = FakeProductSessionGateway()..currentUserId = 'consumer-1';
      final repository = InMemoryProductRepository();
      final interestGateway = InMemoryInterestGateway();
      final workflow = ProductWorkflow(
        sessionGateway: session,
        productRepository: repository,
        interestGateway: interestGateway,
        imageGateway: FakeProductImageGateway(),
      );

      final productId = await workflow.createProductWithOptionalImage(
        name: 'Bagel',
        category: 'Pekseg',
        originalPrice: 1000,
        discountedPrice: 500,
        quantity: 2,
        expiresAt: DateTime(2026, 3, 7),
        imageBytes: Uint8List.fromList(const [1, 2, 3]),
      );

      await workflow.markInterest(productId: productId);
      await workflow.markInterest(productId: productId);

      expect(repository.readInterestCount(productId), 1);
      expect(interestGateway.records, {'consumer-1::$productId'});
    },
  );
}
