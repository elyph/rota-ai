import 'package:flutter/material.dart';
import '../models/flight_offer.dart';
import '../models/tourist_place.dart';
import '../models/hotel.dart';
import '../services/travel_plan_service.dart';
import '../services/flight_service.dart';
import '../services/places_service.dart';
import '../services/hotel_service.dart';
import '../services/itinerary_service.dart';

const _primary = Color(0xFF5374FF);
const _dark = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _light = Color(0xFFF8FAFC);
const _border = Color(0xFFF1F5F9);
const _white = Colors.white;

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
  final HotelService _hotelService = HotelService();
  final ItineraryService _itineraryService = ItineraryService();
  bool _editing = false;
  final Map<int, bool> _dayExpanded = {};
  bool _generatingItinerary = false;
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
    _itineraryService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flight = _plan['flight_info'] as Map<String, dynamic>?;
    final returnFlight = flight?['return_flight'] as Map<String, dynamic>?;
    final hotel = _plan['hotel_info'] as Map<String, dynamic>?;
    final places = _plan['selected_places'] as List<dynamic>?;
    final hasItinerary = _plan['itinerary'] != null && (_plan['itinerary'] as String).isNotEmpty;

    return Scaffold(
      backgroundColor: _light,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _dark),
        title: Text(
          _plan['title'] ?? 'Plan Detayı',
          style: const TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_editing ? Icons.check_circle_rounded : Icons.edit_outlined,
                color: _editing ? _primary : _muted),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rota özeti + durum
            _buildCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.flight_takeoff_rounded, size: 18, color: _primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${_plan['departure_city']} → ${_plan['arrival_city']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _dark),
                    ),
                  ),
                  _statusBadge(_plan['status']),
                ]),
                const SizedBox(height: 14),
                _infoRow(Icons.calendar_today_outlined, 'Gidiş',
                    _plan['departure_date'] ?? '-', _editing ? () => _editDate(isReturn: false) : null),
                _infoRow(Icons.calendar_today_outlined, 'Dönüş',
                    _plan['return_date'] ?? 'Eklenmemiş', _editing ? () => _editDate(isReturn: true) : null),
                if (_editing)
                  _infoRow(Icons.swap_horiz_rounded, 'Konum Değiştir',
                      'Planı sıfırla', () => _changeDestination()),
              ]),
            ),

            // Gidiş uçuşu
            _buildCard(
              header: _cardHeader(Icons.flight_takeoff, 'Gidiş Uçuşu',
                  action: _editing ? (flight != null ? 'Değiştir' : 'Ekle') : null,
                  onAction: _editing ? () => _editFlight(isReturn: false) : null),
              child: flight != null
                  ? _flightDetails(flight)
                  : _emptyHint('Gidiş uçuşu eklenmemiş'),
            ),

            // Dönüş uçuşu
            _buildCard(
              header: _cardHeader(Icons.flight_land, 'Dönüş Uçuşu',
                  action: _editing ? (returnFlight != null ? 'Değiştir' : 'Ekle') : null,
                  onAction: _editing ? () => _editFlight(isReturn: true) : null),
              child: returnFlight != null
                  ? _flightDetails(returnFlight)
                  : _emptyHint('Dönüş uçuşu eklenmemiş'),
            ),

            // Otel
            _buildCard(
              header: _cardHeader(Icons.hotel_rounded, 'Otel',
                  action: _editing ? (hotel != null ? 'Değiştir' : 'Ekle') : null,
                  onAction: _editing ? () => _editHotel() : null),
              child: hotel != null
                  ? GestureDetector(
                      onTap: () => _showHotelDetail(hotel),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _row('Otel Adı', hotel['name']?.toString() ?? '-'),
                      _row('Adres', hotel['address']?.toString() ?? '-'),
                      _row('Puan', '⭐ ${hotel['rating'] ?? '-'} (${hotel['reviewCount'] ?? 0} değerlendirme)'),
                      _row('Gecelik', hotel['price_per_night'] != null
                          ? '${(hotel['price_per_night'] as num).toStringAsFixed(0)} ₺' : '-'),
                      const SizedBox(height: 4),
                      Text('Detaylar için dokunun →', style: TextStyle(fontSize: 11, color: _primary.withValues(alpha: 0.7))),
                    ]))
                  : _emptyHint('Otel eklenmemiş'),
            ),

            // Gezilecek yerler
            _buildCard(
              header: _cardHeader(Icons.place_rounded,
                  'Gezilecek Yerler${places != null && places.isNotEmpty ? ' (${places.length})' : ''}',
                  action: _editing ? (places != null && places.isNotEmpty ? 'Değiştir' : 'Ekle') : null,
                  onAction: _editing ? () => _editPlaces() : null),
              child: places != null && places.isNotEmpty
                  ? Column(children: places.map((p) {
                      final place = p as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Container(width: 6, height: 6,
                              decoration: const BoxDecoration(color: _primary, shape: BoxShape.circle)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(place['name'] ?? '',
                              style: const TextStyle(fontSize: 13, color: _dark, fontWeight: FontWeight.w500))),
                          if (place['rating'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text('⭐ ${place['rating']}',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFFF59E0B))),
                            ),
                        ]),
                      );
                    }).toList())
                  : _emptyHint('Gezilecek yer eklenmemiş'),
            ),

            // AI Günlük Program
            _buildItinerarySection(hasItinerary),

            // Notlar
            _buildCard(
              header: _cardHeader(Icons.sticky_note_2_outlined, 'Notlar'),
              child: _editing
                  ? TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: const TextStyle(color: _dark, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Notlarınızı yazın...',
                        hintStyle: TextStyle(color: _muted.withValues(alpha: 0.6), fontSize: 13),
                        filled: true,
                        fillColor: _light,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: _primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    )
                  : Text(
                      _notesController.text.isEmpty ? 'Not eklenmemiş' : _notesController.text,
                      style: TextStyle(
                        color: _notesController.text.isEmpty ? _muted : _dark,
                        fontSize: 14,
                        fontStyle: _notesController.text.isEmpty ? FontStyle.italic : FontStyle.normal,
                        height: 1.5,
                      ),
                    ),
            ),

            // Durum değiştir
            if (_editing) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text('Durum', style: TextStyle(color: _muted, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Wrap(spacing: 8, runSpacing: 8, children: ['planned', 'ongoing', 'completed', 'cancelled'].map((s) {
                final selected = _plan['status'] == s;
                return ChoiceChip(
                  label: Text(_statusLabel(s)),
                  selected: selected,
                  onSelected: (v) { if (v) setState(() => _plan['status'] = s); },
                  selectedColor: _primary.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                      color: selected ? _primary : _muted,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.normal),
                  backgroundColor: _white,
                  side: BorderSide(color: selected ? _primary : _border),
                );
              }).toList()),
              const SizedBox(height: 20),
            ],

            // Sil butonu
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _deletePlan,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Planı Sil', style: TextStyle(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== UI HELPERS ==========

  Widget _buildCard({Widget? header, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (header != null) ...[header, const SizedBox(height: 12), const Divider(height: 1, color: _border)],
        SizedBox(height: header != null ? 12 : 0),
        child,
      ]),
    );
  }

  Widget _cardHeader(IconData icon, String title, {String? action, VoidCallback? onAction}) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 15, color: _primary),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark))),
      if (action != null)
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(action, style: const TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
        Icon(icon, size: 15, color: _muted),
        const SizedBox(width: 10),
        Text('$label  ', style: const TextStyle(color: _muted, fontSize: 13)),
        Expanded(child: Text(value, style: const TextStyle(color: _dark, fontSize: 13, fontWeight: FontWeight.w600))),
        if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFCBD5E1)),
      ])),
    );
  }

  Widget _flightDetails(Map<String, dynamic> f) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _row('Havayolu', '${f['airline']} · ${f['flight_number']}'),
      _row('Saat', '${f['departure_time']} → ${f['arrival_time']}'),
      _row('Süre', f['duration'] ?? '-'),
      _row('Fiyat', '${(f['price'] as num?)?.toStringAsFixed(0) ?? '?'} ₺'),
    ]);
  }

  Widget _row(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 7), child: Row(children: [
      Text('$label  ', style: const TextStyle(color: _muted, fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: _dark, fontSize: 13, fontWeight: FontWeight.w600))),
    ]));
  }

  Widget _emptyHint(String text) => Text(text, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontStyle: FontStyle.italic));

  Widget _statusBadge(String? status) {
    final map = {
      'planned': (_primary, const Color(0xFFEEF2FF), '🗓 Planlandı'),
      'ongoing': (const Color(0xFFF59E0B), const Color(0xFFFFFBEB), '🚀 Devam Ediyor'),
      'completed': (const Color(0xFF10B981), const Color(0xFFECFDF5), '✅ Tamamlandı'),
      'cancelled': (const Color(0xFFEF4444), const Color(0xFFFEF2F2), '❌ İptal'),
    };
    final (color, bg, label) = map[status] ?? (_primary, const Color(0xFFEEF2FF), '🗓 Planlandı');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  // ========== ITINERARY UI ==========

  Widget _buildItinerarySection(bool hasItinerary) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Başlık satırı
      Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
          child: const Icon(Icons.auto_awesome_rounded, size: 15, color: _primary),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Text('AI Günlük Program',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _dark))),
        if (hasItinerary)
          GestureDetector(
            onTap: _generateAiPlan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('Yeniden Oluştur',
                  style: TextStyle(color: _primary, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
      ]),
      const SizedBox(height: 12),

      if (!hasItinerary)
        _generatingItinerary ? _buildGeneratingIndicator() : _buildGenerateButton()
      else ..._parseAndBuildDays(_plan['itinerary'] as String),
    ]);
  }

  List<Widget> _parseAndBuildDays(String itinerary) {
    // ## ile başlayan günlere böl
    final dayRegex = RegExp(r'##\s+(\d+)\.\s*Gün[^\n]*', multiLine: true);
    final matches = dayRegex.allMatches(itinerary).toList();

    if (matches.isEmpty) {
      // parse edilemezse düz metin göster
      return [
        _buildCard(child: Text(itinerary,
            style: const TextStyle(fontSize: 13, color: _dark, height: 1.7))),
      ];
    }

    final List<Widget> cards = [];
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final header = m.group(0) ?? '';
      final start = m.end;
      final end = i + 1 < matches.length ? matches[i + 1].start : itinerary.length;
      final body = itinerary.substring(start, end).trim();
      final dayNum = int.tryParse(m.group(1) ?? '') ?? (i + 1);

      // Başlıktan tarihi çıkar
      final dateMatch = RegExp(r'\(([^)]+)\)').firstMatch(header);
      final dateStr = dateMatch?.group(1) ?? '';

      cards.add(_buildDayCard(dayNum: dayNum, dateStr: dateStr, body: body));
      cards.add(const SizedBox(height: 10));
    }
    return cards;
  }

  Widget _buildDayCard({required int dayNum, required String dateStr, required String body}) {
    final sections = _parseSections(body);
    final isExpanded = _dayExpanded[dayNum] ?? (dayNum == 1);

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Tıklanabilir gradient başlık
        GestureDetector(
          onTap: () => setState(() => _dayExpanded[dayNum] = !isExpanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, _primary.withValues(alpha: 0.75)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('$dayNum. Gün',
                    style: const TextStyle(color: _white, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(dateStr,
                      style: TextStyle(color: _white.withValues(alpha: 0.85), fontSize: 12)),
                ),
              ] else
                const Spacer(),
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded,
                    color: _white.withValues(alpha: 0.9), size: 22),
              ),
            ]),
          ),
        ),

        // İçerik
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (int i = 0; i < sections.length; i++) ...[
                _buildSection(sections[i]),
                if (i < sections.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, color: _border),
                  ),
              ],
            ]),
          ),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ]),
    );
  }

  List<_ItinerarySection> _parseSections(String body) {
    final patterns = [
      ('☀️', RegExp(r'☀️\s*\*?\*?Sabah:?\*?\*?', caseSensitive: false)),
      ('🌤', RegExp(r'🌤\s*\*?\*?Öğle:?\*?\*?', caseSensitive: false)),
      ('🌙', RegExp(r'🌙\s*\*?\*?Akşam:?\*?\*?', caseSensitive: false)),
      ('💡', RegExp(r'💡\s*\*?\*?İpuçları:?\*?\*?', caseSensitive: false)),
    ];

    final List<({int start, String emoji, String label})> found = [];
    for (final (emoji, rx) in patterns) {
      final m = rx.firstMatch(body);
      if (m != null) {
        final label = emoji == '☀️' ? 'Sabah' : emoji == '🌤' ? 'Öğle' : emoji == '🌙' ? 'Akşam' : 'İpuçları';
        found.add((start: m.start, emoji: emoji, label: label));
      }
    }
    found.sort((a, b) => a.start.compareTo(b.start));

    final sections = <_ItinerarySection>[];
    for (int i = 0; i < found.length; i++) {
      final f = found[i];
      final contentStart = body.indexOf('\n', f.start);
      final contentEnd = i + 1 < found.length ? found[i + 1].start : body.length;
      final content = contentStart >= 0 && contentStart < contentEnd
          ? body.substring(contentStart, contentEnd).trim()
          : '';
      sections.add(_ItinerarySection(emoji: f.emoji, label: f.label, content: _cleanText(content)));
    }

    // Hiç eşleşme yoksa tüm metni tek blok olarak ver
    if (sections.isEmpty && body.isNotEmpty) {
      sections.add(_ItinerarySection(emoji: '📋', label: 'Program', content: _cleanText(body)));
    }
    return sections;
  }

  String _cleanText(String t) {
    // Markdown bold (**text**) kaldır
    var result = t.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '');
    // Madde işaretlerini normalize et
    result = result
        .replaceAll(RegExp(r'^\s*\*\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'^\s*-\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    return result;
  }

  Widget _buildSection(_ItinerarySection section) {
    final colorMap = {
      '☀️': (const Color(0xFFFFF7ED), const Color(0xFFF97316)),
      '🌤': (const Color(0xFFEFF6FF), const Color(0xFF3B82F6)),
      '🌙': (const Color(0xFFF5F3FF), const Color(0xFF8B5CF6)),
      '💡': (const Color(0xFFFFFBEB), const Color(0xFFF59E0B)),
      '📋': (const Color(0xFFF8FAFC), _muted),
    };
    final (bg, accent) = colorMap[section.emoji] ?? (const Color(0xFFF8FAFC), _muted);

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(9)),
        child: Text(section.emoji, style: const TextStyle(fontSize: 14)),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(section.label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.3)),
        const SizedBox(height: 5),
        Text(section.content,
            style: const TextStyle(fontSize: 13, color: _dark, height: 1.65)),
      ])),
    ]);
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateAiPlan,
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('AI ile Program Oluştur', style: TextStyle(fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: _white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildGeneratingIndicator() {
    return Column(children: [
      const SizedBox(height: 8),
      const CircularProgressIndicator(color: _primary, strokeWidth: 2),
      const SizedBox(height: 12),
      const Text('AI programınız hazırlanıyor...', style: TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 8),
    ]);
  }

  // ========== AI PLAN ==========

  Future<void> _generateAiPlan() async {
    final places = _plan['selected_places'] as List<dynamic>?;
    final flight = _plan['flight_info'] as Map<String, dynamic>?;
    final hotel = _plan['hotel_info'] as Map<String, dynamic>?;

    setState(() => _generatingItinerary = true);
    _showSnack('✨ AI programınız hazırlanıyor...');

    try {
      final itinerary = await _itineraryService.generateItinerary(
        departureCity: _plan['departure_city'] ?? '',
        arrivalCity: _plan['arrival_city'] ?? '',
        departureDate: _plan['departure_date'] ?? '',
        returnDate: _plan['return_date']?.toString(),
        hotelName: hotel?['name']?.toString(),
        selectedPlaces: places
            ?.map((p) => {'name': (p as Map<String, dynamic>)['name'] ?? '', 'address': p['address'] ?? ''})
            .toList()
            .cast<Map<String, dynamic>>() ?? [],
        flightAirline: flight?['airline']?.toString(),
        flightDepartureTime: flight?['departure_time']?.toString(),
        returnFlightAirline: (flight?['return_flight'] as Map<String, dynamic>?)?['airline']?.toString(),
        returnFlightDepartureTime: (flight?['return_flight'] as Map<String, dynamic>?)?['departure_time']?.toString(),
      );
      setState(() => _plan['itinerary'] = itinerary);
      await _planService.updatePlan(_plan['id'], {'itinerary': itinerary});
      _showSnack('Program hazır!');
    } catch (e) {
      _showSnack('Hata: $e');
    } finally {
      setState(() => _generatingItinerary = false);
    }
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
      final f = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() { if (isReturn) _plan['return_date'] = f; else _plan['departure_date'] = f; });
      await _autoSave();
    }
  }

  Future<void> _editFlight({required bool isReturn}) async {
    final dateStr = isReturn ? _plan['return_date'] : _plan['departure_date'];
    if (dateStr == null || dateStr.toString().isEmpty || dateStr == 'Eklenmemiş') {
      _showSnack(isReturn ? 'Önce dönüş tarihi ekleyin!' : 'Gidiş tarihi bulunamadı!'); return;
    }
    final origin = isReturn ? (_plan['arrival_city'] ?? '') : (_plan['departure_city'] ?? '');
    final dest = isReturn ? (_plan['departure_city'] ?? '') : (_plan['arrival_city'] ?? '');
    if (origin.isEmpty || dest.isEmpty) { _showSnack('Kalkış veya varış bilgisi eksik!'); return; }
    DateTime date;
    try { date = DateTime.parse(dateStr.toString()); }
    catch (_) { _showSnack('Tarih formatı hatalı!'); return; }

    _showSnack('Uçuşlar aranıyor...');
    try {
      final flights = await _flightService.searchFlights(origin: origin, destination: dest, departureDate: date);
      if (!mounted) return;
      if (flights.isEmpty) { _showSnack('Uçuş bulunamadı!'); return; }
      final selected = await showModalBottomSheet<FlightOffer>(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (ctx) => _PickerSheet(
          title: isReturn ? 'Dönüş Uçuşu Seç' : 'Gidiş Uçuşu Seç',
          icon: Icons.flight,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: flights.length,
            itemBuilder: (ctx, i) {
              final f = flights[i];
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, f),
                child: _pickerItem(
                  title: f.airline,
                  subtitle: '${f.departureTime} → ${f.arrivalTime}  ·  ${f.duration}',
                  trailing: '${f.priceTL.toStringAsFixed(0)} ₺',
                ),
              );
            },
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          final fd = {'airline': selected.airline, 'flight_number': selected.flightNumber,
            'departure_time': selected.departureTime, 'arrival_time': selected.arrivalTime,
            'price': selected.priceTL, 'duration': selected.duration};
          if (isReturn) {
            if (_plan['flight_info'] == null) _plan['flight_info'] = <String, dynamic>{};
            (_plan['flight_info'] as Map<String, dynamic>)['return_flight'] = fd;
          } else {
            Map<String, dynamic>? ret;
            if (_plan['flight_info'] != null)
              ret = (_plan['flight_info'] as Map<String, dynamic>)['return_flight'] as Map<String, dynamic>?;
            _plan['flight_info'] = Map<String, dynamic>.from(fd);
            if (ret != null) (_plan['flight_info'] as Map<String, dynamic>)['return_flight'] = ret;
          }
        });
        await _autoSave();
      }
    } catch (e) { _showSnack('Hata: $e'); }
  }

  void _showHotelDetail(Map<String, dynamic> hotel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder: (ctx, scrollController) {
            final rating = (hotel['rating'] is num) ? (hotel['rating'] as num).toDouble() : double.tryParse(hotel['rating']?.toString() ?? '0') ?? 0;
            final reviewCount = (hotel['reviewCount'] is int) ? hotel['reviewCount'] as int : int.tryParse(hotel['reviewCount']?.toString() ?? '0') ?? 0;
            final stars = (hotel['stars'] is int) ? hotel['stars'] as int : int.tryParse(hotel['stars']?.toString() ?? '0') ?? rating.round();
            final price = (hotel['price_per_night'] is num) ? (hotel['price_per_night'] as num).toDouble() : null;
            final amenities = (hotel['amenities'] is List) ? (hotel['amenities'] as List).map((e) => e.toString()).toList() : <String>[];
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
                          width: 130, height: 130,
                          child: (hotel['image_url']?.toString().isNotEmpty ?? false)
                              ? Image.network(hotel['image_url']!, fit: BoxFit.cover,
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
                            Text(hotel['name']?.toString() ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
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
                                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('$reviewCount değerlendirme', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                for (int i = 0; i < stars; i++)
                                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFBBF24)),
                                for (int i = stars; i < 5; i++)
                                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFE2E8F0)),
                                const SizedBox(width: 8),
                                Text('$stars yıldız', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              ],
                            ),
                            if (price != null) ...[
                              const SizedBox(height: 8),
                              Text('₺${price.toStringAsFixed(0)} / gece', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF5374FF))),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if ((hotel['address']?.toString() ?? '').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Adres', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(hotel['address'] ?? '', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4))),
                      ],
                    ),
                  ],
                  if (amenities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Olanaklar', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities.map((a) {
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

  Future<void> _editHotel() async {
    final iata = (_plan['arrival_city'] ?? '').toString().toUpperCase();
    final city = _iataToCity(iata);
    if (city.isEmpty) { _showSnack('Varış şehri bulunamadı!'); return; }
    final checkInStr = _plan['departure_date']?.toString();
    final checkOutStr = _plan['return_date']?.toString();
    if (checkInStr == null || checkInStr.isEmpty) { _showSnack('Gidiş tarihi bulunamadı!'); return; }
    DateTime checkIn;
    try { checkIn = DateTime.parse(checkInStr); } catch (_) { _showSnack('Tarih hatası!'); return; }
    DateTime checkOut;
    try { checkOut = checkOutStr != null ? DateTime.parse(checkOutStr) : checkIn.add(const Duration(days: 1)); }
    catch (_) { checkOut = checkIn.add(const Duration(days: 1)); }

    _showSnack('Oteller yükleniyor...');
    try {
      final hotels = await _hotelService.searchHotels(city: city, checkIn: checkIn, checkOut: checkOut);
      if (!mounted) return;
      if (hotels.isEmpty) { _showSnack('Otel bulunamadı!'); return; }

      Hotel? detailHotel;

      final selected = await showModalBottomSheet<Hotel>(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (ctx) => _PickerSheet(
          title: 'Otel Seç',
          icon: Icons.hotel_rounded,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: hotels.length,
            itemBuilder: (ctx, i) {
              final h = hotels[i];
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, h),
                child: _pickerItem(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 52, height: 52,
                      child: h.imageUrl.isNotEmpty
                          ? Image.network(h.imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF1F5F9),
                                  child: Icon(Icons.hotel, color: Color(0xFF94A3B8))))
                          : const ColoredBox(color: Color(0xFFF1F5F9),
                              child: Icon(Icons.hotel, color: Color(0xFF94A3B8)))),
                  ),
                  title: h.name,
                  subtitle: '⭐ ${h.rating.toStringAsFixed(1)}  ·  ${h.pricePerNight?.toStringAsFixed(0) ?? '-'} ₺/gece',
                  trailing: GestureDetector(
                    onTap: () { detailHotel = h; Navigator.pop(ctx); },
                    child: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                  ),
                ),
              );
            },
          ),
        ),
      );

      if (selected != null) {
        setState(() { _plan['hotel_info'] = {'id': selected.id, 'name': selected.name,
          'address': selected.address, 'rating': selected.rating,
          'reviewCount': selected.reviewCount, 'stars': selected.stars,
          'price_per_night': selected.pricePerNight, 'image_url': selected.imageUrl,
          'amenities': selected.amenities}; });
        await _autoSave();
      } else if (detailHotel != null && mounted) {
        Future.microtask(() => _showHotelDetail(detailHotel!.toJson()));
      }
    } catch (e) { _showSnack('Hata: $e'); }
  }

  Future<void> _editPlaces() async {
    final iata = (_plan['arrival_city'] ?? '').toString().toUpperCase();
    final city = _iataToCity(iata);
    if (city.isEmpty) { _showSnack('Varış şehri bulunamadı!'); return; }
    _showSnack('Yerler yükleniyor...');
    try {
      final places = await _placesService.getNearbyPlaces(city: city);
      final top10 = (places.where((p) => p.rating >= 3.0).toList()
        ..sort((a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal))).take(10).toList();
      if (!mounted) return;
      if (top10.isEmpty) { _showSnack('Bu şehirde yer bulunamadı!'); return; }
      final currentPlaces = (_plan['selected_places'] as List<dynamic>?)
          ?.map((p) => ((p as Map<String, dynamic>)['name'] ?? '').toString()).toSet() ?? <String>{};
      final selected = await showModalBottomSheet<List<TouristPlace>>(
        context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (ctx) => _PlacesPicker(places: top10, initialSelected: currentPlaces),
      );
      if (selected != null) {
        setState(() { _plan['selected_places'] = selected.map((y) =>
            {'name': y.name, 'address': y.address, 'rating': y.rating}).toList(); });
        await _autoSave();
      }
    } catch (e) { _showSnack('Hata: $e'); }
  }

  Widget _pickerItem({Widget? leading, required String title, required String subtitle, dynamic trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _light,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        if (leading != null) ...[leading, const SizedBox(width: 12)],
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: _dark, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
        ])),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          if (trailing is Widget)
            trailing
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(trailing.toString(), style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ],
      ]),
    );
  }

  String _iataToCity(String iata) {
    const m = {
      'IST': 'istanbul', 'SAW': 'istanbul', 'ESB': 'ankara', 'AYT': 'antalya',
      'ADB': 'izmir', 'DLM': 'muğla', 'BJV': 'muğla', 'TZX': 'trabzon',
      'ADA': 'adana', 'NAV': 'nevşehir', 'GZT': 'gaziantep',
      'ERZ': 'erzurum', 'SZF': 'samsun', 'ECN': 'lefkoşa',
    };
    return m[iata] ?? iata.toLowerCase();
  }

  Future<void> _changeDestination() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Konum Değiştir'),
      content: const Text('Uçuşlar ve gezilecek yerler sıfırlanacak. Devam edilsin mi?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Devam', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ));
    if (ok != true || !mounted) return;
    await _planService.deletePlan(_plan['id']);
    if (mounted) { Navigator.pop(context, true); _showSnack('Plan sıfırlandı.'); }
  }

  Future<void> _autoSave() async {
    try {
      await _planService.updatePlan(_plan['id'], {
        'departure_date': _plan['departure_date'], 'return_date': _plan['return_date'],
        'flight_info': _plan['flight_info'], 'hotel_info': _plan['hotel_info'],
        'selected_places': _plan['selected_places'], 'notes': _notesController.text,
        'status': _plan['status'], 'itinerary': _plan['itinerary'],
      });
    } catch (e) { _showSnack('Kaydetme hatası: $e'); }
  }

  Future<void> _deletePlan() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Planı Sil'),
      content: const Text('Bu planı silmek istediğinize emin misiniz?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Color(0xFFEF4444)))),
      ],
    ));
    if (ok == true) { await _planService.deletePlan(_plan['id']); if (mounted) Navigator.pop(context, true); }
  }

  String _statusLabel(String? s) {
    switch (s) {
      case 'planned': return 'Planlandı';
      case 'ongoing': return 'Devam Ediyor';
      case 'completed': return 'Tamamlandı';
      case 'cancelled': return 'İptal Edildi';
      default: return 'Planlandı';
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: _dark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ========== PICKER SHEET ==========
class _PickerSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _PickerSheet({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36, height: 4,
          decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 8, 8), child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: _primary),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close_rounded, color: _muted), onPressed: () => Navigator.pop(context)),
        ])),
        const Divider(height: 1, color: _border),
        Expanded(child: child),
      ]),
    );
  }
}

