import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/flights_screen.dart';
import 'screens/hotels_screen.dart';
import 'screens/places_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rphnftrzemsuhfyipuij.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwaG5mdHJ6ZW1zdWhmeWlwdWlqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgzOTgxNTEsImV4cCI6MjA5Mzk3NDE1MX0.n9f-tyNEYJkvqshAimw89GEnaRQvfl-hFiIylo3rxNE',
  );

  runApp(const RotaAIApp());
}

class RotaAIApp extends StatelessWidget {
  const RotaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rota AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
      builder: (context, child) {
        // Flutter web keyboard insets hatasını önlemek için
        // negatif viewInsets'i clamp'le (bilinen Flutter web bug'ı)
        final mediaQuery = MediaQuery.of(context);
        final bottomInset = mediaQuery.viewInsets.bottom.clamp(0.0, double.infinity);
        return MediaQuery(
          data: mediaQuery.copyWith(
            viewInsets: mediaQuery.viewInsets.copyWith(bottom: bottomInset),
          ),
          child: child!,
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(onNavigateToProfile: () => setState(() => _selectedIndex = 4)),
    const FlightsScreen(),
    const HotelsScreen(),
    const PlacesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Screens
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // Chatbot FAB - above the navbar, right side
          if (_selectedIndex == 0)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 96,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5374FF), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF5374FF).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          // Floating Bottom Navigation Bar
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_filled, Icons.home_outlined, 'Ana Menü', 0),
                  _buildNavItem(Icons.flight, Icons.flight_outlined, 'Uçuş', 1),
                  _buildNavItem(Icons.apartment_rounded, Icons.apartment_outlined, 'Otel', 2),
                  _buildNavItem(Icons.location_on_rounded, Icons.location_on_outlined, 'Gezilecek Yerler', 3),
                  _buildNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profil', 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF5374FF).withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: 24,
                color: isSelected
                    ? const Color(0xFF5374FF)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF5374FF)
                    : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
