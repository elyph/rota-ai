import 'package:flutter/material.dart';
import '../models/airport.dart';

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
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5374FF), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      hint: const Text('Seçiniz', style: TextStyle(color: Color(0xFF64748B))),
      dropdownColor: Colors.white,
      iconEnabledColor: const Color(0xFF64748B),
      style: const TextStyle(color: Color(0xFF0F172A)),
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
                color: Color(0xFF0F172A),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF5374FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  airport.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF5374FF),
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
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      airport.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
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

