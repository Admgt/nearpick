import 'package:flutter/material.dart';
import '../../services/product_service.dart';

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
    super.dispose();
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

      await ProductService().addProduct(
        name: _nameCtrl.text.trim(),
        category: _selectedCategory,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantity: quantity,
        // lejáratot beállítjuk a nap végére (23:59)
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
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  decoration:
                      const InputDecoration(labelText: 'Kategória'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _originalPriceCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Eredeti ár (Ft)'),
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
                  decoration:
                      const InputDecoration(labelText: 'Akciós ár (Ft)'),
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
                  decoration:
                      const InputDecoration(labelText: 'Mennyiség (db)'),
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
