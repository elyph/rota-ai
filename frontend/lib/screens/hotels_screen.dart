import 'package:flutter/material.dart';
import '../services/hotel_service.dart';
import '../models/hotel.dart';
import '../helpers/turkey_provinces.dart';

enum SortOption { recommended, priceLowToHigh, priceHighToLow, score }

class HotelsScreen extends StatefulWidget {
  const HotelsScreen({super.key});

  @override
  State<HotelsScreen> createState() => _HotelsScreenState();
}

class _HotelsScreenState extends State<HotelsScreen> {
  String? _selectedProvinceKey;
  String? _selectedProvinceName;
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 2));
  bool _loading = false;
  List<Hotel> _hotels = [];
  SortOption _sortOption = SortOption.recommended;
  bool _searched = false;

  final _service = HotelService();

  static const _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _formatDate(DateTime date) {
    return '${date.day} ${_aylar[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF5374FF),
              brightness: Brightness.light,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
          _checkOut = _checkIn.add(const Duration(days: 1));
        }
      } else {
        _checkOut = picked;
        if (_checkOut.isBefore(_checkIn) || _checkOut.isAtSameMomentAs(_checkIn)) {
          _checkIn = _checkOut.subtract(const Duration(days: 1));
        }
      }
    });
  }

  Future<void> _search() async {
    if (_selectedProvinceKey == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen bir il seçin.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    setState(() { _loading = true; _hotels = []; _searched = true; });
    try {
      final results = await _service.searchHotels(
        city: _selectedProvinceKey!,
        checkIn: _checkIn,
        checkOut: _checkOut,
      );
      setState(() { _hotels = results; });
      _applySort();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arama başarısız: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  void _applySort() {
    setState(() {
      switch (_sortOption) {
        case SortOption.priceLowToHigh:
          _hotels.sort((a, b) => (a.pricePerNight ?? double.infinity).compareTo(b.pricePerNight ?? double.infinity));
          break;
        case SortOption.priceHighToLow:
          _hotels.sort((a, b) => (b.pricePerNight ?? 0).compareTo(a.pricePerNight ?? 0));
          break;
        case SortOption.score:
          _hotels.sort((a, b) => b.score.compareTo(a.score));
          break;
        case SortOption.recommended:
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button (only when pushed)
              if (Navigator.canPop(context)) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Otel Ara',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Konaklama seçeneklerini keşfet',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // Search card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City selector
                    GestureDetector(
                      onTap: _showCityPicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF5374FF)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedProvinceName ?? 'Şehir seçin',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: _selectedProvinceName != null ? FontWeight.w600 : FontWeight.w400,
                                  color: _selectedProvinceName != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date selectors
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateChip('Giriş', _checkIn, () => _pickDate(true)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDateChip('Çıkış', _checkOut, () => _pickDate(false)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5374FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Otelleri Ara', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Results
              if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF5374FF))),
                )
              else if (_searched && _hotels.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.hotel_rounded, size: 56, color: Color(0xFF94A3B8)),
                        SizedBox(height: 12),
                        Text('Otel bulunamadı', style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                )
              else if (_hotels.isNotEmpty) ...[
                // Sort bar
                Row(
                  children: [
                    Text(
                      '${_hotels.length} otel bulundu',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    ),
                    const Spacer(),
                    _buildSortChip(),
                  ],
                ),
                const SizedBox(height: 12),
                // Hotel list
                ...List.generate(_hotels.length, (i) => _buildHotelCard(_hotels[i], () => _showHotelDetail(_hotels[i]))),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.hotel_rounded, size: 56, color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        const Text('Arama yaparak otelleri görebilirsin', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF5374FF)),
                const SizedBox(width: 6),
                Text(
                  _formatDate(date),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip() {
    return GestureDetector(
      onTap: () {
        setState(() {
          final values = SortOption.values;
          final next = (values.indexOf(_sortOption) + 1) % values.length;
          _sortOption = values[next];
        });
        _applySort();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              _sortLabel(),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  String _sortLabel() {
    switch (_sortOption) {
      case SortOption.priceLowToHigh: return 'Ucuz';
      case SortOption.priceHighToLow: return 'Pahalı';
      case SortOption.score: return 'Puan';
      default: return 'Önerilen';
    }
  }

  Widget _buildHotelCard(Hotel hotel, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFFF1F5F9),
              child: hotel.imageUrl.isNotEmpty
                  ? Image.network(
                      hotel.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.hotel_rounded, color: Color(0xFF94A3B8)),
                    )
                  : const Icon(Icons.hotel_rounded, color: Color(0xFF94A3B8)),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (hotel.address.isNotEmpty)
                  Text(
                    hotel.address,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    Text(
                      hotel.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${hotel.reviewCount})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                    const Spacer(),
                    if (hotel.pricePerNight != null)
                      Text(
                        '₺${hotel.pricePerNight!.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showHotelDetail(Hotel hotel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 130,
                          height: 130,
                          child: hotel.imageUrl.isNotEmpty
                              ? Image.network(hotel.imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.hotel_rounded, size: 48, color: Color(0xFF94A3B8)),
                                  ))
                              : Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(Icons.hotel_rounded, size: 48, color: Color(0xFF94A3B8)),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hotel.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 4),
                                      Text(
                                        hotel.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${hotel.reviewCount} değerlendirme',
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (int i = 0; i < hotel.stars; i++)
                                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
                                for (int i = hotel.stars; i < 5; i++)
                                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFE2E8F0)),
                                const SizedBox(width: 8),
                                Text('${hotel.stars} yıldız', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              ],
                            ),
                            if (hotel.pricePerNight != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '₺${hotel.pricePerNight!.toStringAsFixed(0)} / gece',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF5374FF)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (hotel.address.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Adres', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(hotel.address, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4))),
                      ],
                    ),
                  ],
                  if (hotel.amenities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Olanaklar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hotel.amenities.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(a, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Şehir Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: turkeyProvinces.length,
                      itemBuilder: (context, index) {
                        final province = turkeyProvinces[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          title: Text(province.name, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                          onTap: () {
                            setState(() {
                              _selectedProvinceKey = province.key;
                              _selectedProvinceName = province.name;
                              _hotels = [];
                              _searched = false;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
