import 'package:supabase_flutter/supabase_flutter.dart';

class TravelPlanService {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Yeni seyahat planı oluştur
  Future<Map<String, dynamic>?> createPlan({
    required String title,
    required String departureCity,
    required String arrivalCity,
    required String departureDate,
    String? returnDate,
    Map<String, dynamic>? flightInfo,
    Map<String, dynamic>? hotelInfo,
    List<Map<String, dynamic>>? selectedPlaces,
    String? itinerary,
    double? budget,
    double? estimatedCost,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _supabase.from('travel_plans').insert({
      'user_id': userId,
      'title': title,
      'departure_city': departureCity,
      'arrival_city': arrivalCity,
      'departure_date': departureDate,
      'return_date': returnDate,
      'flight_info': flightInfo,
      'hotel_info': hotelInfo,
      'selected_places': selectedPlaces,
      'itinerary': itinerary,
      'status': 'planned',
      if (budget != null) 'budget': budget,
      if (estimatedCost != null) 'estimated_cost': estimatedCost,
    }).select().single();

    return response;
  }

  /// Kullanıcının tüm planlarını getir
  Future<List<Map<String, dynamic>>> getMyPlans() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('travel_plans')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Plan güncelle
  Future<void> updatePlan(String planId, Map<String, dynamic> updates) async {
    updates['updated_at'] = DateTime.now().toIso8601String();
    await _supabase.from('travel_plans').update(updates).eq('id', planId);
  }

  /// Plan sil
  Future<void> deletePlan(String planId) async {
    await _supabase.from('travel_plans').delete().eq('id', planId);
  }
}
