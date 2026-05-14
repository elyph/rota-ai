import 'package:flutter/material.dart';
import '../models/airport.dart';
import '../theme/app_theme.dart';

class AirportDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final Airport? selectedAirport;
  final ValueChanged<Airport?> onChanged;
  final List<Airport> excludeAirports;

  const AirportDropdown({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedAirport,
    required this.onChanged,
    this.excludeAirports = const [],
  });

  @override
  Widget build(BuildContext context) {
    final availableAirports = AirportData.airports
        .where((a) => !excludeAirports.contains(a))
        .toList();

    return DropdownButtonFormField<Airport>(
      initialValue: selectedAirport,
      isDense: true,
      itemHeight: 64,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.8)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
      ),
      hint: Text('Seçiniz', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
      dropdownColor: const Color(0xFF1E293B),
      iconEnabledColor: Colors.white.withValues(alpha: 0.8),
      style: const TextStyle(color: Colors.white),
      isExpanded: true,
      selectedItemBuilder: (context) {
        return availableAirports.map((airport) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${airport.code} • ${airport.city}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList();
      },
      items: availableAirports.map((airport) {
        return DropdownMenuItem<Airport>(
          value: airport,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  airport.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airport.city,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      airport.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
