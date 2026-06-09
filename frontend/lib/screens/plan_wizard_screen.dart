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
import '../services/itinerary_service.dart';
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
  bool _otelAramaBasladi = false;
  final TextEditingController _otelSehirController = TextEditingController();

  final FlightService _flightService = FlightService();
  final PlacesService _placesService = PlacesService();
  final TravelPlanService _planService = TravelPlanService();
  final HotelService _hotelService = HotelService();
  final ItineraryService _itineraryService = ItineraryService();

  int get _totalSteps => _donusTarihi != null ? 6 : 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: Navigator.canPop(context) ? Align(
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF0F172A)),
            ),
          ),
        ) : null,
        title: Text(
          _getStepTitle(),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: SafeArea(child: _buildCurrentStep()),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                AirportDropdown(label: 'Kalkış', icon: Icons.flight_takeoff_rounded, selectedAirport: _kalkis, onChanged: (a) => setState(() => _kalkis = a), excludeAirports: _varis != null ? [_varis!] : []),
                const SizedBox(height: 16),
                AirportDropdown(label: 'Varış', icon: Icons.flight_land_rounded, selectedAirport: _varis, onChanged: (a) => setState(() => _varis = a), excludeAirports: _kalkis != null ? [_kalkis!] : []),
                const SizedBox(height: 16),
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
    if (_ucusYukleniyor) return const Center(child: CircularProgressIndicator(color: Color(0xFF5374FF)));
    final ucuslar = isReturn ? _donusUcuslari : _gidisUcuslari;
    final secilen = isReturn ? _secilenDonusUcus : _secilenGidisUcus;

    if (ucuslar == null || ucuslar.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.flight_outlined, size: 64, color: Color(0xFF64748B)),
        const SizedBox(height: 16),
        Text(isReturn ? 'Dönüş uçuşu bulunamadı' : 'Gidiş uçuşu bulunamadı', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(width: 200, child: _buildBackButton()),
      ]));
    }

    return Column(children: [
      Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildStepIndicator(),
        const SizedBox(height: 8),
        Text(isReturn ? 'Dönüş uçuşunuzu seçin' : 'Gidiş uçuşunuzu seçin', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
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
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF5374FF).withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? const Color(0xFF5374FF) : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                if (selected) const Icon(Icons.check_circle, color: Color(0xFF5374FF), size: 24)
                else const Icon(Icons.radio_button_off, color: Color(0xFFCBD5E1), size: 24),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ucus.airline, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('${ucus.departureTime} → ${ucus.arrivalTime}  •  ${ucus.duration}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ])),
                Text('${ucus.priceTL.toStringAsFixed(0)} ₺', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
          );
        },
      )),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          Expanded(child: _buildBackButton()),
          const SizedBox(width: 12),
          Expanded(child: _buildNextButton('Devam', () {
            if (!isReturn && _secilenGidisUcus == null) { _showSnack('Bir uçuş seçin!'); return; }
            if (isReturn && _secilenDonusUcus == null) { _showSnack('Bir dönüş uçuşu seçin!'); return; }
            if (!isReturn && _donusTarihi != null) { _searchFlights(isReturn: true); }
            else { setState(() => _currentStep++); }
          })),
        ]),
      ),
    ]);
  }

  Widget _buildHotelStep() {
    final cityKey = _varis != null ? _iataToCity(_varis!.code) : null;
    _otelSehirController.text = cityKey ?? '';

    // Sayfa ilk açıldığında otomatik ara
    if (!_otelAramaBasladi && cityKey != null && _hoteller == null && !_hotellerYukleniyor) {
      _otelAramaBasladi = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchHotelsAuto(cityKey);
      });
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildStepIndicator(),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.hotel_rounded, size: 48, color: Color(0xFF5374FF)),
                    const SizedBox(height: 12),
                    const Text('Otel Seçimi', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${cityKey?.toUpperCase() ?? ''} bölgesindeki oteller listeleniyor.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_hotellerYukleniyor)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF5374FF))),
                )
              else if (_hoteller == null || _hoteller!.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Bu bölgede otel bulunamadı.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _hoteller!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
          child: Row(
            children: [
              Expanded(child: _buildBackButton()),
              const SizedBox(width: 12),
              Expanded(child: _buildNextButton('Devam', () { _loadPlaces(); })),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _searchHotelsAuto(String cityKey) async {
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
  }

  Widget _buildPlacesStep() {
    if (_yerlerYukleniyor) return const Center(child: CircularProgressIndicator(color: Color(0xFF5374FF)));
    if (_yerler == null || _yerler!.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.explore_off, size: 64, color: Color(0xFF64748B)), const SizedBox(height: 16),
        const Text('Yer bulunamadı', style: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 24),
        SizedBox(width: 200, child: _buildNextButton('Devam Et', () => setState(() => _currentStep = _totalSteps - 1))),
      ]));
    }
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 12), child: Column(children: [
        _buildStepIndicator(), const SizedBox(height: 16),
        const Text('Ziyaret etmek istediğiniz yerleri seçin', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
      ])),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20), itemCount: _yerler!.length,
        itemBuilder: (context, index) {
          final yer = _yerler![index]; final selected = _secilenYerler.contains(yer);
          return GestureDetector(
            onTap: () { setState(() { if (selected) _secilenYerler.remove(yer); else _secilenYerler.add(yer); }); },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF5374FF).withValues(alpha: 0.08) : Colors.white, 
                borderRadius: BorderRadius.circular(16), 
                border: Border.all(color: selected ? const Color(0xFF5374FF) : Colors.transparent, width: 2),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                if (selected) const Icon(Icons.check_circle, color: Color(0xFF5374FF), size: 24) 
                else const Icon(Icons.radio_button_off, color: Color(0xFFCBD5E1), size: 24),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(yer.name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('${yer.address}  •  ⭐ ${yer.rating}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ])),
              ])),
          );
        },
      )),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          Expanded(child: _buildBackButton()), const SizedBox(width: 12),
          Expanded(child: _buildNextButton('Onayla (${_secilenYerler.length})', () => setState(() => _currentStep = _totalSteps - 1))),
        ]),
      ),
    ]);
  }

  Widget _buildConfirmStep() {
    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
        _buildStepIndicator(), const SizedBox(height: 24),
        Container(width: double.infinity, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Center(child: Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green)), const SizedBox(height: 16),
            const Center(child: Text('Seyahat Planınız', style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w800))), const SizedBox(height: 24),
            _buildSummaryRow(Icons.flight_takeoff_rounded, 'Rota', '${_kalkis?.code ?? ''} → ${_varis?.code ?? ''}'),
            _buildSummaryRow(Icons.calendar_today_rounded, 'Gidiş', _formatDate(_gidisTarihi)),
            if (_donusTarihi != null) _buildSummaryRow(Icons.calendar_today_rounded, 'Dönüş', _formatDate(_donusTarihi)),
            if (_secilenGidisUcus != null) ...[
              const Divider(color: Color(0xFFF1F5F9), height: 32, thickness: 1.5),
              const Text('✈️ Gidiş Uçuşu', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
              _buildSummaryRow(Icons.airlines, 'Havayolu', '${_secilenGidisUcus!.airline} - ${_secilenGidisUcus!.flightNumber}'),
              _buildSummaryRow(Icons.access_time_rounded, 'Saat', '${_secilenGidisUcus!.departureTime} → ${_secilenGidisUcus!.arrivalTime}'),
              _buildSummaryRow(Icons.attach_money_rounded, 'Fiyat', '${_secilenGidisUcus!.priceTL.toStringAsFixed(0)} ₺'),
            ],
            if (_secilenDonusUcus != null) ...[
              const Divider(color: Color(0xFFF1F5F9), height: 32, thickness: 1.5),
              const Text('✈️ Dönüş Uçuşu', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
              _buildSummaryRow(Icons.airlines, 'Havayolu', '${_secilenDonusUcus!.airline} - ${_secilenDonusUcus!.flightNumber}'),
              _buildSummaryRow(Icons.access_time_rounded, 'Saat', '${_secilenDonusUcus!.departureTime} → ${_secilenDonusUcus!.arrivalTime}'),
              _buildSummaryRow(Icons.attach_money_rounded, 'Fiyat', '${_secilenDonusUcus!.priceTL.toStringAsFixed(0)} ₺'),
            ],
            if (_secilenOtel != null) ...[
              const Divider(color: Color(0xFFF1F5F9), height: 32, thickness: 1.5),
              const Text('🏨 Otel', style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
              _buildSummaryRow(Icons.hotel_rounded, 'Otel Adı', _secilenOtel!.name),
              if (_secilenOtel!.address.isNotEmpty) _buildSummaryRow(Icons.location_on_rounded, 'Adres', _secilenOtel!.address),
              _buildSummaryRow(Icons.star_rounded, 'Puan', '⭐ ${_secilenOtel!.rating.toStringAsFixed(1)}'),
              if (_secilenOtel!.pricePerNight != null) _buildSummaryRow(Icons.attach_money_rounded, 'Gecelik', '${_secilenOtel!.pricePerNight!.toStringAsFixed(0)} ₺'),
            ],
            if (_secilenYerler.isNotEmpty) ...[
              const Divider(color: Color(0xFFF1F5F9), height: 32, thickness: 1.5),
              Text('📍 Gezilecek Yerler (${_secilenYerler.length})', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
              ..._secilenYerler.map((y) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.place_rounded, size: 16, color: Color(0xFF64748B)), const SizedBox(width: 10),
                Expanded(child: Text(y.name, style: const TextStyle(color: Color(0xFF334155), fontSize: 14))),
              ]))),
            ],
          ])),
      ]))),
      Container(
        padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: Row(children: [
          Expanded(child: _buildBackButton()), const SizedBox(width: 12),
          Expanded(flex: 2, child: _buildNextButton('Planı Kaydet', _savePlan)),
        ]),
      ),
    ]);
  }

  // ========== HELPERS ==========
  Widget _buildStepIndicator() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(_totalSteps, (i) {
      final active = i == _currentStep; final done = i < _currentStep;
      return Container(width: active ? 28 : 10, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(color: done ? Colors.green : (active ? const Color(0xFF5374FF) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(4)));
    }));
  }

  Widget _buildNextButton(String label, VoidCallback onPressed) {
    return SizedBox(height: 54, child: ElevatedButton(onPressed: onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5374FF), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))));
  }

  Widget _buildBackButton() {
    return SizedBox(height: 54, child: OutlinedButton(
      onPressed: () { if (_currentStep == 0) Navigator.pop(context); else setState(() => _currentStep--); },
      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0F172A), side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: const Text('Geri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16))));
  }

  Widget _buildDateButton(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(
      height: 64, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)), const SizedBox(width: 10),
        Flexible(child: Text(date != null ? _formatDate(date) : label, style: TextStyle(color: date != null ? const Color(0xFF0F172A) : const Color(0xFF64748B), fontSize: 14, fontWeight: date != null ? FontWeight.w600 : FontWeight.normal), overflow: TextOverflow.ellipsis)),
      ])));
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: const Color(0xFF64748B)), const SizedBox(width: 12),
      SizedBox(width: 80, child: Text('$label: ', style: const TextStyle(color: Color(0xFF64748B), fontSize: 14))),
      Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600))),
    ]));
  }

  @override
  void dispose() {
    _otelSehirController.dispose();
    _flightService.dispose();
    _placesService.dispose();
    _hotelService.dispose();
    _itineraryService.dispose();
    super.dispose();
  }

  // ========== ACTIONS ==========
  Future<void> _selectDate(bool isGidis) async {
    final picked = await showDatePicker(
      context: context, 
      initialDate: isGidis ? (_gidisTarihi ?? DateTime.now().add(const Duration(days: 7))) : (_donusTarihi ?? _gidisTarihi?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 8))),
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
      // 1. Gemini'den gün gün program oluştur
      _showSnack('✨ AI programınız hazırlanıyor...');
      String? itinerary;
      try {
        itinerary = await _itineraryService.generateItinerary(
          departureCity: _kalkis!.code,
          arrivalCity: _varis!.code,
          departureDate: _gidisTarihi!.toIso8601String().split('T')[0],
          returnDate: _donusTarihi?.toIso8601String().split('T')[0],
          hotelName: _secilenOtel?.name,
          selectedPlaces: _secilenYerler
              .map((y) => {'name': y.name, 'address': y.address})
              .toList(),
          flightAirline: _secilenGidisUcus?.airline,
          flightDepartureTime: _secilenGidisUcus?.departureTime,
          returnFlightAirline: _secilenDonusUcus?.airline,
          returnFlightDepartureTime: _secilenDonusUcus?.departureTime,
        );
      } catch (_) {
        // Gemini başarısız olursa itinerary olmadan devam et
        itinerary = null;
      }

      // 2. Planı kaydet
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
        itinerary: itinerary,
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: const Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }
}

