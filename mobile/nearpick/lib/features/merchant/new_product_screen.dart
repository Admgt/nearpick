// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/error/app_error_message.dart';
import '../../services/dynamic_pricing_service.dart';
import '../../services/location_service.dart';
import '../../services/product_service.dart';
import '../../ui/app_chrome.dart';
import '../../utils/date_time_formatters.dart';
import 'dynamic_pricing.dart';
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

  const NewProductScreen({
    super.key,
    this.onSaveProduct,
    this.initialExpiry,
    this.onGeneratePricingRecommendation,
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
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _imageLoading = false;
  bool _fetchingLocation = false;
  bool _pricingLoading = false;

  String _selectedCategory = _categories.first;
  DateTime? _selectedExpiry;
  TimeOfDay _selectedPickupStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _selectedPickupEndTime = const TimeOfDay(hour: 18, minute: 0);
  bool _loading = false;
  String? _error;
  DynamicPricingRecommendation? _pricingRecommendation;
  String? _pricingError;

  @override
  void initState() {
    super.initState();
    _selectedExpiry = widget.initialExpiry;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _originalPriceCtrl.dispose();
    _discountedPriceCtrl.dispose();
    _quantityCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
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
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
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

  void _clearPricingRecommendation() {
    if (_pricingRecommendation == null && _pricingError == null) {
      return;
    }
    setState(() {
      _pricingRecommendation = null;
      _pricingError = null;
    });
  }

  void _showSnackBar(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _fetchingLocation = true;
    });

    try {
      final pos = await LocationService.getCurrentPosition();
      _latCtrl.text = pos.latitude.toStringAsFixed(6);
      _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      _showSnackBar('Hely meghatarozva.');
    } on LocationServiceException catch (e) {
      if (e.code == LocationServiceError.serviceDisabled) {
        _showSnackBar('A helymeghatarozas ki van kapcsolva.');
      } else if (e.code == LocationServiceError.reducedAccuracy) {
        _showSnackBar(
          'A pontos hely nincs engedelyezve. Kapcsold be a pontos helyet a '
          'Beallitasokban.',
        );
      } else if (kIsWeb) {
        _showSnackBar(
          'A bongeszoben a helyhozzaferes le van tiltva. Engedelyezd a cimsor '
          'melletti beallitasoknal.',
        );
      } else {
        _showSnackBar('Hozzaferes megtagadva. Engedelyezd a Beallitasokban.');
      }
    } catch (_) {
      _showSnackBar('Nem sikerult meghatarozni a helyet.');
    } finally {
      if (mounted) {
        setState(() => _fetchingLocation = false);
      }
    }
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
        location: parseOptionalLocation(
          latitudeText: _latCtrl.text,
          longitudeText: _lngCtrl.text,
        ),
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
        await ProductService().createProductWithOptionalImage(
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
    return Scaffold(
      appBar: AppBar(title: const Text('Uj termek hozzaadasa')),
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
                        child: _selectedImageBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt_outlined, size: 36),
                                  SizedBox(height: 8),
                                  Text('Kep hozzaadasa'),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 180,
                                ),
                              ),
                      ),
                    ),
                    if (_imageLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    if (_selectedImage != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setState(() {
                            _selectedImage = null;
                            _selectedImageBytes = null;
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _fetchingLocation ? null : _fetchLocation,
                        icon: _fetchingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Aktualis hely meghatarozasa'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('new_product_latitude_field'),
                            controller: _latCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Bolt latitude',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: validateLatitude,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            key: const ValueKey('new_product_longitude_field'),
                            controller: _lngCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Bolt longitude',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: validateLongitude,
                          ),
                        ),
                      ],
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
                          : const Text('Mentes'),
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