// ========== PLACES PICKER ==========
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
      decoration: const BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36, height: 4,
          decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 8, 8), child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: const Icon(Icons.place_rounded, size: 16, color: _primary),
          ),
          const SizedBox(width: 10),
          const Text('Gezilecek Yerler', style: TextStyle(color: _dark, fontSize: 17, fontWeight: FontWeight.w800)),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context, _selected),
            child: Text('Kaydet (${_selected.length})',
                style: const TextStyle(color: _primary, fontWeight: FontWeight.w700)),
          ),
        ])),
        const Divider(height: 1, color: _border),
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: widget.places.length,
          itemBuilder: (ctx, i) {
            final yer = widget.places[i];
            final sel = _selected.contains(yer);
            return GestureDetector(
              onTap: () => setState(() { if (sel) _selected.remove(yer); else _selected.add(yer); }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFEEF2FF) : _light,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? _primary.withValues(alpha: 0.4) : _border,
                      width: sel ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(sel ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                      color: sel ? _primary : const Color(0xFFCBD5E1), size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(yer.name, style: const TextStyle(color: _dark, fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('${yer.address}  ·  ⭐ ${yer.rating}',
                        style: const TextStyle(color: _muted, fontSize: 11)),
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

class _ItinerarySection {
  final String emoji;
  final String label;
  final String content;
  const _ItinerarySection({required this.emoji, required this.label, required this.content});
}
