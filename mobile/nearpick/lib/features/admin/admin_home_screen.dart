import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/admin_dashboard_stats.dart';
import '../../models/app_user_profile.dart';
import '../../models/merchant_stats_summary.dart';
import '../../models/product.dart';
import '../../models/reservation.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import 'admin_product_detail_screen.dart';
import 'admin_reservation_detail_screen.dart';
import 'admin_support.dart';
import 'admin_user_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AdminService _adminService = AdminService();

  AdminSection _section = AdminSection.dashboard;
  String _userQuery = '';
  String _merchantQuery = '';
  String _customerQuery = '';
  String _productQuery = '';
  String _reservationQuery = '';
  String _productStatusFilter = 'all';
  String _reservationStatusFilter = 'all';

  void _openSection(AdminSection section) {
    setState(() => _section = section);
  }

  bool _matchesQuery(Iterable<String> values, String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return true;
    }
    return values.any((value) => value.toLowerCase().contains(normalizedQuery));
  }

  Future<void> _openUserDetail({
    required AppUserProfile user,
    required List<Product> products,
    required List<Reservation> reservations,
    required Map<String, Product> productsById,
    required Map<String, AppUserProfile> usersById,
    required MerchantStatsSummary? merchantStats,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(
          user: user,
          products: products,
          reservations: reservations,
          productsById: productsById,
          usersById: usersById,
          merchantStats: merchantStats,
          adminService: _adminService,
        ),
      ),
    );
  }

  Future<void> _openProductDetail({
    required Product product,
    required Map<String, AppUserProfile> usersById,
    required List<Reservation> reservations,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminProductDetailScreen(
          product: product,
          merchant: usersById[product.ownerId],
          reservations: reservations
              .where((reservation) => reservation.productId == product.id)
              .toList(),
          adminService: _adminService,
        ),
      ),
    );
  }

  Future<void> _openReservationDetail({
    required Reservation reservation,
    required Map<String, Product> productsById,
    required Map<String, AppUserProfile> usersById,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminReservationDetailScreen(
          reservation: reservation,
          product: productsById[reservation.productId],
          buyer: usersById[reservation.buyerId],
          merchant: usersById[reservation.merchantId],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    Color? tint,
  }) {
    final color = tint ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: 220,
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard({
    required BuildContext context,
    required AdminDashboardStats stats,
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
  }) {
    final hiddenProducts = products
        .where(
          (product) =>
              !product.isDeleted && product.effectiveStatus == 'hidden',
        )
        .length;
    final restrictedUsers = users
        .where((user) => user.accountStatus != 'active')
        .length;
    final cancelledReservations = reservations
        .where((reservation) => reservation.status == 'cancelled')
        .length;

    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'A NearPick teljes rendszerallapota egy helyen: felhasznalok, termekek, foglalasok es moderacios kockazatok.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    context: context,
                    title: 'Osszes felhasznalo',
                    value: '${stats.userCount}',
                    icon: Icons.groups_outlined,
                  ),
                  _buildMetricCard(
                    context: context,
                    title: 'Kereskedok',
                    value: '${stats.merchantCount}',
                    icon: Icons.storefront_outlined,
                  ),
                  _buildMetricCard(
                    context: context,
                    title: 'Vasarlok',
                    value: '${stats.customerCount}',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _buildMetricCard(
                    context: context,
                    title: 'Aktiv termekek',
                    value: '${stats.activeProductCount}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _buildMetricCard(
                    context: context,
                    title: 'Osszes foglalas',
                    value: '${stats.reservationCount}',
                    icon: Icons.assignment_outlined,
                  ),
                  _buildMetricCard(
                    context: context,
                    title: 'Completed foglalasok',
                    value: '${stats.completedReservationCount}',
                    icon: Icons.task_alt_outlined,
                    tint: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moderacios fokusz',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.visibility_off_outlined),
                title: const Text('Elrejtett termekek'),
                trailing: Text('$hiddenProducts db'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_off_outlined),
                title: const Text('Nem aktiv fiokok'),
                trailing: Text('$restrictedUsers db'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_busy_outlined),
                title: const Text('Lemondott foglalasok'),
                trailing: Text('$cancelledReservations db'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserSection({
    required BuildContext context,
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
    required Map<String, Product> productsById,
    required Map<String, AppUserProfile> usersById,
    required Map<String, MerchantStatsSummary> merchantStatsById,
  }) {
    final filteredUsers = users.where((user) {
      return _matchesQuery([
        user.primaryLabel,
        user.email,
        user.companyName,
        roleLabel(user.role),
        accountStatusLabel(user.accountStatus),
      ], _userQuery);
    }).toList();

    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Felhasznalok',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _userQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Kereses nev, email vagy statusz alapjan',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talalatok: ${filteredUsers.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (filteredUsers.isEmpty)
                const Text('Nincs a keresesnek megfelelo felhasznalo.')
              else
                ...filteredUsers.map((user) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        user.primaryLabel.isEmpty
                            ? '?'
                            : user.primaryLabel.substring(0, 1).toUpperCase(),
                      ),
                    ),
                    title: Text(user.primaryLabel),
                    subtitle: Text(userSubtitle(user)),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(roleLabel(user.role))),
                        Chip(
                          label: Text(accountStatusLabel(user.accountStatus)),
                          backgroundColor: accountStatusColor(
                            context,
                            user.accountStatus,
                          ).withValues(alpha: 0.14),
                        ),
                        TextButton(
                          onPressed: () => _openUserDetail(
                            user: user,
                            products: products,
                            reservations: reservations,
                            productsById: productsById,
                            usersById: usersById,
                            merchantStats: merchantStatsById[user.id],
                          ),
                          child: const Text('Reszletek'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMerchantSection({
    required BuildContext context,
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
    required Map<String, Product> productsById,
    required Map<String, AppUserProfile> usersById,
    required Map<String, MerchantStatsSummary> merchantStatsById,
  }) {
    final merchants = users.where((user) => user.role == 'merchant').where((
      user,
    ) {
      return _matchesQuery([
        user.primaryLabel,
        user.email,
        user.companyName,
      ], _merchantQuery);
    }).toList();

    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kereskedok',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _merchantQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Kereses kereskedore',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talalatok: ${merchants.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (merchants.isEmpty)
                const Text('Nincs megjelenitheto kereskedo.')
              else
                ...merchants.map((merchant) {
                  final merchantProducts = products
                      .where((product) => product.ownerId == merchant.id)
                      .toList();
                  final merchantStats = merchantStatsById[merchant.id];
                  final merchantReservations = reservations
                      .where(
                        (reservation) => reservation.merchantId == merchant.id,
                      )
                      .toList();
                  final activeProductCount = merchantProducts
                      .where((product) => product.isEffectivelyActive)
                      .length;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(merchant.primaryLabel),
                    subtitle: Text(userSubtitle(merchant)),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text('Termek: ${merchantProducts.length}')),
                        Chip(label: Text('Aktiv: $activeProductCount')),
                        Chip(
                          label: Text(
                            'Rating: ${merchantRatingLabel(merchantStats)}',
                          ),
                        ),
                        Chip(
                          label: Text(
                            'Foglalas: ${merchantReservations.length}',
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openUserDetail(
                            user: merchant,
                            products: products,
                            reservations: reservations,
                            productsById: productsById,
                            usersById: usersById,
                            merchantStats: merchantStats,
                          ),
                          child: const Text('Reszletek'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerSection({
    required BuildContext context,
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
    required Map<String, Product> productsById,
    required Map<String, AppUserProfile> usersById,
    required Map<String, MerchantStatsSummary> merchantStatsById,
  }) {
    final customers = users.where((user) => user.role == 'consumer').where((
      user,
    ) {
      return _matchesQuery([user.primaryLabel, user.email], _customerQuery);
    }).toList();

    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vasarlok',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _customerQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Kereses vasarlora',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talalatok: ${customers.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (customers.isEmpty)
                const Text('Nincs megjelenitheto vasarlo.')
              else
                ...customers.map((customer) {
                  final customerReservations = reservations
                      .where(
                        (reservation) => reservation.buyerId == customer.id,
                      )
                      .toList();
                  final completedCount = customerReservations
                      .where((reservation) => reservation.status == 'completed')
                      .length;
                  final cancelledCount = customerReservations
                      .where((reservation) => reservation.status == 'cancelled')
                      .length;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(customer.primaryLabel),
                    subtitle: Text(userSubtitle(customer)),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            'Foglalas: ${customerReservations.length}',
                          ),
                        ),
                        Chip(label: Text('Completed: $completedCount')),
                        Chip(label: Text('Lemondott: $cancelledCount')),
                        TextButton(
                          onPressed: () => _openUserDetail(
                            user: customer,
                            products: products,
                            reservations: reservations,
                            productsById: productsById,
                            usersById: usersById,
                            merchantStats: merchantStatsById[customer.id],
                          ),
                          child: const Text('Reszletek'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductSection({
    required BuildContext context,
    required List<Product> products,
    required Map<String, AppUserProfile> usersById,
    required List<Reservation> reservations,
  }) {
    final filteredProducts = products.where((product) {
      final matchesStatus = _productStatusFilter == 'all'
          ? true
          : product.effectiveStatus == _productStatusFilter;
      final merchant = usersById[product.ownerId];
      final matchesQuery = _matchesQuery([
        product.name,
        product.category,
        product.merchantName,
        merchant?.primaryLabel ?? '',
      ], _productQuery);
      return matchesStatus && matchesQuery;
    }).toList();

    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Termekmoderacio',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _productQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Kereses termekre vagy kereskedore',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'all',
                      'active',
                      'hidden',
                      'archived',
                      'expired',
                      'sold_out',
                    ].map((status) {
                      final selected = _productStatusFilter == status;
                      return ChoiceChip(
                        label: Text(status == 'all' ? 'Osszes' : status),
                        selected: selected,
                        onSelected: (_) {
                          setState(() => _productStatusFilter = status);
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talalatok: ${filteredProducts.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (filteredProducts.isEmpty)
                const Text('Nincs megjelenitheto termek.')
              else
                ...filteredProducts.map((product) {
                  final merchant = usersById[product.ownerId];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.name),
                    subtitle: Text(
                      '${merchant?.primaryLabel ?? product.merchantName} | ${product.category} | ${product.createdAt == null ? 'Nincs datum' : formatDateTime(product.createdAt!)}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(productStatusLabel(product)),
                          backgroundColor: productStatusColor(
                            context,
                            product,
                          ).withValues(alpha: 0.14),
                        ),
                        TextButton(
                          onPressed: () => _openProductDetail(
                            product: product,
                            usersById: usersById,
                            reservations: reservations,
                          ),
                          child: const Text('Megnyitas'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationSection({
    required BuildContext context,
    required List<Reservation> reservations,
    required Map<String, AppUserProfile> usersById,
    required Map<String, Product> productsById,
  }) {
    final filteredReservations = reservations.where((reservation) {
      final matchesStatus = _reservationStatusFilter == 'all'
          ? true
          : reservation.status == _reservationStatusFilter;
      final matchesQuery = _matchesQuery([
        reservationProductLabel(
          reservation: reservation,
          productsById: productsById,
        ),
        reservationBuyerLabel(reservation: reservation, usersById: usersById),
        reservationMerchantLabel(
          reservation: reservation,
          usersById: usersById,
        ),
      ], _reservationQuery);
      return matchesStatus && matchesQuery;
    }).toList();

    return ListView(
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Foglalasok',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _reservationQuery = value),
                decoration: const InputDecoration(
                  labelText: 'Kereses termekre, vasarlora vagy kereskedore',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    [
                      'all',
                      'reserved',
                      'completed',
                      'cancelled',
                      'expired',
                    ].map((status) {
                      return ChoiceChip(
                        label: Text(status == 'all' ? 'Osszes' : status),
                        selected: _reservationStatusFilter == status,
                        onSelected: (_) {
                          setState(() => _reservationStatusFilter = status);
                        },
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Talalatok: ${filteredReservations.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (filteredReservations.isEmpty)
                const Text('Nincs megjelenitheto foglalas.')
              else
                ...filteredReservations.map((reservation) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      reservationProductLabel(
                        reservation: reservation,
                        productsById: productsById,
                      ),
                    ),
                    subtitle: Text(
                      '${reservationBuyerLabel(reservation: reservation, usersById: usersById)} | ${reservationMerchantLabel(reservation: reservation, usersById: usersById)} | ${reservation.createdAt == null ? 'Nincs datum' : formatDateTime(reservation.createdAt!)}',
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(reservationStatusLabel(reservation)),
                          backgroundColor: reservationStatusColor(
                            context,
                            reservation,
                          ).withValues(alpha: 0.14),
                        ),
                        TextButton(
                          onPressed: () => _openReservationDetail(
                            reservation: reservation,
                            productsById: productsById,
                            usersById: usersById,
                          ),
                          child: const Text('Reszletek'),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContent({
    required BuildContext context,
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
    required List<MerchantStatsSummary> merchantStats,
  }) {
    final usersById = {for (final user in users) user.id: user};
    final productsById = {for (final product in products) product.id: product};
    final merchantStatsById = {
      for (final stats in merchantStats) stats.merchantId: stats,
    };
    final stats = AdminDashboardStats.fromCollections(
      users: users,
      products: products,
      reservations: reservations,
    );

    switch (_section) {
      case AdminSection.dashboard:
        return _buildDashboard(
          context: context,
          stats: stats,
          users: users,
          products: products,
          reservations: reservations,
        );
      case AdminSection.users:
        return _buildUserSection(
          context: context,
          users: users,
          products: products,
          reservations: reservations,
          productsById: productsById,
          usersById: usersById,
          merchantStatsById: merchantStatsById,
        );
      case AdminSection.merchants:
        return _buildMerchantSection(
          context: context,
          users: users,
          products: products,
          reservations: reservations,
          productsById: productsById,
          usersById: usersById,
          merchantStatsById: merchantStatsById,
        );
      case AdminSection.customers:
        return _buildCustomerSection(
          context: context,
          users: users,
          products: products,
          reservations: reservations,
          productsById: productsById,
          usersById: usersById,
          merchantStatsById: merchantStatsById,
        );
      case AdminSection.products:
        return _buildProductSection(
          context: context,
          products: products,
          usersById: usersById,
          reservations: reservations,
        );
      case AdminSection.reservations:
        return _buildReservationSection(
          context: context,
          reservations: reservations,
          usersById: usersById,
          productsById: productsById,
        );
    }
  }

  Widget _buildDesktopNavigation() {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: NavigationRail(
        selectedIndex: AdminSection.values.indexOf(_section),
        onDestinationSelected: (index) {
          _openSection(AdminSection.values[index]);
        },
        labelType: NavigationRailLabelType.all,
        destinations: AdminSection.values.map((section) {
          return NavigationRailDestination(
            icon: Icon(section.icon),
            label: Text(section.label),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required List<AppUserProfile> users,
    required List<Product> products,
    required List<Reservation> reservations,
    required List<MerchantStatsSummary> merchantStats,
  }) {
    final wideLayout = MediaQuery.sizeOf(context).width >= 1120;
    final content = NearPickBackground(
      padding: const EdgeInsets.all(20),
      child: _buildSectionContent(
        context: context,
        users: users,
        products: products,
        reservations: reservations,
        merchantStats: merchantStats,
      ),
    );

    if (!wideLayout) {
      return content;
    }

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
          child: _buildDesktopNavigation(),
        ),
        Expanded(child: content),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('NearPick Admin - ${_section.label}'),
        actions: [
          if (currentUser?.email != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(child: Text(currentUser!.email!)),
            ),
          IconButton(
            onPressed: () => AuthService().logout(),
            tooltip: 'Kijelentkezes',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<AppUserProfile>>(
        stream: _adminService.watchUsers(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasError) {
            return Center(
              child: Text(
                'Hiba a felhasznalok betoltesekor: ${userSnapshot.error}',
              ),
            );
          }

          return StreamBuilder<List<Product>>(
            stream: _adminService.watchProducts(),
            builder: (context, productSnapshot) {
              if (productSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (productSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Hiba a termekek betoltesekor: ${productSnapshot.error}',
                  ),
                );
              }

              return StreamBuilder<List<Reservation>>(
                stream: _adminService.watchReservations(),
                builder: (context, reservationSnapshot) {
                  if (reservationSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (reservationSnapshot.hasError) {
                    return Center(
                      child: Text(
                        'Hiba a foglalasok betoltesekor: ${reservationSnapshot.error}',
                      ),
                    );
                  }

                  return StreamBuilder<List<MerchantStatsSummary>>(
                    stream: _adminService.watchMerchantStats(),
                    builder: (context, merchantStatsSnapshot) {
                      if (merchantStatsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (merchantStatsSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Hiba a kereskedoi statisztikak betoltesekor: ${merchantStatsSnapshot.error}',
                          ),
                        );
                      }

                      final users =
                          userSnapshot.data ?? const <AppUserProfile>[];
                      final products =
                          productSnapshot.data ?? const <Product>[];
                      final reservations =
                          reservationSnapshot.data ?? const <Reservation>[];
                      final merchantStats =
                          merchantStatsSnapshot.data ??
                          const <MerchantStatsSummary>[];

                      return _buildBody(
                        context: context,
                        users: users,
                        products: products,
                        reservations: reservations,
                        merchantStats: merchantStats,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width >= 1120
          ? null
          : NavigationBar(
              selectedIndex: AdminSection.values.indexOf(_section),
              onDestinationSelected: (index) {
                _openSection(AdminSection.values[index]);
              },
              destinations: AdminSection.values.map((section) {
                return NavigationDestination(
                  icon: Icon(section.icon),
                  label: section.label,
                );
              }).toList(),
            ),
    );
  }
}
