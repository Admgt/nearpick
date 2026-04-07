import 'dart:typed_data';

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error/app_error_message.dart';
import '../../models/product.dart';
import '../../services/dynamic_pricing_service.dart';
import '../../services/product_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import '../../widgets/storage_image.dart';
import 'dynamic_pricing.dart';
import 'merchant_dashboard_screen.dart';
import 'merchant_home_screen.dart';
import 'merchant_navigation.dart';
import 'merchant_profile_screen.dart';
import 'merchant_reservations_screen.dart';
import 'new_product_form_logic.dart';

typedef SaveProductAction = Future<void> Function(NewProductCommand command);
typedef GeneratePricingRecommendationAction =
    Future<DynamicPricingRecommendation> Function({
      required String category,
      required int originalPrice,
      required int quantity,
      required DateTime expiresAt,
    });

class NewProductScreen extends StatefulWidget {
  final SaveProductAction? onSaveProduct;
  final DateTime? initialExpiry;
  final GeneratePricingRecommendationAction? onGeneratePricingRecommendation;
  final Product? initialProduct;

  const NewProductScreen({
    super.key,
    this.onSaveProduct,
    this.initialExpiry,
    this.onGeneratePricingRecommendation,
    this.initialProduct,
  });

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _discountedPriceCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _imageLoading = false;
  bool _removeExistingImage = false;
  bool _pricingLoading = false;

  String _selectedCategory = _categories.first;
  DateTime? _selectedExpiry;
  TimeOfDay _selectedPickupStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _selectedPickupEndTime = const TimeOfDay(hour: 18, minute: 0);
  bool _loading = false;
  String? _error;
  DynamicPricingRecommendation? _pricingRecommendation;
  String? _pricingError;

