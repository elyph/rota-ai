import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/airport.dart';
import '../models/flight_offer.dart';
import '../models/tourist_place.dart';
import '../services/flight_service.dart';
import '../services/places_service.dart';
import '../services/travel_plan_service.dart';
import '../widgets/airport_dropdown.dart';
import '../services/hotel_service.dart';
import '../models/hotel.dart';

class PlanWizardScreen extends StatefulWidget {
  const PlanWizardScreen({super.key});
  @override
  State<PlanWizardScreen> createState() => _PlanWizardScreenState();
}

class _PlanWizardScreenState extends State<PlanWizardScreen> {
  // Steps: 0=bilgiler, 1=gidis ucus, 2=donus ucus, 3=otel, 4=yerler, 5=onay
  int _currentStep = 0;
  Airport? _kalkis;
  Airport? _varis;
  DateTime? _gidisTarihi;
  DateTime? _donusTarihi;

  List<FlightOffer>? _gidisUcuslari;
  FlightOffer? _secilenGidisUcus;
  List<FlightOffer>? _donusUcuslari;
  FlightOffer? _secilenDonusUcus;
  bool _ucusYukleniyor = false;

  List<TouristPlace>? _yerler;
  List<TouristPlace> _secilenYerler = [];
  bool _yerlerYukleniyor = false;

  List<Hotel>? _hoteller;
  Hotel? _secilenOtel;
  bool _hotellerYukleniyor = false;
  final TextEditingController _otelSehirController = TextEditingController();

  final FlightService _flightService = FlightService();
  final PlacesService _placesService = PlacesService();
  final TravelPlanService _planService = TravelPlanService();
  final HotelService _hotelService = HotelService();

