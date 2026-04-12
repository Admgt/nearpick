String normalizeCategoryForFilter(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ő', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('ű', 'u');
}

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

  final normalizedSelectedCategory = normalizeCategoryForFilter(
    selectedCategory,
  );
  if (normalizedSelectedCategory ==
      normalizeCategoryForFilter(allCategoryLabel)) {
    return true;
  }

  final category = product['category'] as String? ?? '';
  return normalizeCategoryForFilter(category) == normalizedSelectedCategory;
}