  void _openTopDestination(MerchantTopDestination destination) {
    switch (destination) {
      case MerchantTopDestination.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantHomeScreen()),
        );
      case MerchantTopDestination.reservations:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantReservationsScreen()),
        );
      case MerchantTopDestination.dashboard:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantDashboardScreen()),
        );
      case MerchantTopDestination.profile:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
        );
    }
  }

  @override
  void initState() {
    super.initState();
    final initialProduct = widget.initialProduct;
    _selectedExpiry = initialProduct?.expiresAt ?? widget.initialExpiry;

    if (initialProduct == null) {
      return;
    }

    _nameCtrl.text = initialProduct.name;
    _originalPriceCtrl.text = initialProduct.originalPrice.toString();
    _discountedPriceCtrl.text = initialProduct.discountedPrice.toString();
    _quantityCtrl.text = initialProduct.quantity.toString();
    _selectedCategory = _categories.contains(initialProduct.category)
        ? initialProduct.category
        : _categories.first;

    final pickupStartAt = initialProduct.pickupStartAt;
    if (pickupStartAt != null) {
      _selectedPickupStartTime = TimeOfDay.fromDateTime(pickupStartAt);
    }

    final pickupEndAt = initialProduct.pickupEndAt;
    if (pickupEndAt != null) {
      _selectedPickupEndTime = TimeOfDay.fromDateTime(pickupEndAt);
    }

    _pricingRecommendation = _pricingRecommendationFromMap(
      initialProduct.pricingRecommendation,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _originalPriceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _showImagePickerSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeria'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      setState(() => _imageLoading = true);
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 82,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _removeExistingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(appErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _imageLoading = false);
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 14)),
    );
    if (picked != null) {
      setState(() {
        _selectedExpiry = picked;
        _pricingRecommendation = null;
        _pricingError = null;
      });
    }
  }

  Future<void> _pickPickupTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _selectedPickupStartTime : _selectedPickupEndTime,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _selectedPickupStartTime = picked;
      } else {
        _selectedPickupEndTime = picked;
      }
    });
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatTimeOfDay(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _formatLocationLabel(GeoPoint? location) {
    if (location == null) {
      return 'Nincs mentett hely ehhez a termekhez.';
    }
    return '${location.latitude.toStringAsFixed(6)}, '
        '${location.longitude.toStringAsFixed(6)}';
  }

  void _clearPricingRecommendation() {
    if (_pricingRecommendation == null && _pricingError == null) {
      return;
    }
    setState(() {
      _pricingRecommendation = null;
      _pricingError = null;
    });
  }

  DynamicPricingRecommendation? _pricingRecommendationFromMap(
    Map<String, dynamic>? source,
  ) {
    if (source == null) {
      return null;
    }

    final recommendedPrice = source['recommendedPrice'] as int?;
    final minimumSuggestedPrice = source['minimumSuggestedPrice'] as int?;
    final maximumSuggestedPrice = source['maximumSuggestedPrice'] as int?;
    final discountPercent = source['discountPercent'] as int?;
    final demandScore = source['demandScore'];
    final demandLevel = source['demandLevel'] as String?;
    final expectedReservations24h = source['expectedReservations24h'] as int?;
    final views7d = source['views7d'] as int?;
    final interests7d = source['interests7d'] as int?;
    final dismissals7d = source['dismissals7d'] as int?;
    final activeCategoryOffers = source['activeCategoryOffers'] as int?;
    final averageDiscountPercent = source['averageDiscountPercent'] as int?;

    if (recommendedPrice == null ||
        minimumSuggestedPrice == null ||
        maximumSuggestedPrice == null ||
        discountPercent == null ||
        demandScore is! num ||
        demandLevel == null ||
        expectedReservations24h == null ||
        views7d == null ||
        interests7d == null ||
        dismissals7d == null ||
        activeCategoryOffers == null ||
        averageDiscountPercent == null) {
      return null;
    }

    return DynamicPricingRecommendation(
      recommendedPrice: recommendedPrice,
      minimumSuggestedPrice: minimumSuggestedPrice,
      maximumSuggestedPrice: maximumSuggestedPrice,
      discountPercent: discountPercent,
      demandScore: demandScore.toDouble(),
      demandLevel: demandLevel,
      expectedReservations24h: expectedReservations24h,
      marketSnapshot: MerchantMarketSnapshot(
        views7d: views7d,
        interests7d: interests7d,
        dismissals7d: dismissals7d,
        activeCategoryOffers: activeCategoryOffers,
        averageDiscountRatio: averageDiscountPercent / 100,
      ),
      reasons: const [],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedExpiry == null) {
      setState(() => _error = 'Kerlek valaszd ki a lejarati datumot.');
      return;
    }

    final pickupStartAt = _combineDateAndTime(
      _selectedExpiry!,
      _selectedPickupStartTime,
    );
    final pickupEndAt = _combineDateAndTime(
      _selectedExpiry!,
      _selectedPickupEndTime,
    );
    if (!pickupEndAt.isAfter(pickupStartAt)) {
      setState(() {
        _error = 'Az atveteli idosav vege legyen kesobb, mint a kezdete.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final command = NewProductCommand(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        originalPrice: parsePositiveInt(
          _originalPriceCtrl.text,
          fieldLabel: 'Az eredeti ar',
        ),
        discountedPrice: parsePositiveInt(
          _discountedPriceCtrl.text,
          fieldLabel: 'Az akcios ar',
        ),
        quantity: parsePositiveInt(
          _quantityCtrl.text,
          fieldLabel: 'A mennyiseg',
        ),
        location: widget.initialProduct?.location,
        expiresAt: DateTime(
          _selectedExpiry!.year,
          _selectedExpiry!.month,
          _selectedExpiry!.day,
          23,
          59,
        ),
        pickupStartAt: pickupStartAt,
        pickupEndAt: pickupEndAt,
        pricingRecommendation: _pricingRecommendation,
      );

      if (widget.onSaveProduct != null) {
        await widget.onSaveProduct!(command);
      } else {
        final productService = ProductService();
        final initialProduct = widget.initialProduct;
        if (initialProduct == null) {
          await productService.createProductWithOptionalImage(
            name: command.name,
            category: command.category,
            originalPrice: command.originalPrice,
            discountedPrice: command.discountedPrice,
            quantity: command.quantity,
            expiresAt: command.expiresAt,
            pickupStartAt: command.pickupStartAt,
            pickupEndAt: command.pickupEndAt,
            location: command.location,
            imageBytes: _selectedImageBytes,
            pricingRecommendation: command.pricingRecommendation,
          );
        } else {
          await productService.updateProduct(
            productId: initialProduct.id,
            name: command.name,
            category: command.category,
            originalPrice: command.originalPrice,
            discountedPrice: command.discountedPrice,
            quantity: command.quantity,
            expiresAt: command.expiresAt,
            pickupStartAt: command.pickupStartAt,
            pickupEndAt: command.pickupEndAt,
            location: command.location,
            imageBytes: _selectedImageBytes,
            removeImage: _removeExistingImage,
            pricingRecommendation: command.pricingRecommendation,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = appErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _generatePricingRecommendation() async {
    if (_selectedExpiry == null) {
      setState(() {
        _pricingError = 'Elobb valassz lejarati datumot az arjavaslathoz.';
      });
      return;
    }

    final originalPrice = int.tryParse(_originalPriceCtrl.text.trim());
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    if (originalPrice == null || originalPrice <= 0) {
      setState(() {
        _pricingError = 'Adj meg ervenyes eredeti arat az arjavaslathoz.';
      });
      return;
    }
    if (quantity == null || quantity <= 0) {
      setState(() {
        _pricingError = 'Adj meg ervenyes mennyiseget az arjavaslathoz.';
      });
      return;
    }

    setState(() {
      _pricingLoading = true;
      _pricingError = null;
    });

    try {
      final builder =
          widget.onGeneratePricingRecommendation ??
          ({
            required String category,
            required int originalPrice,
            required int quantity,
            required DateTime expiresAt,
          }) {
            return DynamicPricingService().buildRecommendation(
              category: category,
              originalPrice: originalPrice,
              quantity: quantity,
              expiresAt: expiresAt,
            );
          };

      final recommendation = await builder(
        category: _selectedCategory,
        originalPrice: originalPrice,
        quantity: quantity,
        expiresAt: DateTime(
          _selectedExpiry!.year,
          _selectedExpiry!.month,
          _selectedExpiry!.day,
          23,
          59,
        ),
      );

      if (!mounted) return;
      setState(() {
        _pricingRecommendation = recommendation;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pricingError = appErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() => _pricingLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialProduct = widget.initialProduct;
    final isEditing = initialProduct != null;
    final hasExistingImage =
        initialProduct?.hasImage == true &&
        initialProduct?.imagePath != null &&
        initialProduct!.imagePath!.isNotEmpty &&
        !_removeExistingImage;
    final Widget imagePreview;
    if (_selectedImageBytes != null) {
      imagePreview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _selectedImageBytes!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
        ),
      );
    } else if (hasExistingImage) {
      imagePreview = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: StorageImage(
          imagePath: initialProduct.imagePath!,
          imageUrl: initialProduct.imageUrl,
          width: double.infinity,
          height: 180,
          fit: BoxFit.cover,
          maxSizeBytes: 512 * 1024,
        ),
      );
    } else {
      imagePreview = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.camera_alt_outlined, size: 36),
          SizedBox(height: 8),
          Text('Kep hozzaadasa'),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Termek szerkesztese' : 'Uj termek hozzaadasa'),
        actions: buildMerchantAppBarActions(
          context,
          onSelected: _openTopDestination,
        ),
      ),
      body: NearPickBackground(
        maxWidth: 760,
        child: Center(
          child: SingleChildScrollView(
            child: SurfaceCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _showImagePickerSheet,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imagePreview,
                      ),
                    ),
                    if (_imageLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    if (_selectedImage != null || hasExistingImage)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _selectedImage = null;
                            _selectedImageBytes = null;
                            _removeExistingImage = true;
                          }),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Kep torlese'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const ValueKey('new_product_name_field'),
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Termek neve',
                      ),
                      onChanged: (_) => _clearPricingRecommendation(),
                      validator: validateRequiredName,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('new_product_category_field'),
                      initialValue: _selectedCategory,
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCategory = value;
                            _pricingRecommendation = null;
                            _pricingError = null;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Kategoria'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('new_product_original_price_field'),
                      controller: _originalPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Eredeti ar (Ft)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _clearPricingRecommendation(),
                      validator: validateIntegerField,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('new_product_discounted_price_field'),
                      controller: _discountedPriceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Akcios ar (Ft)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: validateIntegerField,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('new_product_quantity_field'),
                      controller: _quantityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mennyiseg (db)',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _clearPricingRecommendation(),
                      validator: validatePositiveQuantity,
                    ),
                    const SizedBox(height: 12),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialProduct == null
                                ? 'Atveteli hely'
                                : 'Termek helye',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.initialProduct == null
                                ? 'Az uj termek automatikusan a profilban '
                                      'megadott ceges helyet kapja meg.'
                                : 'A szerkesztes megtartja a termek korabban '
                                      'mentett helyet.',
                          ),
                          if (widget.initialProduct != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _formatLocationLabel(
                                widget.initialProduct?.location,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedExpiry == null
                                ? 'Nincs kivalasztva lejarati datum'
                                : 'Lejarat: ${formatDate(_selectedExpiry!)}',
                          ),
                        ),
                        TextButton(
                          key: const ValueKey('new_product_pick_expiry_button'),
                          onPressed: _pickExpiryDate,
                          child: const Text('Lejarati datum'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Atvetel: ${_formatTimeOfDay(_selectedPickupStartTime)} - ${_formatTimeOfDay(_selectedPickupEndTime)}',
                          ),
                        ),
                        TextButton(
                          key: const ValueKey(
                            'new_product_pickup_start_time_button',
                          ),
                          onPressed: () => _pickPickupTime(isStart: true),
                          child: const Text('Kezdo ido'),
                        ),
                        TextButton(
                          key: const ValueKey(
                            'new_product_pickup_end_time_button',
                          ),
                          onPressed: () => _pickPickupTime(isStart: false),
                          child: const Text('Vege ido'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        key: const ValueKey('new_product_pricing_button'),
                        onPressed: _pricingLoading
                            ? null
                            : _generatePricingRecommendation,
                        icon: _pricingLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_graph_outlined),
                        label: const Text('Arjavaslat es keresletbecsles'),
                      ),
                    ),
                    if (_pricingError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _pricingError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    if (_pricingRecommendation != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Arazasi javaslat',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Javasolt akcios ar: ${_pricingRecommendation!.recommendedPrice} Ft',
                            ),
                            Text(
                              'Sav: ${_pricingRecommendation!.minimumSuggestedPrice}-${_pricingRecommendation!.maximumSuggestedPrice} Ft',
                            ),
                            Text(
                              'Becsult kereslet: ${demandLevelLabel(_pricingRecommendation!.demandLevel)} (${(_pricingRecommendation!.demandScore * 100).round()}%)',
                            ),
                            Text(
                              'Varhato foglalas 24 oran belul: ${_pricingRecommendation!.expectedReservations24h}',
                            ),
                            const SizedBox(height: 10),
                            ..._pricingRecommendation!.reasons.map(
                              (reason) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  '- ${reason.label}: ${reason.detail}',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                key: const ValueKey(
                                  'new_product_apply_pricing_button',
                                ),
                                onPressed: () {
                                  _discountedPriceCtrl.text =
                                      _pricingRecommendation!.recommendedPrice
                                          .toString();
                                },
                                icon: const Icon(Icons.sell_outlined),
                                label: const Text('Javasolt ar beallitasa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_error != null)
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      key: const ValueKey('new_product_save_button'),
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const CircularProgressIndicator()
                          : Text(isEditing ? 'Modositas mentese' : 'Mentes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const List<String> _categories = [
  'Peksutemeny',
  'Tejtermek',
  'Zoldseg / gyumolcs',
  'Keszetel',
  'Egyeb',
];
