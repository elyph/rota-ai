import 'package:flutter/material.dart';
import '../models/airport.dart';
import 'flight_results_screen.dart';

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key});

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  Airport? _kalkisHavaalani;
  Airport? _varisHavaalani;
  DateTime? _gidisTarihi;
  DateTime? _donusTarihi;

  static const _gunler = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  static const _aylar = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

  String _formatTarih(DateTime? date) {
    if (date == null) return 'Tarih seçin';
    return '${date.day} ${_aylar[date.month - 1]} ${date.year} ${_gunler[date.weekday - 1]}';
  }

  Future<void> _tarihSec({required bool gidis}) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: gidis
          ? (_gidisTarihi ?? DateTime.now())
          : (_donusTarihi ?? (_gidisTarihi ?? DateTime.now()).add(const Duration(days: 3))),
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
    if (secilen != null) {
      setState(() {
        if (gidis) {
          _gidisTarihi = secilen;
          if (_donusTarihi != null && _donusTarihi!.isBefore(secilen)) {
            _donusTarihi = null;
          }
        } else {
          _donusTarihi = secilen;
        }
      });
    }
  }

  void _havaalaniDegistir() {
    setState(() {
      final temp = _kalkisHavaalani;
      _kalkisHavaalani = _varisHavaalani;
      _varisHavaalani = temp;
    });
  }

  void _ucuslariAra() {
    if (_kalkisHavaalani == null || _varisHavaalani == null || _gidisTarihi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen kalkış, varış ve tarih seçin!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_kalkisHavaalani!.code == _varisHavaalani!.code) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kalkış ve varış aynı olamaz!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlightResultsScreen(
          kalkis: _kalkisHavaalani!,
          varis: _varisHavaalani!,
          gidisTarihi: _gidisTarihi!,
          donusTarihi: _donusTarihi,
        ),
      ),
    );
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
              // Title
              const Text(
                'Uçuş Ara',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'En uygun uçuşları bul',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),

              // Route selector card
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
                  children: [
                    // Kalkış - Varış row with swap button
                    Row(
                      children: [
                        // Kalkış
                        Expanded(
                          child: _buildAirportSelector(
                            label: 'Nereden',
                            airport: _kalkisHavaalani,
                            icon: Icons.flight_takeoff_rounded,
                            onTap: () => _showAirportPicker(isKalkis: true),
                          ),
                        ),
                        // Swap button
                        GestureDetector(
                          onTap: _havaalaniDegistir,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Color(0xFF5374FF),
                              size: 20,
                            ),
                          ),
                        ),
                        // Varış
                        Expanded(
                          child: _buildAirportSelector(
                            label: 'Nereye',
                            airport: _varisHavaalani,
                            icon: Icons.flight_land_rounded,
                            onTap: () => _showAirportPicker(isKalkis: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Divider
                    Container(
                      height: 1,
                      color: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 16),
                    // Tarih seçiciler
                    GestureDetector(
                      onTap: () => _tarihSec(gidis: true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF5374FF)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatTarih(_gidisTarihi),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _gidisTarihi != null ? FontWeight.w600 : FontWeight.w400,
                                  color: _gidisTarihi != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 20,
                              color: const Color(0xFFE2E8F0),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _tarihSec(gidis: false),
                                child: Text(
                                  _formatTarih(_donusTarihi),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _donusTarihi != null ? FontWeight.w600 : FontWeight.w400,
                                    color: _donusTarihi != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _ucuslariAra,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5374FF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Uçuş Ara',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Popular routes
              const Text(
                'Popüler Rotalar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              _buildPopularRoute('İstanbul', 'Antalya', 'IST', 'AYT'),
              _buildPopularRoute('İstanbul', 'İzmir', 'IST', 'ADB'),
              _buildPopularRoute('Ankara', 'İstanbul', 'ESB', 'IST'),
              _buildPopularRoute('İstanbul', 'Trabzon', 'IST', 'TZX'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAirportSelector({
    required String label,
    required Airport? airport,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFF5374FF)),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              airport != null ? airport.city : 'Seçin',
              style: TextStyle(
                fontSize: 15,
                fontWeight: airport != null ? FontWeight.w700 : FontWeight.w400,
                color: airport != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (airport != null)
              Text(
                airport.code,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularRoute(String from, String to, String fromCode, String toCode) {
    return GestureDetector(
      onTap: () {
        final kalkis = AirportData.airports.firstWhere((a) => a.code == fromCode);
        final varis = AirportData.airports.firstWhere((a) => a.code == toCode);
        setState(() {
          _kalkisHavaalani = kalkis;
          _varisHavaalani = varis;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flight_rounded, size: 18, color: Color(0xFF5374FF)),
            const SizedBox(width: 12),
            Text(
              from,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 8),
            Text(
              to,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const Spacer(),
            Text(
              '$fromCode → $toCode',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAirportPicker({required bool isKalkis}) {
    final exclude = isKalkis
        ? (_varisHavaalani != null ? [_varisHavaalani!] : <Airport>[])
        : (_kalkisHavaalani != null ? [_kalkisHavaalani!] : <Airport>[]);

    final available = AirportData.airports
        .where((a) => !exclude.contains(a))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isKalkis ? 'Kalkış Havaalanı' : 'Varış Havaalanı',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final airport = available[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          airport.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF5374FF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Text(
                        airport.city,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: Text(
                        airport.name,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      onTap: () {
                        setState(() {
                          if (isKalkis) {
                            _kalkisHavaalani = airport;
                          } else {
                            _varisHavaalani = airport;
                          }
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
  }
}
