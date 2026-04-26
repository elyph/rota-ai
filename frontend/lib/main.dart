import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const RotaAIApp());
}

class RotaAIApp extends StatelessWidget {
  const RotaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rota AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AnaEkran(),
    );
  }
}

class AnaEkran extends StatefulWidget {
  const AnaEkran({super.key});

  @override
  State<AnaEkran> createState() => _AnaEkranState();
}

class _AnaEkranState extends State<AnaEkran> {
  // Kullanıcının gireceği verileri tutacak kontrolcüler
  final TextEditingController _sehirController = TextEditingController();
  final TextEditingController _butceController = TextEditingController();
  final TextEditingController _gunController = TextEditingController();
  
  bool _yukleniyor = false; // Yükleniyor animasyonu için

  // Backend'e istek atan fonksiyon
  Future<void> _planOlustur() async {
    setState(() {
      _yukleniyor = true;
    });

    try {
      // Android emülatör için localhost adresi 10.0.2.2'dir. iOS için 127.0.0.1 yapmalısın.
      var url = Uri.parse('http://127.0.0.1:8000/generate-plan');
      
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'city': _sehirController.text,
          'budget': double.tryParse(_butceController.text) ?? 0.0,
          'days': int.tryParse(_gunController.text) ?? 1,
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        
        // Veri başarıyla geldiyse Sonuç ekranına geç
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SonucEkrani(planVerisi: jsonResponse),
            ),
          );
        }
      } else {
        _hataGoster("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      _hataGoster("Bağlantı hatası! Sunucunun açık olduğundan emin ol.");
    } finally {
      setState(() {
        _yukleniyor = false;
      });
    }
  }

  void _hataGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yapay Zeka Gezi Planlayıcı', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.travel_explore, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 30),
            TextField(
              controller: _sehirController,
              decoration: const InputDecoration(
                labelText: 'Hangi şehre gitmek istersin?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _butceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Toplam Bütçen (TL)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _gunController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kaç Gün Kalacaksın?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _yukleniyor ? null : _planOlustur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: _yukleniyor 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Yapay Zeka ile Planla', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- SONUÇ EKRANI ----
class SonucEkrani extends StatelessWidget {
  final Map<String, dynamic> planVerisi;

  const SonucEkrani({super.key, required this.planVerisi});

  @override
  Widget build(BuildContext context) {
    List detaylar = planVerisi['details'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('İşte Harika Planın!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                planVerisi['plan'] ?? 'Plan detayları bulunamadı.',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Tahmini Harcama Dağılımı", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: detaylar.length,
                itemBuilder: (context, index) {
                  var kalem = detaylar[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const Icon(Icons.check_circle, color: Colors.green),
                      title: Text(kalem['item'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text("${kalem['price']} TL", style: const TextStyle(fontSize: 16)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}