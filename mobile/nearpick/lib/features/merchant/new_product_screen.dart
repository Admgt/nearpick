// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/product_service.dart';
import '../../services/location_service.dart';

class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

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

  String _selectedCategory = _categories.first;
  DateTime? _selectedExpiry;
  bool _loading = false;
  String? _error;

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
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    } finally {
      if (mounted) setState(() => _imageLoading = false);
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
      });
    }
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
      setState(() => _error = 'Kérlek válaszd ki a lejárati dátumot.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final originalPrice = int.parse(_originalPriceCtrl.text.trim());
      final discountedPrice = int.parse(_discountedPriceCtrl.text.trim());
      final quantity = int.parse(_quantityCtrl.text.trim());
      final latText = _latCtrl.text.trim();
      final lngText = _lngCtrl.text.trim();
      GeoPoint? location;
      if (latText.isNotEmpty || lngText.isNotEmpty) {
        if (latText.isEmpty || lngText.isEmpty) {
          throw Exception('Kerek add meg mindket koordinatat.');
        }
        final lat = double.tryParse(latText);
        final lng = double.tryParse(lngText);
        if (lat == null || lng == null) {
          throw Exception('Adj meg ervenyes szamokat a koordinatakhoz.');
        }
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
          throw Exception('A koordinatak tartomanya hibas.');
        }
        location = GeoPoint(lat, lng);
      }

      await ProductService().createProductWithOptionalImage(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantity: quantity,
        location: location,
        // lejáratot beállítjuk a nap végére (23:59)
        imageBytes: _selectedImageBytes,
        expiresAt: DateTime(
          _selectedExpiry!.year,
          _selectedExpiry!.month,
          _selectedExpiry!.day,
          23,
          59,
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Új termék hozzáadása')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
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
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Termék neve'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Kötelező mező';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  decoration: const InputDecoration(labelText: 'Kategória'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originalPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Eredeti ár (Ft)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null) {
                      return 'Adj meg egy érvényes számot';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _discountedPriceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Akciós ár (Ft)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || int.tryParse(value) == null) {
                      return 'Adj meg egy érvényes számot';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _quantityCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mennyiség (db)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final q = int.tryParse(value ?? '');
                    if (q == null || q <= 0) {
                      return 'Adj meg egy pozitív számot';
                    }
                    return null;
                  },
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                        controller: _latCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bolt latitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < -90 || parsed > 90) {
                            return 'Adj meg -90 es 90 kozotti erteket';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lngCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Bolt longitude',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null || parsed < -180 || parsed > 180) {
                            return 'Adj meg -180 es 180 kozotti erteket';
                          }
                          return null;
                        },
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
                            ? 'Nincs kiválasztva lejárati dátum'
                            : 'Lejárat: ${_selectedExpiry!.year}.${_selectedExpiry!.month.toString().padLeft(2, '0')}.${_selectedExpiry!.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                    TextButton(
                      onPressed: _pickExpiryDate,
                      child: const Text('Lejárati dátum'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Mentés'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// egyszerű kategórialista kezdésnek – később bővíthető
const List<String> _categories = [
  'Péksütemény',
  'Tejtermék',
  'Zöldség / gyümölcs',
  'Készétel',
  'Egyéb',
];
