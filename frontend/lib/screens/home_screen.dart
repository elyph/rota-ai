import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/date_field.dart';
import '../widgets/feature_item.dart';
import '../widgets/airport_dropdown.dart';
import '../models/airport.dart';
import 'flight_results_screen.dart';
import 'places_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Uçuş değişkenleri
  Airport? _kalkisHavaalani;
  Airport? _varisHavaalani;
  DateTime? _gidisTarihi;
  DateTime? _donusTarihi;

  // Gezilecek yerler değişkenleri
  String? _secilenSehir;
  DateTime? _geziTarihi;

  // Şehir listesi
  final List<Map<String, String>> _sehirler = [
    {'name': 'İstanbul', 'key': 'istanbul'},
    {'name': 'Ankara', 'key': 'ankara'},
    {'name': 'İzmir', 'key': 'izmir'},
    {'name': 'Antalya', 'key': 'antalya'},
    {'name': 'Muğla', 'key': 'muğla'},
    {'name': 'Trabzon', 'key': 'trabzon'},
    {'name': 'Adana', 'key': 'adana'},
    {'name': 'Nevşehir', 'key': 'nevşehir'},
    {'name': 'Gaziantep', 'key': 'gaziantep'},
    {'name': 'Erzurum', 'key': 'erzurum'},
    {'name': 'Samsun', 'key': 'samsun'},
    {'name': 'Bursa', 'key': 'bursa'},
    {'name': 'Konya', 'key': 'konya'},
    {'name': 'Mardin', 'key': 'mardin'},
    {'name': 'Edirne', 'key': 'edirne'},
    {'name': 'Çanakkale', 'key': 'çanakkale'},
  ];

  Future<void> _tarihSec({required bool gidis}) async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
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

  Future<void> _geziTarihiSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (secilen != null) {
      setState(() {
        _geziTarihi = secilen;
      });
    }
  }

  void _ucuslariAra() {
    if (_kalkisHavaalani == null ||
        _varisHavaalani == null ||
        _gidisTarihi == null) {
      _hataGoster("Lütfen kalkış, varış ve tarih seçin!");
      return;
    }

    if (_kalkisHavaalani!.code == _varisHavaalani!.code) {
      _hataGoster("Kalkış ve varış aynı olamaz!");
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

  void _gezilecekYerleriBul() {
    if (_secilenSehir == null) {
      _hataGoster("Lütfen bir şehir seçin!");
      return;
    }

    final secilenSehir = _sehirler.firstWhere(
      (s) => s['key'] == _secilenSehir,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlacesScreen(
          cityName: secilenSehir['name']!,
          cityKey: secilenSehir['key']!,
        ),
      ),
    );
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Üst Başlık
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.flight_takeoff_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Rota AI',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Akıllı Gezi Planlayıcı',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ========== UÇUŞ BİLGİLERİ KARTI ==========
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.flight,
                                      color: AppTheme.primaryColor, size: 22),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Uçuş Bilgileri',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              AirportDropdown(
                                label: 'Kalkış',
                                icon: Icons.flight_takeoff,
                                selectedAirport: _kalkisHavaalani,
                                onChanged: (airport) {
                                  setState(() => _kalkisHavaalani = airport);
                                },
                                excludeAirports: _varisHavaalani != null
                                    ? [_varisHavaalani!]
                                    : [],
                              ),
                              const SizedBox(height: 12),

                              AirportDropdown(
                                label: 'Varış',
                                icon: Icons.flight_land,
                                selectedAirport: _varisHavaalani,
                                onChanged: (airport) {
                                  setState(() => _varisHavaalani = airport);
                                },
                                excludeAirports: _kalkisHavaalani != null
                                    ? [_kalkisHavaalani!]
                                    : [],
                              ),
                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: DateField(
                                      label: 'Gidiş',
                                      date: _gidisTarihi,
                                      onTap: () => _tarihSec(gidis: true),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DateField(
                                      label: 'Dönüş',
                                      date: _donusTarihi,
                                      onTap: () => _tarihSec(gidis: false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _ucuslariAra,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.search, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Uçuşları Ara',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ========== GEZİLECEK YERLER KARTI ==========
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.explore,
                                      color: AppTheme.primaryColor, size: 22),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Gezilecek Yerler',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Şehir seçme dropdown
                              DropdownButtonFormField<String>(
                                value: _secilenSehir,
                                decoration: InputDecoration(
                                  labelText: 'Şehir Seçin',
                                  prefixIcon: const Icon(Icons.location_city,
                                      color: AppTheme.primaryColor),
                                  filled: true,
                                  fillColor: AppTheme.lightBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppTheme.primaryColor, width: 2),
                                  ),
                                  labelStyle:
                                      const TextStyle(color: AppTheme.darkColor),
                                ),
                                hint: Text('Şehir seçiniz',
                                    style:
                                        TextStyle(color: Colors.grey.shade500)),
                                isExpanded: true,
                                items: _sehirler.map((sehir) {
                                  return DropdownMenuItem<String>(
                                    value: sehir['key'],
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            sehir['key']!.substring(0, 2).toUpperCase(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          sehir['name']!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _secilenSehir = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 12),

                              // Tarih seçme
                              DateField(
                                label: 'Gezi Tarihi',
                                date: _geziTarihi,
                                onTap: _geziTarihiSec,
                              ),
                              const SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _gezilecekYerleriBul,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B894),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.explore, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Gezilecek Yerleri Bul',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Özellikler
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            FeatureItem(icon: Icons.flight, label: 'Uçuşlar'),
                            FeatureItem(icon: Icons.hotel, label: 'Oteller'),
                            FeatureItem(
                                icon: Icons.explore, label: 'Gezilecek Yerler'),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
