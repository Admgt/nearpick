import 'package:flutter/material.dart';

import '../../models/app_user_profile.dart';
import '../../models/merchant_stats_summary.dart';
import '../../models/product.dart';
import '../../models/reservation.dart';
import '../../utils/date_time_formatters.dart';

enum AdminSection {
  dashboard,
  users,
  merchants,
  customers,
  products,
  reservations,
}

extension AdminSectionPresentation on AdminSection {
  String get label {
    switch (this) {
      case AdminSection.dashboard:
        return 'Dashboard';
      case AdminSection.users:
        return 'Felhasznalok';
      case AdminSection.merchants:
        return 'Kereskedok';
      case AdminSection.customers:
        return 'Vasarlok';
      case AdminSection.products:
        return 'Termekek';
      case AdminSection.reservations:
        return 'Foglalasok';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminSection.dashboard:
        return Icons.dashboard_outlined;
      case AdminSection.users:
        return Icons.groups_outlined;
      case AdminSection.merchants:
        return Icons.storefront_outlined;
      case AdminSection.customers:
        return Icons.shopping_bag_outlined;
      case AdminSection.products:
        return Icons.inventory_2_outlined;
      case AdminSection.reservations:
        return Icons.assignment_outlined;
    }
  }
}

String roleLabel(String role) {
  switch (role) {
    case 'admin':
      return 'Admin';
    case 'merchant':
      return 'Kereskedo';
    default:
      return 'Vasarlo';
  }
}

String accountStatusLabel(String accountStatus) {
  switch (accountStatus) {
    case 'blocked':
      return 'Tiltott';
    case 'suspended':
      return 'Felfuggesztett';
    default:
      return 'Aktiv';
  }
}

Color accountStatusColor(BuildContext context, String accountStatus) {
  final scheme = Theme.of(context).colorScheme;
  switch (accountStatus) {
    case 'blocked':
      return scheme.error;
    case 'suspended':
      return scheme.secondary;
    default:
      return scheme.primary;
  }
}

String productStatusLabel(Product product) {
  switch (product.effectiveStatus) {
    case 'hidden':
      return 'Elrejtve';
    case 'archived':
      return 'Archivalt';
    case 'expired':
      return 'Lejart';
    case 'sold_out':
      return 'Elfogyott';
    default:
      return 'Aktiv';
  }
}

Color productStatusColor(BuildContext context, Product product) {
  final scheme = Theme.of(context).colorScheme;
  switch (product.effectiveStatus) {
    case 'hidden':
      return scheme.secondary;
    case 'archived':
      return scheme.error;
    case 'expired':
      return scheme.outline;
    case 'sold_out':
      return scheme.tertiary;
    default:
      return scheme.primary;
  }
}

String reservationStatusLabel(Reservation reservation) {
  switch (reservation.status) {
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Lemondott';
    case 'expired':
      return 'Lejart';
    default:
      return 'Foglalva';
  }
}

Color reservationStatusColor(BuildContext context, Reservation reservation) {
  final scheme = Theme.of(context).colorScheme;
  switch (reservation.status) {
    case 'completed':
      return scheme.primary;
    case 'cancelled':
      return scheme.error;
    case 'expired':
      return scheme.outline;
    default:
      return scheme.secondary;
  }
}

String userSubtitle(AppUserProfile user) {
  final parts = <String>[];
  if (user.email.isNotEmpty) {
    parts.add(user.email);
  }
  if (user.companyName.isNotEmpty && !user.isConsumer) {
    parts.add(user.companyName);
  }
  if (user.createdAt != null) {
    parts.add('Regisztralt: ${formatDateTime(user.createdAt!)}');
  }
  return parts.join(' | ');
}

String productMerchantLabel({
  required Product product,
  required Map<String, AppUserProfile> usersById,
}) {
  final merchant = usersById[product.ownerId];
  if (merchant == null) {
    return product.merchantName.isNotEmpty
        ? product.merchantName
        : product.ownerId;
  }
  return merchant.primaryLabel;
}

String reservationBuyerLabel({
  required Reservation reservation,
  required Map<String, AppUserProfile> usersById,
}) {
  final buyer = usersById[reservation.buyerId];
  return buyer?.primaryLabel ?? reservation.buyerId;
}

String reservationMerchantLabel({
  required Reservation reservation,
  required Map<String, AppUserProfile> usersById,
}) {
  final merchant = usersById[reservation.merchantId];
  if (merchant != null) {
    return merchant.primaryLabel;
  }
  return reservation.merchantName.isNotEmpty
      ? reservation.merchantName
      : reservation.merchantId;
}

String reservationProductLabel({
  required Reservation reservation,
  required Map<String, Product> productsById,
}) {
  final product = productsById[reservation.productId];
  if (product != null && product.name.isNotEmpty) {
    return product.name;
  }
  return reservation.productSnapshot['name'] as String? ??
      reservation.productId;
}

String merchantRatingLabel(MerchantStatsSummary? stats) {
  if (stats == null || stats.reviewCount == 0) {
    return '-';
  }

  return '${stats.averageRating.toStringAsFixed(1)} / 5';
}

String adminMessageTopicLabel(String topic) {
  switch (topic) {
    case 'rating':
      return 'Rating';
    case 'moderation':
      return 'Moderacio';
    default:
      return 'Altalanos';
  }
}
