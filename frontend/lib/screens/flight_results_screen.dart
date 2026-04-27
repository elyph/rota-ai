import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/airport.dart';
import '../models/flight_offer.dart';
import '../services/duffel_service.dart';
import '../helpers/date_helper.dart';

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

class _FlightResultsScreenState extends State<FlightResultsScreen>
    with SingleTickerProviderStateMixin {
  final DuffelService _duffelService = DuffelService();
  List<FlightOffer>? _gidisUcuslari;
  List<FlightOffer>? _donusUcuslari;
  bool _yukleniyor = true;
  String? _hata;
  late TabController _tabController;

  bool get _donusVar => widget.donusTarihi != null;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _donusVar ? 2 : 1, vsync: this);
    _ucuslariGetir();
  }

  Future<void> _ucuslariGetir() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final gidis = await _duffelService.searchFlights(
        origin: widget.kalkis.code,
        destination: widget.varis.code,
        departureDate: widget.gidisTarihi,
      );

      List<FlightOffer>? donus;
      if (_donusVar) {
        donus = await _duffelService.searchFlights(
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
    _duffelService.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kalkis.code} → ${widget.varis.code}'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: _donusVar
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppTheme.primaryColor.withValues(alpha: 0.9),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flight_takeoff, size: 18),
                            const SizedBox(width: 6),
                            Text('Gidiş\n${DateHelper.formatDate(widget.gidisTarihi).split(' ').take(2).join(' ')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flight_land, size: 18),
                            const SizedBox(width: 6),
                            Text('Dönüş\n${DateHelper.formatDate(widget.donusTarihi).split(' ').take(2).join(' ')}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_yukleniyor) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Uçuşlar aranıyor...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_hata != null) {
      return _buildErrorView();
    }

    if (_donusVar) {
      return TabBarView(
        controller: _tabController,
        children: [
          _buildFlightList(_gidisUcuslari, isReturn: false),
          _buildFlightList(_donusUcuslari, isReturn: true),
        ],
      );
    }

    return _buildFlightList(_gidisUcuslari, isReturn: false);
  }

  Widget _buildFlightList(List<FlightOffer>? ucuslar, {required bool isReturn}) {
    if (ucuslar == null || ucuslar.isEmpty) {
      return _buildEmptyView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRouteHeader(ucuslar, isReturn),
          const SizedBox(height: 16),
          ...List.generate(ucuslar.length, (index) {
            return _buildFlightCard(ucuslar[index], ucuslar, index);
          }),
          const SizedBox(height: 16),
          // Uyarı metni
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fiyatlar global sağlayıcı verisidir, havayolu sitesinde farklılık gösterebilir.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
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
            Icon(Icons.error_outline, size: 64, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            const Text(
              'Uçuşlar yüklenirken hata oluştu!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _hata!.contains('Duffel API')
                  ? 'API bağlantı hatası. Token\'ınızı kontrol edin.'
                  : 'Sunucuya bağlanılamadı. İnternet bağlantınızı kontrol edin.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _ucuslariGetir,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
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
          const Icon(Icons.flight_takeoff, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Bu rotada Pegasus uçuşu bulunamadı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(List<FlightOffer> ucuslar, bool isReturn) {
    final varisKodu = isReturn ? widget.kalkis.code : widget.varis.code;
    final kalkisKodu = isReturn ? widget.varis.code : widget.kalkis.code;
    final tarih = isReturn ? widget.donusTarihi! : widget.gidisTarihi;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                kalkisKodu,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  isReturn ? Icons.flight_land : Icons.flight,
                  size: 28,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                varisKodu,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${ucuslar.length} uçuş bulundu • ${DateHelper.formatDate(tarih)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightCard(FlightOffer ucus, List<FlightOffer> liste, int index) {
    final fiyatOran = (ucus.priceUSD - liste.first.priceUSD) /
        (liste.last.priceUSD - liste.first.priceUSD).clamp(1, double.infinity);
    final renk = Color.lerp(
      Colors.green,
      Colors.orange,
      fiyatOran.clamp(0.0, 1.0),
    )!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _ucuSec(ucus),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ucus.airline,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Uçuş ${ucus.flightNumber}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: renk.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${ucus.priceTL.toStringAsFixed(0)} ₺',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: renk,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeColumn(
                        time: ucus.departureTime,
                        airport: ucus.departureAirport,
                        label: 'Kalkış',
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Text(
                            ucus.duration,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.3),
                                  Colors.white.withValues(alpha: 0.6),
                                  Colors.white.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                          ),
                          if (ucus.stops > 0)
                            Text(
                              '${ucus.stops} Aktarma',
                              style: TextStyle(
                                color: Colors.orange.shade300,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildTimeColumn(
                        time: ucus.arrivalTime,
                        airport: ucus.arrivalAirport,
                        label: 'Varış',
                        alignRight: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeColumn({
    required String time,
    required String airport,
    required String label,
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          airport,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _ucuSec(FlightOffer ucus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Uçuş Seçildi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(
              '${ucus.airline} - ${ucus.flightNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${ucus.departureAirport} → ${ucus.arrivalAirport}',
            ),
            const SizedBox(height: 4),
            Text('${ucus.priceTL.toStringAsFixed(0)} ₺'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
