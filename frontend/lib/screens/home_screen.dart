import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/date_field.dart';
import '../widgets/feature_item.dart';
import 'result_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _neredenController = TextEditingController();
  final TextEditingController _nereyeController = TextEditingController();
  final TextEditingController _butceController = TextEditingController();

  DateTime? _gidisTarihi;
  DateTime? _donusTarihi;

  bool _yukleniyor = false;

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

  Future<void> _planOlustur() async {
    if (_neredenController.text.isEmpty ||
        _nereyeController.text.isEmpty ||
        _gidisTarihi == null ||
        _donusTarihi == null) {
      _hataGoster("Lütfen tüm alanları doldurun!");
      return;
    }

    setState(() => _yukleniyor = true);

    try {
      var url = Uri.parse('http://127.0.0.1:8000/generate-plan');
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'from': _neredenController.text,
          'to': _nereyeController.text,
          'budget': double.tryParse(_butceController.text) ?? 0.0,
          'departure_date': _gidisTarihi!.toIso8601String(),
          'return_date': _donusTarihi!.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(planVerisi: jsonResponse),
            ),
          );
        }
      } else {
        _hataGoster("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      _hataGoster("Bağlantı hatası! Sunucunun açık olduğundan emin ol.");
    } finally {
      setState(() => _yukleniyor = false);
    }
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
  void dispose() {
    _neredenController.dispose();
    _nereyeController.dispose();
    _butceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Üst Başlık
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
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
                        'Akıllı Seyahat Planlayıcı',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Seyahat Bilgileri Kartı
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seyahat Bilgileri',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        controller: _neredenController,
                        label: 'Nereden',
                        hint: 'Örn: İstanbul',
                        icon: Icons.flight_takeoff,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _nereyeController,
                        label: 'Nereye',
                        hint: 'Örn: Antalya',
                        icon: Icons.flight_land,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: DateField(
                              label: 'Gidiş Tarihi',
                              date: _gidisTarihi,
                              onTap: () => _tarihSec(gidis: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DateField(
                              label: 'Dönüş Tarihi',
                              date: _donusTarihi,
                              onTap: () => _tarihSec(gidis: false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _butceController,
                        label: 'Bütçe (TL)',
                        hint: 'Örn: 5000',
                        icon: Icons.account_balance_wallet,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _yukleniyor ? null : _planOlustur,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _yukleniyor
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_awesome, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Yapay Zeka ile Planla',
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
                const SizedBox(height: 24),

                // Özellikler
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    FeatureItem(icon: Icons.flight, label: 'Uçuşlar'),
                    FeatureItem(icon: Icons.hotel, label: 'Oteller'),
                    FeatureItem(icon: Icons.explore, label: 'Gezilecek Yerler'),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
