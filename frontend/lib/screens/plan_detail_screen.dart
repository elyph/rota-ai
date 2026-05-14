import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/flight_offer.dart';
import '../models/tourist_place.dart';
import '../services/travel_plan_service.dart';
import '../services/flight_service.dart';
import '../services/places_service.dart';

class PlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  const PlanDetailScreen({super.key, required this.plan});

  @override
  State<PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<PlanDetailScreen> {
  late Map<String, dynamic> _plan;
  final TravelPlanService _planService = TravelPlanService();
  final FlightService _flightService = FlightService();
  final PlacesService _placesService = PlacesService();
  bool _editing = false;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _plan = Map<String, dynamic>.from(widget.plan);
    _notesController = TextEditingController(text: _plan['notes'] ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flight = _plan['flight_info'] as Map<String, dynamic>?;
    final returnFlight = flight?['return_flight'] as Map<String, dynamic>?;
    final hotel = _plan['hotel_info'] as Map<String, dynamic>?;
    final places = _plan['selected_places'] as List<dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(_plan['title'] ?? 'Plan Detayı'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.check : Icons.edit),
            onPressed: () async {
              if (_editing) {
                await _planService.updatePlan(_plan['id'], {
                  'notes': _notesController.text,
                  'status': _plan['status'],
                  'departure_date': _plan['departure_date'],
                  'return_date': _plan['return_date'],
                  'flight_info': _plan['flight_info'],
                  'selected_places': _plan['selected_places'],
                });
                _showSnack('Plan güncellendi!');
              }
              setState(() => _editing = !_editing);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Rota ve tarih
              _buildSection(
                icon: Icons.flight,
                title: '${_plan['departure_city']} → ${_plan['arrival_city']}',
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildEditableRow(Icons.calendar_today, 'Gidiş', _plan['departure_date'] ?? '-', _editing ? () => _editDate(isReturn: false) : null),
                  _buildEditableRow(Icons.calendar_today, 'Dönüş', _plan['return_date'] ?? 'Eklenmemiş', _editing ? () => _editDate(isReturn: true) : null),
                  _buildEditableRow(Icons.info_outline, 'Durum', _statusLabel(_plan['status']), null),
                  if (_editing) ...[
                    const SizedBox(height: 8),
                    _buildEditableRow(Icons.swap_horiz, 'Konum Değiştir', 'Tüm planı sıfırla', () => _changeDestination()),
                  ],
                ]),
              ),

              // Gidiş uçuşu
              _buildSection(
                icon: Icons.flight_takeoff,
                title: 'Gidiş Uçuşu',
                actionLabel: _editing ? (flight != null ? 'Değiştir' : 'Ekle') : null,
                onAction: _editing ? () => _editFlight(isReturn: false) : null,
                child: flight != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _row('Havayolu', '${flight['airline']} - ${flight['flight_number']}'),
                        _row('Saat', '${flight['departure_time']} → ${flight['arrival_time']}'),
                        _row('Süre', flight['duration'] ?? '-'),
                        _row('Fiyat', '${(flight['price'] as num?)?.toStringAsFixed(0) ?? '?'} ₺'),
                      ])
                    : Text('Gidiş uçuşu eklenmemiş', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
              ),

              // Dönüş uçuşu
              _buildSection(
                icon: Icons.flight_land,
                title: 'Dönüş Uçuşu',
                actionLabel: _editing ? (returnFlight != null ? 'Değiştir' : 'Ekle') : null,
                onAction: _editing ? () => _editFlight(isReturn: true) : null,
                child: returnFlight != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _row('Havayolu', '${returnFlight['airline']} - ${returnFlight['flight_number']}'),
                        _row('Saat', '${returnFlight['departure_time']} → ${returnFlight['arrival_time']}'),
                        _row('Süre', returnFlight['duration'] ?? '-'),
                        _row('Fiyat', '${(returnFlight['price'] as num?)?.toStringAsFixed(0) ?? '?'} ₺'),
                      ])
                    : Text('Dönüş uçuşu eklenmemiş', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
              ),

              // Otel
              _buildSection(
                icon: Icons.hotel,
                title: 'Otel',
                actionLabel: _editing ? 'Ekle' : null,
                onAction: _editing ? () => _showSnack('Otel seçimi için Planlama ekranından yeni plan oluşturabilirsin.') : null,
                child: hotel != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _row('Otel Adı', hotel['name']?.toString() ?? '-'),
                        _row('Adres', hotel['address']?.toString() ?? '-'),
                        _row('Puan', hotel['rating']?.toString() ?? '-'),
                        _row('Gecelik', hotel['price_per_night'] != null ? '${(hotel['price_per_night'] as num).toStringAsFixed(0)} ₺' : '-'),
                      ])
                    : Text('Otel eklenmemiş', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
              ),

              // Gezilecek yerler
              _buildSection(
                icon: Icons.place,
                title: 'Gezilecek Yerler${places != null && places.isNotEmpty ? ' (${places.length})' : ''}',
                actionLabel: _editing ? (places != null && places.isNotEmpty ? 'Değiştir' : 'Ekle') : null,
                onAction: _editing ? () => _editPlaces() : null,
                child: places != null && places.isNotEmpty
                    ? Column(children: places.map((p) {
                        final place = p as Map<String, dynamic>;
                        return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                          const Icon(Icons.place, size: 14, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(child: Text(place['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13))),
                          if (place['rating'] != null) Text('⭐ ${place['rating']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                        ]));
                      }).toList())
                    : Text('Gezilecek yer eklenmemiş', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontStyle: FontStyle.italic)),
              ),

              // Notlar
              _buildSection(
                icon: Icons.note,
                title: 'Notlar',
                child: _editing
                    ? TextField(controller: _notesController, maxLines: 4, style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(hintText: 'Notlarınızı yazın...', hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)), border: InputBorder.none))
                    : Text(_notesController.text.isEmpty ? 'Not eklenmemiş' : _notesController.text,
                        style: TextStyle(color: Colors.white.withValues(alpha: _notesController.text.isEmpty ? 0.5 : 0.9), fontSize: 14, fontStyle: _notesController.text.isEmpty ? FontStyle.italic : FontStyle.normal)),
              ),

              // Durum değiştir
              if (_editing) ...[
                _sectionTitle('Durum'),
                Wrap(spacing: 8, children: ['planned', 'ongoing', 'completed', 'cancelled'].map((s) {
                  final selected = _plan['status'] == s;
                  return ChoiceChip(label: Text(_statusLabel(s)), selected: selected,
                    onSelected: (v) { if (v) setState(() => _plan['status'] = s); },
                    selectedColor: Colors.green.withValues(alpha: 0.3),
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70, fontSize: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    side: BorderSide(color: selected ? Colors.green : Colors.white24));
                }).toList()),
                const SizedBox(height: 24),
              ],

              // Sil butonu
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
                onPressed: _deletePlan,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Planı Sil'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withValues(alpha: 0.8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required IconData icon, required String title, required Widget child, String? actionLabel, VoidCallback? onAction}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(8)),
                child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _buildEditableRow(IconData icon, String label, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        if (onTap != null) Icon(Icons.edit, size: 14, color: Colors.white.withValues(alpha: 0.4)),
      ])),
    );
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
      Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
    ]));
  }

  Widget _sectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)));
  }

  // ========== EDIT ACTIONS ==========

  Future<void> _editDate({required bool isReturn}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isReturn) { _plan['return_date'] = formatted; }
        else { _plan['departure_date'] = formatted; }
      });
      await _autoSave();
    }
  }

  Future<void> _editFlight({required bool isReturn}) async {
    // Tarih kontrolü
    final dateStr = isReturn ? _plan['return_date'] : _plan['departure_date'];
    if (dateStr == null || dateStr.toString().isEmpty || dateStr == 'Eklenmemiş') {
      _showSnack(isReturn ? 'Önce dönüş tarihi ekleyin!' : 'Gidiş tarihi bulunamadı!');
      return;
    }

    final origin = isReturn ? (_plan['arrival_city'] ?? '') : (_plan['departure_city'] ?? '');
    final dest = isReturn ? (_plan['departure_city'] ?? '') : (_plan['arrival_city'] ?? '');
    
    if (origin.isEmpty || dest.isEmpty) {
      _showSnack('Kalkış veya varış bilgisi eksik!');
      return;
    }

    DateTime date;
    try {
      date = DateTime.parse(dateStr.toString());
    } catch (_) {
      _showSnack('Tarih formatı hatalı!');
      return;
    }

    // Uçuşları ara ve seçtir
    _showSnack('Uçuşlar aranıyor...');
    try {
      final flights = await _flightService.searchFlights(origin: origin, destination: dest, departureDate: date);
      if (!mounted) return;
      if (flights.isEmpty) { _showSnack('Uçuş bulunamadı!'); return; }

      final selected = await showModalBottomSheet<FlightOffer>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _buildFlightPicker(flights, isReturn),
      );

      if (selected != null) {
        setState(() {
          final flightData = {
            'airline': selected.airline,
            'flight_number': selected.flightNumber,
            'departure_time': selected.departureTime,
            'arrival_time': selected.arrivalTime,
            'price': selected.priceTL,
            'duration': selected.duration,
          };
          if (isReturn) {
            if (_plan['flight_info'] == null) _plan['flight_info'] = <String, dynamic>{};
            (_plan['flight_info'] as Map<String, dynamic>)['return_flight'] = flightData;
          } else {
            Map<String, dynamic>? existingReturn;
            if (_plan['flight_info'] != null) {
              existingReturn = (_plan['flight_info'] as Map<String, dynamic>)['return_flight'] as Map<String, dynamic>?;
            }
            _plan['flight_info'] = Map<String, dynamic>.from(flightData);
            if (existingReturn != null) {
              (_plan['flight_info'] as Map<String, dynamic>)['return_flight'] = existingReturn;
            }
          }
        });
        await _autoSave();
      }
    } catch (e) { _showSnack('Hata: $e'); }
  }

  Widget _buildFlightPicker(List<FlightOffer> flights, bool isReturn) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Text(isReturn ? 'Dönüş Uçuşu Seç' : 'Gidiş Uçuşu Seç', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        ])),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: flights.length,
          itemBuilder: (ctx, i) {
            final f = flights[i];
            return GestureDetector(
              onTap: () => Navigator.pop(context, f),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('${f.departureTime} → ${f.arrivalTime}  •  ${f.duration}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ])),
                  Text('${f.priceTL.toStringAsFixed(0)} ₺', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }

  Future<void> _editPlaces() async {
    // IATA kodunu şehir adına çevir
    final iataCode = (_plan['arrival_city'] ?? '').toString().toUpperCase();
    final cityName = _iataToCity(iataCode);
    if (cityName.isEmpty) { _showSnack('Varış şehri bulunamadı!'); return; }
    
    _showSnack('Yerler yükleniyor...');
    try {
      final places = await _placesService.getNearbyPlaces(city: cityName);
      final filtered = places.where((p) => p.rating >= 3.0).toList()..sort((a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal));
      final top10 = filtered.take(10).toList();
      if (!mounted) return;

      if (top10.isEmpty) { _showSnack('Bu şehirde yer bulunamadı!'); return; }

      // Mevcut seçili yerlerin isimlerini al
      final currentPlaces = (_plan['selected_places'] as List<dynamic>?)
          ?.map((p) => ((p as Map<String, dynamic>)['name'] ?? '').toString())
          .toSet() ?? <String>{};

      final selected = await showModalBottomSheet<List<TouristPlace>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _PlacesPicker(places: top10, initialSelected: currentPlaces),
      );

      if (selected != null) {
        setState(() {
          _plan['selected_places'] = selected.map((y) => {'name': y.name, 'address': y.address, 'rating': y.rating}).toList();
        });
        await _autoSave();
      }
    } catch (e) { _showSnack('Hata: $e'); }
  }

  String _iataToCity(String iata) {
    const mapping = {
      'IST': 'istanbul', 'SAW': 'istanbul',
      'ESB': 'ankara',
      'AYT': 'antalya',
      'ADB': 'izmir',
      'DLM': 'muğla', 'BJV': 'muğla',
      'TZX': 'trabzon',
      'ADA': 'adana',
      'NAV': 'nevşehir',
      'GZT': 'gaziantep',
      'ERZ': 'erzurum',
      'SZF': 'samsun',
      'ECN': 'lefkoşa',
    };
    return mapping[iata] ?? iata.toLowerCase();
  }

  Future<void> _changeDestination() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Konum Değiştir'),
      content: const Text('Konum değiştirilirse uçuşlar ve gezilecek yerler sıfırlanacak. Devam etmek istiyor musunuz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Devam', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm != true || !mounted) return;

    // Planı sil ve wizard'a yönlendir
    await _planService.deletePlan(_plan['id']);
    if (mounted) {
      Navigator.pop(context, true); // Profil ekranına dön, oradan yeni plan oluşturulabilir
      _showSnack('Plan sıfırlandı. Yeni plan oluşturabilirsiniz.');
    }
  }

  Future<void> _autoSave() async {
    try {
      await _planService.updatePlan(_plan['id'], {
        'departure_date': _plan['departure_date'],
        'return_date': _plan['return_date'],
        'flight_info': _plan['flight_info'],
        'selected_places': _plan['selected_places'],
        'notes': _notesController.text,
        'status': _plan['status'],
      });
    } catch (e) {
      _showSnack('Kaydetme hatası: $e');
    }
  }

  Future<void> _deletePlan() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Planı Sil'),
      content: const Text('Bu planı silmek istediğinize emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm == true) {
      await _planService.deletePlan(_plan['id']);
      if (mounted) Navigator.pop(context, true);
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'planned': return 'Planlandı';
      case 'ongoing': return 'Devam Ediyor';
      case 'completed': return 'Tamamlandı';
      case 'cancelled': return 'İptal Edildi';
      default: return 'Planlandı';
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}

// ========== PLACES PICKER BOTTOM SHEET ==========
class _PlacesPicker extends StatefulWidget {
  final List<TouristPlace> places;
  final Set<String> initialSelected;
  const _PlacesPicker({required this.places, required this.initialSelected});

  @override
  State<_PlacesPicker> createState() => _PlacesPickerState();
}

class _PlacesPickerState extends State<_PlacesPicker> {
  late List<TouristPlace> _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.places.where((p) => widget.initialSelected.contains(p.name)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Color(0xFF1a1a2e), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          const Text('Gezilecek Yerler', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          TextButton(onPressed: () => Navigator.pop(context, _selected), child: Text('Kaydet (${_selected.length})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        ])),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: widget.places.length,
          itemBuilder: (ctx, i) {
            final yer = widget.places[i];
            final selected = _selected.contains(yer);
            return GestureDetector(
              onTap: () { setState(() { if (selected) _selected.remove(yer); else _selected.add(yer); }); },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? Colors.green : Colors.white.withValues(alpha: 0.15), width: selected ? 2 : 1),
                ),
                child: Row(children: [
                  if (selected) const Icon(Icons.check_circle, color: Colors.green, size: 20) else Icon(Icons.radio_button_off, color: Colors.white.withValues(alpha: 0.4), size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(yer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('${yer.address}  •  ⭐ ${yer.rating}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                  ])),
                ]),
              ),
            );
          },
        )),
      ]),
    );
  }
}
