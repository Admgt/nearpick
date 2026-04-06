import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../recommendation/recommendation_engine.dart';
import '../../ui/app_chrome.dart';
import '../../widgets/storage_image.dart';

class OfferMapView extends StatefulWidget {
  final List<RecommendationResult> offers;
  final GeoPoint? userLocation;
  final double preferredRadiusKm;
  final ValueChanged<RecommendationResult> onOpenProduct;
  final void Function(String productId, Map<String, dynamic> product)
  onReserveProduct;

  const OfferMapView({
    super.key,
    required this.offers,
    required this.userLocation,
    required this.preferredRadiusKm,
    required this.onOpenProduct,
    required this.onReserveProduct,
  });

  @override
  State<OfferMapView> createState() => _OfferMapViewState();
}

class _OfferMapViewState extends State<OfferMapView> {
  String? _selectedProductId;

  @override
  void didUpdateWidget(covariant OfferMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedProductId == null) {
      return;
    }

    final stillExists = widget.offers.any(
      (o) => o.productId == _selectedProductId,
    );
    if (!stillExists) {
      _selectedProductId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final offersWithLocation = widget.offers
        .where((offer) => offer.product['location'] is GeoPoint)
        .toList();

    if (offersWithLocation.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.map_outlined,
        title: 'Nincs terkepezheto ajanlat',
        message:
            'Ehhez a szureshez most nincs olyan ajanlat, amelyhez helyadat tartozik.',
      );
    }

    final selectedOffer = offersWithLocation.firstWhere(
      (offer) => offer.productId == _selectedProductId,
      orElse: () => offersWithLocation.first,
    );
    final initialCenter = _buildInitialCenter(offersWithLocation);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                InfoBadge(
                  icon: Icons.place_outlined,
                  label: 'Terkepezett',
                  value: '${offersWithLocation.length} ajanlat',
                ),
                InfoBadge(
                  icon: Icons.route_outlined,
                  label: 'Sugar',
                  value: '${widget.preferredRadiusKm.toStringAsFixed(0)} km',
                ),
                InfoBadge(
                  icon: Icons.near_me_outlined,
                  label: 'Kozeledben',
                  value:
                      '${offersWithLocation.where((o) => o.isWithinPreferredRadius).length} db',
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: _zoomForRadius(widget.preferredRadiusKm),
                      onTap: (_, __) =>
                          setState(() => _selectedProductId = null),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.nearpick',
                      ),
                      MarkerLayer(
                        markers: [
                          if (widget.userLocation != null)
                            Marker(
                              point: LatLng(
                                widget.userLocation!.latitude,
                                widget.userLocation!.longitude,
                              ),
                              width: 54,
                              height: 54,
                              child: const _UserLocationMarker(),
                            ),
                          ...offersWithLocation.map(_buildOfferMarker),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          'Map data: OpenStreetMap contributors',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 44,
                    child: _SelectedOfferCard(
                      offer: selectedOffer,
                      onOpen: () => widget.onOpenProduct(selectedOffer),
                      onReserve: () => widget.onReserveProduct(
                        selectedOffer.productId,
                        selectedOffer.product,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Marker _buildOfferMarker(RecommendationResult offer) {
    final location = offer.product['location'] as GeoPoint;
    final discountedPrice = offer.product['discountedPrice'] as int? ?? 0;
    final isSelected = offer.productId == _selectedProductId;

    return Marker(
      point: LatLng(location.latitude, location.longitude),
      width: 84,
      height: 52,
      child: GestureDetector(
        onTap: () => setState(() => _selectedProductId = offer.productId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _markerColor(
              isSelected: isSelected,
              isWithinRadius: offer.isWithinPreferredRadius,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: FittedBox(
            child: Text(
              '$discountedPrice Ft',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  LatLng _buildInitialCenter(List<RecommendationResult> offersWithLocation) {
    if (widget.userLocation != null) {
      return LatLng(
        widget.userLocation!.latitude,
        widget.userLocation!.longitude,
      );
    }

    final firstLocation =
        offersWithLocation.first.product['location'] as GeoPoint;
    return LatLng(firstLocation.latitude, firstLocation.longitude);
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 2) return 14.3;
    if (radiusKm <= 5) return 13.2;
    if (radiusKm <= 10) return 12.2;
    return 11.3;
  }

  Color _markerColor({required bool isSelected, required bool isWithinRadius}) {
    if (isSelected) {
      return const Color(0xFFB85C38);
    }
    if (isWithinRadius) {
      return const Color(0xFF2E7D5A);
    }
    return const Color(0xFF5C6F7C);
  }
}

class _SelectedOfferCard extends StatelessWidget {
  final RecommendationResult offer;
  final VoidCallback onOpen;
  final VoidCallback onReserve;

  const _SelectedOfferCard({
    required this.offer,
    required this.onOpen,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final product = offer.product;
    final imagePath = product['imagePath'] as String?;
    final hasImage = product['hasImage'] == true;
    final name = product['name'] as String? ?? 'Nevtelen termek';
    final merchantName = (product['merchantName'] as String?)?.trim() ?? '';
    final category = product['category'] as String? ?? 'Ismeretlen kategoria';
    final discountedPrice = product['discountedPrice'] as int? ?? 0;
    final quantityAvailable =
        product['quantityAvailable'] as int? ??
        product['quantity'] as int? ??
        0;
    final distanceText = offer.distanceKm == null
        ? 'Nincs tavolsag adat'
        : distanceLabelKm(offer.distanceKm!);

    return SurfaceCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (hasImage && imagePath != null && imagePath.isNotEmpty)
            StorageImage(
              imagePath: imagePath,
              width: 72,
              height: 72,
              borderRadius: 14,
              maxSizeBytes: 256 * 1024,
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.storefront_outlined),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  merchantName.isEmpty
                      ? '$category | $distanceText'
                      : '$merchantName | $category | $distanceText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniPill(label: '$discountedPrice Ft'),
                    _MiniPill(label: '$quantityAvailable db'),
                    _MiniPill(
                      label: offer.isWithinPreferredRadius
                          ? 'Sajat sugarban'
                          : 'Sajat sugaron kivul',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonal(
                onPressed: onOpen,
                child: const Text('Reszletek'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: quantityAvailable <= 0 ? null : onReserve,
                child: const Text('Foglalas'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;

  const _MiniPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFB85C38),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.my_location, color: Colors.white, size: 24),
    );
  }
}
