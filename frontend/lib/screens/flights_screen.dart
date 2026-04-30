import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/airport_dropdown.dart';
import '../widgets/date_field.dart';
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

  void _ucuslariAra() {
    if (_kalkisHavaalani == null ||
        _varisHavaalani == null ||
        _gidisTarihi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen kalkış, varış ve tarih seçin!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_kalkisHavaalani!.code == _varisHavaalani!.code) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kalkış ve varış aynı olamaz!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      appBar: AppBar(
        title: const Text('Uçuş Ara'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
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
              children: [
                Row(
                  children: [
                    const Icon(Icons.flight, color: AppTheme.primaryColor, size: 22),
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
                  excludeAirports: _varisHavaalani != null ? [_varisHavaalani!] : [],
                ),
                const SizedBox(height: 12),
                AirportDropdown(
                  label: 'Varış',
                  icon: Icons.flight_land,
                  selectedAirport: _varisHavaalani,
                  onChanged: (airport) {
                    setState(() => _varisHavaalani = airport);
                  },
                  excludeAirports: _kalkisHavaalani != null ? [_kalkisHavaalani!] : [],
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
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
