import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../theme/app_theme.dart';
import '../services/hotel_service.dart';
import '../models/hotel.dart';
import '../helpers/turkey_provinces.dart';

enum SortOption { recommended, priceLowToHigh, priceHighToLow, rating }

class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  String? _selectedProvinceKey;
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  bool _loading = false;
  List<Hotel> _hotels = [];
  SortOption _sortOption = SortOption.recommended;

  final _service = HotelService();

  Future<void> _pickDate(BuildContext context, bool isCheckIn) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn)) _checkOut = _checkIn.add(const Duration(days: 1));
      } else {
        _checkOut = picked;
        if (_checkOut.isBefore(_checkIn)) _checkIn = _checkOut.subtract(const Duration(days: 1));
      }
    });
  }

  Future<void> _search() async {
    final province = _selectedProvinceKey;
    if (province == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir il seçin.')));
      return;
    }
    setState(() { _loading = true; _hotels = []; });
    try {
      final results = await _service.searchHotels(
        city: province,
        checkIn: _checkIn,
        checkOut: _checkOut,
      );
      setState(() { _hotels = results; });
      _applySort();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arama başarısız: $e')));
    } finally {
      setState(() { _loading = false; });
    }
  }

  void _applySort() {
    setState(() {
      switch (_sortOption) {
        case SortOption.priceLowToHigh:
          _hotels.sort((a, b) => (a.pricePerNight ?? double.infinity).compareTo(b.pricePerNight ?? double.infinity));
          break;
        case SortOption.priceHighToLow:
          _hotels.sort((a, b) => (b.pricePerNight ?? double.negativeInfinity).compareTo(a.pricePerNight ?? double.negativeInfinity));
          break;
        case SortOption.rating:
          _hotels.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case SortOption.recommended:
        default:
          break;
      }
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Otel Ara'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.hotel, color: AppTheme.accentColor, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Otel Bilgileri',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedProvinceKey,
                      isExpanded: true,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'İl seçin',
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.12),
                        labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                      dropdownColor: const Color(0xFF1E293B),
                      items: turkeyProvinces
                          .map((province) => DropdownMenuItem<String>(
                                value: province.key,
                                child: Text(
                                  province.name,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProvinceKey = value;
                          _hotels = [];
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _selectedProvinceKey == null
                          ? 'Lütfen listeden bir il seçin.'
                          : 'Seçilen il: ${turkeyProvinces.firstWhere((p) => p.key == _selectedProvinceKey).name}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateChip(
                            label: 'Giriş',
                            value: _formatDate(_checkIn),
                            onTap: () => _pickDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateChip(
                            label: 'Çıkış',
                            value: _formatDate(_checkOut),
                            onTap: () => _pickDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(minHeight: 50),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButton<SortOption>(
                        value: _sortOption,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        items: const [
                          DropdownMenuItem(value: SortOption.recommended, child: Text('Sıralama: Önerilen')),
                          DropdownMenuItem(value: SortOption.priceLowToHigh, child: Text('Sıralama: Fiyat Artan')),
                          DropdownMenuItem(value: SortOption.priceHighToLow, child: Text('Sıralama: Fiyat Azalan')),
                          DropdownMenuItem(value: SortOption.rating, child: Text('Sıralama: Puan Yüksek')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _sortOption = v;
                          });
                          _applySort();
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: _selectedProvinceKey == null ? null : _search,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                            shadowColor: Colors.transparent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Otelleri Ara',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hotels.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 90),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hotel, size: 72, color: Colors.white54),
                        const SizedBox(height: 12),
                        Text('Arama yaparak otelleri görebilirsin', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _hotels.length,
                  separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 24),
                  itemBuilder: (context, idx) {
                    final h = _hotels[idx];
                    return _HotelCard(
                      hotel: h,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Seçildi: ${h.name}')));
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateChip({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 3),
                    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final Hotel hotel;
  final VoidCallback onTap;

  const _HotelCard({required this.hotel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: hotel.imageUrl.isNotEmpty && !kIsWeb
                      ? Image.network(
                          hotel.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.white12, child: Icon(Icons.hotel, color: Colors.white70)),
                        )
                      : const ColoredBox(color: Colors.white12, child: Icon(Icons.hotel, color: Colors.white70)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (hotel.address.isNotEmpty)
                      Text(hotel.address, style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _MetaPill(text: '⭐ ${hotel.rating.toStringAsFixed(1)}', highlight: true),
                        _MetaPill(text: '${hotel.reviewCount} yorum'),
                        _MetaPill(text: hotel.pricePerNight != null ? '${hotel.pricePerNight!.toStringAsFixed(0)} ₺' : 'Fiyat yok', highlight: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String text;
  final bool highlight;

  const _MetaPill({required this.text, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.accentColor.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: highlight ? AppTheme.accentColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(text, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: highlight ? FontWeight.w600 : FontWeight.w500)),
    );
  }
}
