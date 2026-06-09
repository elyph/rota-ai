import 'package:flutter/material.dart';
import '../models/airport.dart';
import '../models/flight_offer.dart';
import '../services/flight_service.dart';

class FlightResultsScreen extends StatefulWidget {
  final Airport kalkis;
  final Airport varis;
  final DateTime gidisTarihi;
  final DateTime? donusTarihi;

  const FlightResultsScreen({
    super.key,
    required this.kalkis,
    required this.varis,
    required this.gidisTarihi,
    this.donusTarihi,
  });

  @override
  State<FlightResultsScreen> createState() => _FlightResultsScreenState();
}

class _FlightResultsScreenState extends State<FlightResultsScreen> {
  final FlightService _flightService = FlightService();
  List<FlightOffer>? _gidisUcuslari;
  List<FlightOffer>? _donusUcuslari;
  bool _yukleniyor = true;
  String? _hata;
  int _selectedTab = 0; // 0: Gidiş, 1: Dönüş
  String _siralama = 'fiyat_artan';

  bool get _donusVar => widget.donusTarihi != null;

  static const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  static const _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _formatTarihKisa(DateTime date) {
    return '${date.day} ${_aylar[date.month - 1]} ${date.year} ${_gunler[date.weekday - 1]}';
  }

  @override
  void initState() {
    super.initState();
    _ucuslariGetir();
  }

  Future<void> _ucuslariGetir() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final gidis = await _flightService.searchFlights(
        origin: widget.kalkis.code,
        destination: widget.varis.code,
        departureDate: widget.gidisTarihi,
      );

      List<FlightOffer>? donus;
      if (_donusVar) {
        donus = await _flightService.searchFlights(
          origin: widget.varis.code,
          destination: widget.kalkis.code,
          departureDate: widget.donusTarihi!,
        );
      }

      setState(() {
        _gidisUcuslari = gidis;
        _donusUcuslari = donus;
        _yukleniyor = false;
      });
    } catch (e) {
      setState(() {
        _hata = e.toString();
        _yukleniyor = false;
      });
    }
  }

  @override
  void dispose() {
    _flightService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Content
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Back + Route
          Row(
            children: [
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
              const SizedBox(width: 12),
              // Route pill
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flight_takeoff_rounded, size: 16, color: Color(0xFF5374FF)),
                      const SizedBox(width: 8),
                      Text(
                        widget.kalkis.city,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        widget.varis.city,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF5374FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatTarihKisa(widget.gidisTarihi),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_donusVar) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('|', style: TextStyle(color: Color(0xFFE2E8F0))),
                  ),
                  Expanded(
                    child: Text(
                      _formatTarihKisa(widget.donusTarihi!),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_yukleniyor) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF5374FF)),
            SizedBox(height: 16),
            Text('Uçuşlar aranıyor...', style: TextStyle(color: Color(0xFF64748B), fontSize: 15)),
          ],
        ),
      );
    }

    if (_hata != null) {
      return _buildErrorView();
    }

    return Column(
      children: [
        // Tabs (Gidiş / Dönüş) + Sort
        if (_donusVar) _buildTabs(),
        _buildSortBar(),
        // Flight list
        Expanded(
          child: _selectedTab == 0
              ? _buildFlightList(_gidisUcuslari)
              : _buildFlightList(_donusUcuslari),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Gidiş', 0)),
          Expanded(child: _buildTab('Dönüş', 1)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF5374FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: selected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 18, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              setState(() {
                _siralama = _siralama == 'fiyat_artan' ? 'fiyat_azalan' : 'fiyat_artan';
              });
            },
            child: Text(
              _siralama == 'fiyat_artan' ? 'Ucuzdan Pahalıya' : 'Pahalıdan Ucuza',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_siralama == 'fiyat_artan') {
                  _siralama = 'fiyat_azalan';
                } else if (_siralama == 'fiyat_azalan') {
                  _siralama = 'zaman';
                } else {
                  _siralama = 'fiyat_artan';
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 4),
                  Text('Filtrele', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightList(List<FlightOffer>? ucuslar) {
    if (ucuslar == null || ucuslar.isEmpty) {
      return _buildEmptyView();
    }

    final sirali = List<FlightOffer>.from(ucuslar);
    switch (_siralama) {
      case 'fiyat_artan':
        sirali.sort((a, b) => a.priceTL.compareTo(b.priceTL));
        break;
      case 'fiyat_azalan':
        sirali.sort((a, b) => b.priceTL.compareTo(a.priceTL));
        break;
      case 'zaman':
      default:
        sirali.sort((a, b) => a.departureTime.compareTo(b.departureTime));
        break;
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: sirali.length,
      itemBuilder: (context, index) => _buildFlightCard(sirali[index]),
    );
  }

  Widget _buildFlightCard(FlightOffer ucus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Flight info row
          Row(
            children: [
              // Airline logo placeholder
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    ucus.airline.substring(0, ucus.airline.length > 2 ? 2 : ucus.airline.length).toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: Color(0xFF5374FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Departure
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ucus.departureAirport,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.flight_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                  Text(
                    ucus.departureTime,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Duration line
              Expanded(
                child: Column(
                  children: [
                    Text(
                      ucus.duration,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      color: const Color(0xFFE2E8F0),
                    ),
                    if (ucus.stops > 0)
                      Text(
                        '${ucus.stops} Aktarma',
                        style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                      )
                    else
                      const Text(
                        'Direkt',
                        style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrival
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ucus.arrivalAirport,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    ucus.arrivalTime,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₺${ucus.priceTL.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Kişi Başı',
                        style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Airline name row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.airlines_rounded, size: 14, color: Color(0xFF5374FF)),
                ),
                const SizedBox(width: 8),
                Text(
                  ucus.airline,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'Uçuşlar yüklenirken hata oluştu',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sunucuya bağlanılamadı. Lütfen tekrar deneyin.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _ucuslariGetir,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5374FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.flight_takeoff_rounded, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text(
            'Bu rotada uçuş bulunamadı',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5374FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
