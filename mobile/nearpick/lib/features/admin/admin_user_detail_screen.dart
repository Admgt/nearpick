import 'package:flutter/material.dart';

import '../../core/error/app_error_message.dart';
import '../../models/admin_message.dart';
import '../../models/app_user_profile.dart';
import '../../models/merchant_stats_summary.dart';
import '../../models/product.dart';
import '../../models/reservation.dart';
import '../../services/admin_message_service.dart';
import '../../services/admin_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import '../../widgets/merchant_reviews_section.dart';
import 'admin_support.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final AppUserProfile user;
  final List<Product> products;
  final List<Reservation> reservations;
  final Map<String, Product> productsById;
  final Map<String, AppUserProfile> usersById;
  final MerchantStatsSummary? merchantStats;
  final AdminService adminService;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
    required this.products,
    required this.reservations,
    required this.productsById,
    required this.usersById,
    required this.merchantStats,
    required this.adminService,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  final AdminMessageService _messageService = AdminMessageService();
  final TextEditingController _messageSubjectController =
      TextEditingController();
  final TextEditingController _messageBodyController = TextEditingController();

  bool _statusLoading = false;
  bool _messageSending = false;
  String _messageTopic = 'general';

  @override
  void dispose() {
    _messageSubjectController.dispose();
    _messageBodyController.dispose();
    super.dispose();
  }

  Future<void> _setStatus(String status) async {
    setState(() => _statusLoading = true);
    try {
      await widget.adminService.updateUserAccountStatus(
        userId: widget.user.id,
        accountStatus: status,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Felhasznalo allapota: ${accountStatusLabel(status)}'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _statusLoading = false);
      }
    }
  }

  Widget _buildStatusActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.tonal(
          onPressed: _statusLoading ? null : () => _setStatus('suspended'),
          child: const Text('Felfuggesztes'),
        ),
        FilledButton(
          onPressed: _statusLoading ? null : () => _setStatus('active'),
          child: const Text('Visszaaktivalas'),
        ),
        OutlinedButton(
          onPressed: _statusLoading ? null : () => _setStatus('blocked'),
          child: const Text('Tiltas'),
        ),
      ],
    );
  }

  void _applyRatingTemplate({
    required AppUserProfile user,
    required MerchantStatsSummary? merchantStats,
  }) {
    final ratingLabel = merchantRatingLabel(merchantStats);
    final reviewCount = merchantStats?.reviewCount ?? 0;
    _messageTopic = 'rating';
    _messageSubjectController.text = 'Vasarloi ertekelesek felulvizsgalata';
    _messageBodyController.text =
        'Kedves ${user.primaryLabel},\n\n'
        'Az admin felulet alapjan a kereskedoi profilod aktualis atlagos ertekelese $ratingLabel'
        '${reviewCount > 0 ? ' ($reviewCount velemeny alapjan)' : ''}. '
        'Kerjuk, nezd at a legutobbi vasarloi visszajelzeseket, es szukseg eseten javits a kiszolgalason, '
        'atveteli folyamaton vagy a termekleirasok pontossagan.\n\n'
        'Ha szeretned, kuldunk reszletesebb visszajelzest is.';
    setState(() {});
  }

  Future<void> _sendMessageToMerchant() async {
    final subject = _messageSubjectController.text.trim();
    final body = _messageBodyController.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A targy es az uzenet torzse kotelezo.')),
      );
      return;
    }

    setState(() => _messageSending = true);
    try {
      await _messageService.sendMessageToMerchant(
        merchantId: widget.user.id,
        subject: subject,
        body: body,
        topic: _messageTopic,
      );
      if (!mounted) {
        return;
      }
      _messageSubjectController.clear();
      _messageBodyController.clear();
      setState(() => _messageTopic = 'general');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Az admin uzenet elkuldve a kereskedonek.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() => _messageSending = false);
      }
    }
  }

  Widget _buildAdminMessageHistory(List<AdminMessage> messages) {
    if (messages.isEmpty) {
      return const Text(
        'Ehhez a kereskedohoz meg nem lett admin uzenet kuldve.',
      );
    }

    return Column(
      children: messages.take(6).map((message) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            message.isRead
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
          ),
          title: Text(message.subject),
          subtitle: Text(
            '${adminMessageTopicLabel(message.topic)} | ${message.createdAt == null ? 'Nincs datum' : formatDateTime(message.createdAt!)}\n${message.body}',
          ),
          isThreeLine: true,
          trailing: Text(message.isRead ? 'Olvasva' : 'Uj'),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final ownProducts = widget.products
        .where((product) => product.ownerId == user.id)
        .toList();
    final ownReservations = widget.reservations
        .where(
          (reservation) =>
              reservation.buyerId == user.id ||
              reservation.merchantId == user.id,
        )
        .toList();
    final merchantStats = widget.merchantStats;

    return Scaffold(
      appBar: AppBar(title: Text('Felhasznalo: ${user.primaryLabel}')),
      body: NearPickBackground(
        maxWidth: 1040,
        child: ListView(
          children: [
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.primaryLabel,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      InfoBadge(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Szerepkor',
                        value: roleLabel(user.role),
                      ),
                      InfoBadge(
                        icon: Icons.verified_user_outlined,
                        label: 'Statusz',
                        value: accountStatusLabel(user.accountStatus),
                        tint: accountStatusColor(context, user.accountStatus),
                      ),
                      InfoBadge(
                        icon: Icons.calendar_today_outlined,
                        label: 'Regisztracio',
                        value: user.createdAt == null
                            ? 'Nincs adat'
                            : formatDateTime(user.createdAt!),
                      ),
                      if (user.isMerchant)
                        InfoBadge(
                          icon: Icons.star_outline,
                          label: 'Atlag rating',
                          value: merchantRatingLabel(merchantStats),
                          tint: Colors.amber.shade700,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Email: ${user.email.isEmpty ? 'Nincs adat' : user.email}',
                  ),
                  if (user.companyName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Cegnev: ${user.companyName}'),
                  ],
                  if (user.isMerchant && merchantStats != null) ...[
                    const SizedBox(height: 8),
                    Text('Velemenyek: ${merchantStats.reviewCount} db'),
                  ],
                  const SizedBox(height: 20),
                  _buildStatusActions(),
                ],
              ),
            ),
            if (user.isMerchant) ...[
              const SizedBox(height: 16),
              MerchantReviewsSection(
                merchantId: user.id,
                title: 'Vasarloi velemenyek a kereskedorol',
                emptyMessage:
                    'Ehhez a kereskedohoz meg nincs megjelenitheto velemeny.',
                limit: 20,
                showProductName: true,
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin uzenet a kereskedonek',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      merchantStats != null &&
                              merchantStats.reviewCount >= 3 &&
                              merchantStats.averageRating < 3.5
                          ? 'A kereskedo atlagos ratingje jelenleg alacsony, innen kozvetlenul kuldhetsz figyelmeztetest vagy tajekoztato uzenetet.'
                          : 'Itt tudsz kozvetlen admin tajekoztato vagy moderacios uzenetet kuldeni a kereskedonek.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ['general', 'rating', 'moderation'].map((
                        topic,
                      ) {
                        return ChoiceChip(
                          label: Text(adminMessageTopicLabel(topic)),
                          selected: _messageTopic == topic,
                          onSelected: _messageSending
                              ? null
                              : (_) {
                                  setState(() => _messageTopic = topic);
                                },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    if (merchantStats != null &&
                        merchantStats.reviewCount >= 3 &&
                        merchantStats.averageRating < 3.5)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _messageSending
                              ? null
                              : () => _applyRatingTemplate(
                                  user: user,
                                  merchantStats: merchantStats,
                                ),
                          icon: const Icon(Icons.auto_fix_high_outlined),
                          label: const Text('Rating figyelmeztetes sablon'),
                        ),
                      ),
                    TextField(
                      controller: _messageSubjectController,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Targy',
                        prefixIcon: Icon(Icons.subject_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _messageBodyController,
                      maxLength: 1000,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Uzenet',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _messageSending
                          ? null
                          : _sendMessageToMerchant,
                      icon: _messageSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: const Text('Uzenet kuldese'),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Korabbi admin uzenetek',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<AdminMessage>>(
                      stream: _messageService.watchMessagesForUser(user.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Text(appErrorMessage(snapshot.error!));
                        }
                        return _buildAdminMessageHistory(
                          snapshot.data ?? const [],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Termekek',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (ownProducts.isEmpty)
                    const Text('Ehhez a felhasznalohoz nem tartozik termek.')
                  else
                    ...ownProducts.take(8).map((product) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.category} | ${productStatusLabel(product)} | ${formatDateTime(product.createdAt ?? DateTime.now())}',
                        ),
                      );
                    }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Foglalasi elozmeny',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (ownReservations.isEmpty)
                    const Text('Ehhez a felhasznalohoz nem tartozik foglalas.')
                  else
                    ...ownReservations.take(10).map((reservation) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          reservationProductLabel(
                            reservation: reservation,
                            productsById: widget.productsById,
                          ),
                        ),
                        subtitle: Text(
                          '${reservationStatusLabel(reservation)} | ${reservation.createdAt == null ? 'Nincs datum' : formatDateTime(reservation.createdAt!)}',
                        ),
                        trailing: Text(
                          user.id == reservation.buyerId
                              ? 'Vasarlo'
                              : roleLabel(
                                  widget
                                          .usersById[reservation.merchantId]
                                          ?.role ??
                                      'merchant',
                                ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
