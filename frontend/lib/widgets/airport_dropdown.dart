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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.lightBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: AppTheme.darkColor),
      ),
      hint: Text('Seçiniz', style: TextStyle(color: Colors.grey.shade500)),
      isExpanded: true,
      items: availableAirports.map((airport) {
        return DropdownMenuItem<Airport>(
          value: airport,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  airport.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airport.city,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      airport.name,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
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
