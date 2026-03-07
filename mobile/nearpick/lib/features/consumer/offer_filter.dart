bool shouldIncludeOffer({
  required String productId,
  required Map<String, dynamic> product,
  required Set<String> dismissedProductIds,
  required String selectedCategory,
  required String allCategoryLabel,
}) {
  if (dismissedProductIds.contains(productId)) {
    return false;
  }

  final isDeleted = product['isDeleted'] == true;
  final status = product['status'] as String?;
  if (isDeleted || (status != null && status != 'active')) {
    return false;
  }

  final quantityAvailable =
      product['quantityAvailable'] as int? ?? product['quantity'] as int? ?? 0;
  if (quantityAvailable <= 0) {
    return false;
  }

  if (selectedCategory == allCategoryLabel) {
    return true;
  }

  final category = product['category'] as String? ?? '';
  return category == selectedCategory;
}