class _SelectableHotelRow extends StatelessWidget {
  final Hotel hotel; final bool selected; final VoidCallback onTap;
  const _SelectableHotelRow({required this.hotel, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF5374FF).withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: selected ? const Color(0xFF5374FF) : Colors.transparent, width: 2), borderRadius: BorderRadius.circular(20), boxShadow: selected ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(width: 80, height: 80,
              child: hotel.imageUrl.isNotEmpty ? Image.network(hotel.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFF1F5F9), child: Icon(Icons.hotel_rounded, color: Color(0xFF94A3B8))))
              : const ColoredBox(color: Color(0xFFF1F5F9), child: Icon(Icons.hotel_rounded, color: Color(0xFF94A3B8)))
            )),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(hotel.name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 6),
              if (hotel.address.isNotEmpty) Text(hotel.address, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.star_rounded, size: 16, color: Colors.amber), const SizedBox(width: 4),
                Text(hotel.rating.toStringAsFixed(1), style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w600, fontSize: 13)), const Spacer(),
                if (hotel.pricePerNight != null) Text('${hotel.pricePerNight!.toStringAsFixed(0)} ₺', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 15)),
              ]),
            ])),
            if (selected) const Padding(padding: EdgeInsets.only(left: 8.0), child: Icon(Icons.check_circle, color: Color(0xFF5374FF))),
          ]),
        ),
      ),
    );
  }
}