  int get _totalSteps => _donusTarihi != null ? 6 : 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getStepTitle()),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(child: _buildCurrentStep()),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0: return 'Uçuş Bilgileri';
      case 1: return 'Gidiş Uçuşu Seç';
      case 2: return _donusTarihi != null ? 'Dönüş Uçuşu Seç' : 'Otel Seç';
      case 3: return _donusTarihi != null ? 'Otel Seç' : 'Gezilecek Yerler';
      case 4: return _donusTarihi != null ? 'Gezilecek Yerler' : 'Planı Onayla';
      case 5: return 'Planı Onayla';
      default: return 'Seyahat Planla';
    }
  }

  Widget _buildCurrentStep() {
    if (_donusTarihi != null) {
      switch (_currentStep) {
        case 0: return _buildFlightInfoStep();
        case 1: return _buildFlightSelectStep(isReturn: false);
        case 2: return _buildFlightSelectStep(isReturn: true);
        case 3: return _buildHotelStep();
        case 4: return _buildPlacesStep();
        case 5: return _buildConfirmStep();
      }
    } else {
      switch (_currentStep) {
        case 0: return _buildFlightInfoStep();
        case 1: return _buildFlightSelectStep(isReturn: false);
        case 2: return _buildHotelStep();
        case 3: return _buildPlacesStep();
        case 4: return _buildConfirmStep();
      }
    }
    return const SizedBox();
  }

  Widget _buildFlightInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildStepIndicator(),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                AirportDropdown(label: 'Kalkış', icon: Icons.flight_takeoff, selectedAirport: _kalkis, onChanged: (a) => setState(() => _kalkis = a), excludeAirports: _varis != null ? [_varis!] : []),
                const SizedBox(height: 14),
                AirportDropdown(label: 'Varış', icon: Icons.flight_land, selectedAirport: _varis, onChanged: (a) => setState(() => _varis = a), excludeAirports: _kalkis != null ? [_kalkis!] : []),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _buildDateButton('Gidiş', _gidisTarihi, () => _selectDate(true))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDateButton('Dönüş (opsiyonel)', _donusTarihi, () => _selectDate(false))),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildNextButton('Uçuşları Ara', () {
            if (_kalkis == null || _varis == null || _gidisTarihi == null) { _showSnack('Kalkış, varış ve gidiş tarihi seçin!'); return; }
            _searchFlights(isReturn: false);
          }),
        ],
      ),
    );
  }

  Widget _buildFlightSelectStep({required bool isReturn}) {
    if (_ucusYukleniyor) return const Center(child: CircularProgressIndicator(color: Colors.white));
    final ucuslar = isReturn ? _donusUcuslari : _gidisUcuslari;
    final secilen = isReturn ? _secilenDonusUcus : _secilenGidisUcus;

    if (ucuslar == null || ucuslar.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.flight_outlined, size: 64, color: Colors.white70),
        const SizedBox(height: 16),
        Text(isReturn ? 'Dönüş uçuşu bulunamadı' : 'Gidiş uçuşu bulunamadı', style: const TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 16),
        _buildBackButton(),
      ]));
    }

    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildStepIndicator(),
        const SizedBox(height: 8),
        Text(isReturn ? 'Dönüş uçuşunuzu seçin' : 'Gidiş uçuşunuzu seçin', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ucuslar.length,
        itemBuilder: (context, index) {
          final ucus = ucuslar[index];
          final selected = secilen == ucus;
          return GestureDetector(
            onTap: () => setState(() { if (isReturn) _secilenDonusUcus = ucus; else _secilenGidisUcus = ucus; }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15), width: selected ? 2 : 1),
              ),
              child: Row(children: [
                if (selected) const Icon(Icons.check_circle, color: Colors.green, size: 22)
                else Icon(Icons.radio_button_off, color: Colors.white.withValues(alpha: 0.4), size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ucus.airline, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${ucus.departureTime} → ${ucus.arrivalTime}  •  ${ucus.duration}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                ])),
                Text('${ucus.priceTL.toStringAsFixed(0)} ₺', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
            ),
          );
        },
      )),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: _buildBackButton()),
        const SizedBox(width: 12),
        Expanded(child: _buildNextButton('Devam', () {
          if (!isReturn && _secilenGidisUcus == null) { _showSnack('Bir uçuş seçin!'); return; }
          if (isReturn && _secilenDonusUcus == null) { _showSnack('Bir dönüş uçuşu seçin!'); return; }
          if (!isReturn && _donusTarihi != null) { _searchFlights(isReturn: true); }
          else { setState(() => _currentStep++); }
        })),
      ])),
    ]);
  }

  Widget _buildHotelStep() {
    final cityKey = _varis != null ? _iataToCity(_varis!.code) : null;
    _otelSehirController.text = cityKey ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStepIndicator(),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              const Icon(Icons.hotel, size: 48, color: Colors.white70),
              const SizedBox(height: 12),
              const Text('Otel Seçimi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Şehre göre otelleri arayıp seçebilirsiniz.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: TextField(
                  controller: _otelSehirController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Şehir',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.10),
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white, width: 2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: cityKey == null
                    ? null
                    : () async {
                        final checkIn = _gidisTarihi ?? DateTime.now();
                        final checkOut = _donusTarihi ?? checkIn.add(const Duration(days: 1));
                        setState(() {
                          _hotellerYukleniyor = true;
                          _hoteller = [];
                        });
                        try {
                          final results = await _hotelService.searchHotels(city: cityKey, checkIn: checkIn, checkOut: checkOut);
                          if (!mounted) return;
                          setState(() {
                            _hoteller = results;
                          });
                        } catch (e) {
                          _showSnack('Otel arama hatası: $e');
                        } finally {
                          if (mounted) {
                            setState(() {
                              _hotellerYukleniyor = false;
                            });
                          }
                        }
                      },
                child: const Text('Ara'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_hotellerYukleniyor)
          const Padding(
            padding: EdgeInsets.only(top: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hoteller == null || _hoteller!.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Henüz otel yok. Arama yapın veya bu adımı atlayın.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _hoteller!.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.white24, height: 24),
            itemBuilder: (context, idx) {
              final h = _hoteller![idx];
              final selected = _secilenOtel?.id == h.id;
              return _SelectableHotelRow(
                hotel: h,
                selected: selected,
                onTap: () => setState(() => _secilenOtel = h),
              );
            },
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: _buildBackButton()),
            const SizedBox(width: 12),
            Expanded(child: _buildNextButton('Devam', () { _loadPlaces(); })),
          ],
        ),
      ],
    );
  }

  Widget _buildPlacesStep() {
    if (_yerlerYukleniyor) return const Center(child: CircularProgressIndicator(color: Colors.white));
    if (_yerler == null || _yerler!.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.explore_off, size: 64, color: Colors.white70), const SizedBox(height: 16),
        const Text('Yer bulunamadı', style: TextStyle(color: Colors.white, fontSize: 18)),
        const SizedBox(height: 16),
        _buildNextButton('Devam Et', () => setState(() => _currentStep = _totalSteps - 1)),
      ]));
    }
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Column(children: [
        _buildStepIndicator(), const SizedBox(height: 12),
        Text('Ziyaret etmek istediğiniz yerleri seçin', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _yerler!.length,
        itemBuilder: (context, index) {
          final yer = _yerler![index]; final selected = _secilenYerler.contains(yer);
          return GestureDetector(
            onTap: () { setState(() { if (selected) _secilenYerler.remove(yer); else _secilenYerler.add(yer); }); },
            child: Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: selected ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? Colors.green : Colors.white.withValues(alpha: 0.15), width: selected ? 2 : 1)),
              child: Row(children: [
                if (selected) const Icon(Icons.check_circle, color: Colors.green, size: 22) else Icon(Icons.radio_button_off, color: Colors.white.withValues(alpha: 0.4), size: 22),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(yer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('${yer.address}  •  ⭐ ${yer.rating}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                ])),
              ])),
          );
        },
      )),
      Padding(padding: const EdgeInsets.all(16), child: Row(children: [
        Expanded(child: _buildBackButton()), const SizedBox(width: 12),
        Expanded(child: _buildNextButton('Onayla (${_secilenYerler.length} yer)', () => setState(() => _currentStep = _totalSteps - 1))),
      ])),
    ]);
  }

  Widget _buildConfirmStep() {
    return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
      _buildStepIndicator(), const SizedBox(height: 24),
      Container(width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Center(child: Icon(Icons.check_circle_outline, size: 48, color: Colors.green)),
          const SizedBox(height: 16),
          const Center(child: Text('Seyahat Planınız', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          _buildSummaryRow(Icons.flight, 'Rota', '${_kalkis?.code ?? ''} → ${_varis?.code ?? ''}'),
          _buildSummaryRow(Icons.calendar_today, 'Gidiş', _formatDate(_gidisTarihi)),
          if (_donusTarihi != null) _buildSummaryRow(Icons.calendar_today, 'Dönüş', _formatDate(_donusTarihi)),
          if (_secilenGidisUcus != null) ...[
            const Divider(color: Colors.white24, height: 20),
            Text('✈️ Gidiş Uçuşu', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildSummaryRow(Icons.airlines, 'Havayolu', '${_secilenGidisUcus!.airline} - ${_secilenGidisUcus!.flightNumber}'),
            _buildSummaryRow(Icons.access_time, 'Saat', '${_secilenGidisUcus!.departureTime} → ${_secilenGidisUcus!.arrivalTime}'),
            _buildSummaryRow(Icons.attach_money, 'Fiyat', '${_secilenGidisUcus!.priceTL.toStringAsFixed(0)} ₺'),
          ],
          if (_secilenDonusUcus != null) ...[
            const Divider(color: Colors.white24, height: 20),
            Text('✈️ Dönüş Uçuşu', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _buildSummaryRow(Icons.airlines, 'Havayolu', '${_secilenDonusUcus!.airline} - ${_secilenDonusUcus!.flightNumber}'),
            _buildSummaryRow(Icons.access_time, 'Saat', '${_secilenDonusUcus!.departureTime} → ${_secilenDonusUcus!.arrivalTime}'),
            _buildSummaryRow(Icons.attach_money, 'Fiyat', '${_secilenDonusUcus!.priceTL.toStringAsFixed(0)} ₺'),
          ],
          if (_secilenYerler.isNotEmpty) ...[
            const Divider(color: Colors.white24, height: 20),
            Text('📍 Gezilecek Yerler (${_secilenYerler.length})', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._secilenYerler.map((y) => Padding(padding: const EdgeInsets.only(bottom: 4), child: Row(children: [
              Icon(Icons.place, size: 14, color: Colors.white.withValues(alpha: 0.5)), const SizedBox(width: 8),
              Expanded(child: Text(y.name, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13))),
            ]))),
          ],
        ])),
      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: _buildBackButton()), const SizedBox(width: 12),
        Expanded(flex: 2, child: _buildNextButton('Planı Kaydet', _savePlan)),
      ]),
    ]));
  }

  // ========== HELPERS ==========
  Widget _buildStepIndicator() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_totalSteps, (i) {
      final active = i == _currentStep; final done = i < _currentStep;
      return Container(width: active ? 28 : 10, height: 10, margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(color: done ? Colors.green : (active ? Colors.white : Colors.white.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(5)));
    }));
  }

  Widget _buildNextButton(String label, VoidCallback onPressed) {
    return SizedBox(height: 50, child: ElevatedButton(onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))));
  }

  Widget _buildBackButton() {
    return SizedBox(height: 50, child: OutlinedButton(
      onPressed: () { if (_currentStep == 0) Navigator.pop(context); else setState(() => _currentStep--); },
      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white.withValues(alpha: 0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
      child: const Text('Geri')));
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
      child: Row(children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.white.withValues(alpha: 0.7)), const SizedBox(width: 8),
        Flexible(child: Text(date != null ? _formatDate(date) : label, style: TextStyle(color: Colors.white.withValues(alpha: date != null ? 1.0 : 0.5), fontSize: 12), overflow: TextOverflow.ellipsis)),
      ])));
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.6)), const SizedBox(width: 10),
      Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
      Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
    ]));
  }

  @override
  void dispose() {
    _otelSehirController.dispose();
    _flightService.dispose();
    _placesService.dispose();
    _hotelService.dispose();
    super.dispose();
  }

  // ========== ACTIONS ==========
  Future<void> _selectDate(bool isGidis) async {
    final picked = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 7)), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() { if (isGidis) _gidisTarihi = picked; else _donusTarihi = picked; });
  }

  Future<void> _searchFlights({required bool isReturn}) async {
    setState(() { _ucusYukleniyor = true; if (!isReturn) _currentStep = 1; else _currentStep = 2; });
    try {
      final origin = isReturn ? _varis!.code : _kalkis!.code;
      final dest = isReturn ? _kalkis!.code : _varis!.code;
      final date = isReturn ? _donusTarihi! : _gidisTarihi!;
      final flights = await _flightService.searchFlights(origin: origin, destination: dest, departureDate: date);
      setState(() { if (isReturn) _donusUcuslari = flights; else _gidisUcuslari = flights; _ucusYukleniyor = false; });
    } catch (e) { setState(() => _ucusYukleniyor = false); _showSnack('Uçuş arama hatası: $e'); }
  }

  Future<void> _loadPlaces() async {
    final placesStep = _donusTarihi != null ? 4 : 3;
    setState(() { _yerlerYukleniyor = true; _currentStep = placesStep; });
    try {
      // IATA kodunu şehir adına çevir
      final cityKey = _iataToCity(_varis!.code);
      final places = await _placesService.getNearbyPlaces(city: cityKey);
      final filtered = places.where((p) => p.rating >= 3.0).toList()..sort((a, b) => b.userRatingsTotal.compareTo(a.userRatingsTotal));
      setState(() { _yerler = filtered.take(10).toList(); _yerlerYukleniyor = false; });
    } catch (e) { setState(() => _yerlerYukleniyor = false); _showSnack('Yerler yüklenemedi: $e'); }
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

  Future<void> _savePlan() async {
    try {
      final returnFlight = _secilenDonusUcus != null ? {
        'airline': _secilenDonusUcus!.airline, 'flight_number': _secilenDonusUcus!.flightNumber,
        'departure_time': _secilenDonusUcus!.departureTime, 'arrival_time': _secilenDonusUcus!.arrivalTime,
        'price': _secilenDonusUcus!.priceTL, 'duration': _secilenDonusUcus!.duration,
      } : null;

      await _planService.createPlan(
        title: '${_kalkis!.code} → ${_varis!.code} Seyahati',
        departureCity: _kalkis!.code, arrivalCity: _varis!.code,
        departureDate: _gidisTarihi!.toIso8601String().split('T')[0],
        returnDate: _donusTarihi?.toIso8601String().split('T')[0],
        flightInfo: _secilenGidisUcus != null ? {
          'airline': _secilenGidisUcus!.airline, 'flight_number': _secilenGidisUcus!.flightNumber,
          'departure_time': _secilenGidisUcus!.departureTime, 'arrival_time': _secilenGidisUcus!.arrivalTime,
          'price': _secilenGidisUcus!.priceTL, 'duration': _secilenGidisUcus!.duration,
          'return_flight': returnFlight,
        } : null,
        hotelInfo: _secilenOtel != null ? {
          'id': _secilenOtel!.id,
          'name': _secilenOtel!.name,
          'address': _secilenOtel!.address,
          'rating': _secilenOtel!.rating,
          'price_per_night': _secilenOtel!.pricePerNight,
          'image_url': _secilenOtel!.imageUrl,
        } : null,
        selectedPlaces: _secilenYerler.map((y) => {'name': y.name, 'address': y.address, 'rating': y.rating}).toList(),
      );
      if (mounted) { _showSnack('Plan kaydedildi!'); Navigator.pop(context, true); }
    } catch (e) { _showSnack('Kaydetme hatası: $e'); }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }
}

class _SelectableHotelRow extends StatelessWidget {
  final Hotel hotel;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableHotelRow({required this.hotel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: hotel.imageUrl.isNotEmpty
                      ? Image.network(
                          hotel.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Colors.white12,
                            child: Icon(Icons.hotel, color: Colors.white70),
                          ),
                        )
                      : const ColoredBox(
                          color: Colors.white12,
                          child: Icon(Icons.hotel, color: Colors.white70),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (hotel.address.isNotEmpty)
                      Text(hotel.address, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('⭐ ${hotel.rating.toStringAsFixed(1)}  •  ${hotel.pricePerNight?.toStringAsFixed(0) ?? '-'} ₺', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.check_circle, color: Colors.green),
            ],
          ),
        ),
      ),
    );
  }
}
