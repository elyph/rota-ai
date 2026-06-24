import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/travel_plan_service.dart';
import 'plan_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TravelPlanService _planService = TravelPlanService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  List<Map<String, dynamic>>? _userPlans;

  @override
  void initState() {
    super.initState();
    _loadUserPlans();
  }

  Future<void> _loadUserPlans() async {
    try {
      final plans = await _planService.getMyPlans();
      setState(() => _userPlans = plans);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF5374FF),
              child: Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text(
              'Rota AI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Color(0xFF64748B)),
            onPressed: () {
              setState(() => _chatService.clearHistory());
            },
            tooltip: 'Sohbeti temizle',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final messages = _chatService.history;

    if (messages.isEmpty) {
      return _buildWelcome();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(messages[index]);
      },
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const CircleAvatar(
            radius: 36,
            backgroundColor: Color(0xFF5374FF),
            child: Icon(Icons.smart_toy_outlined, size: 36, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            'Merhaba!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seyahat planlama konusunda sana\nyardımcı olmak için buradayım.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          // /plan komutu öne çıkan chip
          _buildPlanCommandBanner(),
          const SizedBox(height: 16),
          _buildSuggestionChip('Tatil için nereye gidebilirim?'),
          _buildSuggestionChip('3 günlük İstanbul planı oluştur'),
          _buildSuggestionChip('Antalya\'da ne yenir?'),
        ],
      ),
    );
  }

  Widget _buildPlanCommandBanner() {
    return GestureDetector(
      onTap: () {
        _controller.text = '/plan ';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5374FF), Color(0xFF7C5CFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '/plan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Otomatik Plan Oluştur',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Uçuş ve otel bul, planı kaydet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _sendMessage(text),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF5374FF),
                  child: Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF5374FF) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    boxShadow: isUser
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (isUser) const SizedBox(width: 10),
            ],
          ),
          // Plan kartı — sadece assistant mesajında ve planData varsa
          if (!isUser && message.planData != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: _PlanCard(
                data: message.planData!,
                planService: _planService,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF5374FF),
            child: Icon(Icons.smart_toy_outlined, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    final isPlanMode = _controller.text.trim().toLowerCase().startsWith('/plan');

    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // /plan modu ipucu
          if (isPlanMode)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Text(
                '✈️  /plan [nereden] [nereye] [tarih aralığı]  →  uçuş + otel arar',
                style: TextStyle(
                  color: Color(0xFF4338CA),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                    border: isPlanMode
                        ? Border.all(color: const Color(0xFF5374FF), width: 1.5)
                        : null,
                  ),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Mesaj yaz veya /plan komutunu kullan...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      prefixIcon: isPlanMode
                          ? const Padding(
                              padding: EdgeInsets.only(left: 12, right: 4),
                              child: Icon(Icons.flight_takeoff_rounded,
                                  color: Color(0xFF5374FF), size: 20),
                            )
                          : null,
                      prefixIconConstraints: const BoxConstraints(minWidth: 0),
                    ),
                    onSubmitted: (_) => _sendCurrentMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isLoading ? null : _sendCurrentMessage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF5374FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(
                    _isLoading
                        ? Icons.hourglass_top_rounded
                        : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendCurrentMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() {});
    _sendMessage(text);
  }

  Future<void> _sendMessage(String message) async {
    setState(() => _isLoading = true);
    _scrollToBottom();

    try {
      await _chatService.sendMessage(message, userPlans: _userPlans);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────
// Plan Kartı — kaydırmalı seçim + kaydetme
// ─────────────────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final TravelPlanService planService;

  const _PlanCard({required this.data, required this.planService});

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  late Map<String, dynamic>? _selectedFlight;
  late Map<String, dynamic>? _selectedReturn;
  late Map<String, dynamic>? _selectedHotel;
  late Set<int> _selectedPlaceIndices; // seçili yer indeksleri
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _selectedFlight = widget.data['best_flight'] as Map<String, dynamic>?;
    _selectedReturn = widget.data['best_return_flight'] as Map<String, dynamic>?;
    _selectedHotel = widget.data['best_hotel'] as Map<String, dynamic>?;
    _selectedPlaceIndices = {};
  }

  List<Map<String, dynamic>> get _allFlights =>
      (widget.data['all_flights'] as List? ?? []).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get _allReturns =>
      (widget.data['all_return_flights'] as List? ?? []).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get _allHotels =>
      (widget.data['all_hotels'] as List? ?? []).cast<Map<String, dynamic>>();
  static const String _backendUrl = 'http://localhost:8004';

  List<Map<String, dynamic>> get _allPlaces {
    return (widget.data['all_places'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map((p) {
      final url = p['photoUrl'] as String? ?? '';
      if (url.startsWith('/')) {
        return {...p, 'photoUrl': '$_backendUrl$url'};
      }
      return p;
    }).toList();
  }

  int get _nights => (widget.data['nights'] as num?)?.toInt() ?? 1;
  double? get _budget => (widget.data['budget'] as num?)?.toDouble();

  double get _totalCost =>
      (_selectedFlight?['price'] as num? ?? 0).toDouble() +
      (_selectedReturn?['price'] as num? ?? 0).toDouble() +
      ((_selectedHotel?['pricePerNight'] as num? ?? 0).toDouble() * _nights);

  @override
  Widget build(BuildContext context) {
    final dep = widget.data['departure_city'] ?? '';
    final arr = widget.data['arrival_city'] ?? '';
    final depDate = widget.data['departure_date'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5374FF), Color(0xFF7C5CFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_takeoff_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$dep → $arr',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const Spacer(),
                Text(depDate,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),

          // Gidiş uçuşu seçimi
          _buildSection(
            label: '✈️  Gidiş Uçuşu',
            emptyText: 'Uçuş bulunamadı',
            items: _allFlights,
            selected: _selectedFlight,
            onSelect: (f) => setState(() => _selectedFlight = f),
            itemBuilder: _buildFlightCard,
          ),

          // Dönüş uçuşu seçimi
          if (widget.data['return_date'] != null)
            _buildSection(
              label: '🔄  Dönüş Uçuşu',
              emptyText: 'Dönüş uçuşu bulunamadı',
              items: _allReturns,
              selected: _selectedReturn,
              onSelect: (f) => setState(() => _selectedReturn = f),
              itemBuilder: _buildFlightCard,
            ),

          // Otel seçimi
          _buildSection(
            label: '🏨  Otel',
            emptyText: 'Otel bulunamadı',
            items: _allHotels,
            selected: _selectedHotel,
            onSelect: (h) => setState(() => _selectedHotel = h),
            itemBuilder: _buildHotelCard,
          ),

          // Gezilecek yerler
          if (_allPlaces.isNotEmpty) _buildPlacesSection(),

          // Toplam maliyet
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text('Toplam Maliyet',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A))),
                const Spacer(),
                Text(
                  '${_totalCost.toStringAsFixed(0)} ₺',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _budget == null || _totalCost <= _budget!
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
                if (_budget != null) ...[
                  const SizedBox(width: 6),
                  Text('/ ${_budget!.toStringAsFixed(0)} ₺',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(width: 4),
                  Icon(
                    _totalCost <= _budget!
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    size: 16,
                    color: _totalCost <= _budget!
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ],
              ],
            ),
          ),

          // Butonlar
          _saved
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF22C55E), size: 18),
                        SizedBox(width: 6),
                        Text('Plan Kaydedildi',
                            style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveAndClose,
                          icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                          label: const Text('Planı Kaydet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5374FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saveAndNavigate,
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: const Text('AI ile Planla ve Kaydet'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF5374FF),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFF5374FF)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // Bölüm: başlık + yatay kaydırmalı kartlar
  Widget _buildSection({
    required String label,
    required String emptyText,
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic>? selected,
    required ValueChanged<Map<String, dynamic>> onSelect,
    required Widget Function(Map<String, dynamic>, bool) itemBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3)),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 16),
              child: Text(emptyText,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                      fontStyle: FontStyle.italic)),
            )
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final isSelected = selected == item ||
                      (selected != null &&
                          selected.toString() == item.toString());
                  return GestureDetector(
                    onTap: () => onSelect(item),
                    child: itemBuilder(item, isSelected),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // Uçuş kartı
  Widget _buildFlightCard(Map<String, dynamic> f, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF5374FF) : const Color(0xFFE2E8F0),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_rounded, size: 14, color: Color(0xFF5374FF)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  f['airline'] ?? '',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 14, color: Color(0xFF5374FF)),
            ],
          ),
          Text(
            '${f['departure_time'] ?? '?'} → ${f['arrival_time'] ?? '?'}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                f['duration'] ?? '',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
              Text(
                '${f['price'] ?? '?'} ₺',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF5374FF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Otel kartı — tıklanabilir detay + görsel + rating
  Widget _buildHotelCard(Map<String, dynamic> h, bool selected) {
    final stars = (h['stars'] as num?)?.toInt() ?? 0;
    final rating = (h['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (h['reviewCount'] as num?)?.toInt() ?? 0;
    final imageUrl = h['imageUrl'] as String? ?? '';
    final pricePerNight = (h['pricePerNight'] as num?)?.toDouble() ?? 0;

    return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 190,
        height: 90,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF7ED) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFFF8C42) : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Görsel — sabit 80x90
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: SizedBox(
                width: 80, height: 90,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.hotel_rounded,
                              color: Color(0xFFCBD5E1), size: 24),
                        ))
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.hotel_rounded,
                            color: Color(0xFFCBD5E1), size: 24),
                      ),
              ),
            ),
            // Bilgi — Expanded ile kalan alanı doldur
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // İsim
                    Text(
                      h['name'] ?? '',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Yıldız sınıfı + puan
                    Row(
                      children: [
                        ...List.generate(stars.clamp(0, 5),
                            (_) => const Icon(Icons.star_rounded,
                                size: 10, color: Color(0xFFFBBF24))),
                        const SizedBox(width: 3),
                        if (rating > 0)
                          Text('${rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A))),
                        if (reviewCount > 0)
                          Text(' (${_formatCount(reviewCount)})',
                              style: const TextStyle(
                                  fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                    // Fiyat + seçim işareti
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${pricePerNight.toStringAsFixed(0)} ₺/g',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFF8C42)),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFFFF8C42))
                        else
                          GestureDetector(
                            onTap: () => _showHotelDetail(h),
                            child: const Icon(Icons.info_outline_rounded,
                                size: 16, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }

  // Sayıyı k formatına çevir: 1200 → 1,2b
  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}b';
    return '$n';
  }

  // Amenity çevirisi
  static const Map<String, String> _amenityTr = {
    'free parking': 'Ücretsiz otopark', 'parking': 'Otopark',
    'indoor pool': 'Kapalı havuz', 'outdoor pool': 'Açık havuz', 'pool': 'Havuz',
    'fitness center': 'Spor salonu', 'fitness centre': 'Spor salonu',
    'restaurant': 'Restoran', 'free breakfast': 'Ücretsiz kahvaltı',
    'breakfast (\$)': 'Kahvaltı (ücretli)', 'breakfast included': 'Kahvaltı dahil',
    'spa': 'Spa', 'beach access': 'Plaj erişimi',
    'child-friendly': 'Çocuk dostu', 'kid-friendly': 'Çocuk dostu',
    'bar': 'Bar', 'pet-friendly': 'Evcil hayvan kabul edilir',
    'room service': 'Oda servisi', 'room service (\$)': 'Oda servisi (ücretli)',
    'free wi-fi': 'Ücretsiz Wi-Fi', 'air-conditioned': 'Klima',
    'air conditioning': 'Klima', 'all-inclusive available': 'Her şey dahil seçeneği',
    'all-inclusive': 'Her şey dahil', 'wheelchair accessible': 'Tekerlekli sandalye erişimi',
    'accessible': 'Engelli erişimi', 'ev charger': 'Elektrikli araç şarjı',
    'hot tub': 'Jakuzi', 'outdoor grill': 'Açık ızgara', 'fireplace': 'Şömine',
    'patio or deck': 'Veranda', 'kitchen': 'Mutfak', 'cot': 'Portatif yatak',
    'crib': 'Bebek karyolası', 'washer': 'Çamaşır makinesi',
    'smoke-free': 'Sigara içilmez', 'smoke-free property': 'Sigara içilmez',
    'ironing board': 'Ütü masası', 'elevator': 'Asansör', 'microwave': 'Mikrodalga',
    'oven stove': 'Fırın/ocak', 'balcony': 'Balkon',
    'airport shuttle': 'Havaalanı servisi', 'airport shuttle (\$)': 'Havaalanı servisi (ücretli)',
    'parking (\$)': 'Otopark (ücretli)', 'restaurant (\$)': 'Restoran (ücretli)',
    'bar (\$)': 'Bar (ücretli)', 'laundry service': 'Çamaşır servisi',
    'full-service laundry': 'Tam çamaşır servisi', 'business center': 'İş merkezi',
    'outdoor space': 'Açık alan', 'terrace': 'Teras', 'concierge': 'Konsiyerj',
    'golf': 'Golf', 'casino': 'Kumarhane', '24-hour front desk': '24 saat resepsiyon',
    'luggage storage': 'Bagaj emaneti', 'non-smoking rooms': 'Sigara içilmeyen odalar',
    'family rooms': 'Aile odaları', 'ocean view': 'Deniz manzarası',
    'mountain view': 'Dağ manzarası', 'city view': 'Şehir manzarası',
    'kitchen in some rooms': 'Bazı odalarda mutfak',
    'no airport shuttle': 'Havaalanı servisi yok', 'no beach access': 'Plaj erişimi yok',
    'no elevator': 'Asansör yok', 'no indoor pool': 'Kapalı havuz yok',
    'no kitchen': 'Mutfak yok', 'not kid-friendly': 'Çocuk dostu değil',
    'not wheelchair accessible': 'Tekerlekli sandalye erişimi yok',
  };

  String _tr(String a) => _amenityTr[a.toLowerCase().trim()] ?? a;

  void _showHotelDetail(Map<String, dynamic> h) {
    final stars = (h['stars'] as num?)?.toInt() ?? 0;
    final rating = (h['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (h['reviewCount'] as num?)?.toInt() ?? 0;
    final imageUrl = h['imageUrl'] as String? ?? '';
    final pricePerNight = (h['pricePerNight'] as num?)?.toDouble();
    final amenities = (h['amenities'] as List? ?? []).cast<String>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 130, height: 130,
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.hotel_rounded,
                                    size: 48, color: Color(0xFF94A3B8)),
                              ))
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.hotel_rounded,
                                  size: 48, color: Color(0xFF94A3B8)),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A))),
                        const SizedBox(height: 8),
                        // Puan
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded,
                                      size: 15, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 3),
                                  Text(rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF92400E))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$reviewCount değerlendirme',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Yıldız sınıfı
                        Row(
                          children: [
                            ...List.generate(
                              stars.clamp(0, 5),
                              (_) => const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFFBBF24)),
                            ),
                            ...List.generate(
                              (5 - stars).clamp(0, 5),
                              (_) => const Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFE2E8F0)),
                            ),
                            const SizedBox(width: 6),
                            Text('$stars yıldız',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        if (pricePerNight != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${pricePerNight.toStringAsFixed(0)} ₺ / gece',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF5374FF)),
                          ),
                          Text(
                            '${_nights} gece = ${(pricePerNight * _nights).toStringAsFixed(0)} ₺',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if ((h['address'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Adres',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(h['address'] ?? '',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.4)),
                    ),
                  ],
                ),
              ],
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text('Olanaklar',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: amenities
                      .map((a) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(_tr(a),
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF334155),
                                    fontWeight: FontWeight.w500)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Gezilecek yerler — çok seçimli yatay kaydırmalı bölüm
  Widget _buildPlacesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '📍  Gezilecek Yerler',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              if (_selectedPlaceIndices.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedPlaceIndices.length} seçildi',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'İstediğin yerlere dokun, seç/kaldır',
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: _allPlaces.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final selected = _selectedPlaceIndices.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedPlaceIndices.remove(i);
                    } else {
                      _selectedPlaceIndices.add(i);
                    }
                  }),
                  child: _buildPlaceCard(_allPlaces[i], selected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, bool selected) {
    final photoUrl = place['photoUrl'] as String? ?? '';
    final name = place['name'] as String? ?? '';
    final rating = (place['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (place['userRatingsTotal'] as num?)?.toInt() ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Görsel
            photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.image_not_supported_rounded,
                          color: Color(0xFFCBD5E1), size: 32),
                    ),
                  )
                : Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.place_rounded,
                        color: Color(0xFFCBD5E1), size: 32),
                  ),
            // Alt gradient + isim
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (rating > 0)
                      Text(
                        reviewCount > 0
                            ? '⭐ ${rating.toStringAsFixed(1)} (${_formatCount(reviewCount)})'
                            : '⭐ ${rating.toStringAsFixed(1)}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
            // Seçim işareti
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _doSave() async {
    final dep = widget.data['departure_city'] as String? ?? '';
    final arr = widget.data['arrival_city'] as String? ?? '';

    // Seçili yerleri listele
    final selectedPlaces = _selectedPlaceIndices
        .toList()
        ..sort();
    final placesList = selectedPlaces
        .map((i) => {
              'name': _allPlaces[i]['name'] ?? '',
              'address': _allPlaces[i]['address'] ?? '',
            })
        .toList();

    return await widget.planService.createPlan(
      title: '$dep → $arr Seyahati',
      departureCity: dep,
      arrivalCity: arr,
      departureDate: widget.data['departure_date'] as String? ?? '',
      returnDate: widget.data['return_date'] as String?,
      flightInfo: _selectedFlight != null
          ? {..._selectedFlight!, 'return_flight': _selectedReturn}
          : null,
      hotelInfo: _selectedHotel,
      selectedPlaces: placesList,
      budget: _budget,
      estimatedCost: _totalCost,
    );
  }

  Future<void> _saveAndClose() async {
    try {
      await _doSave();
      if (mounted) setState(() => _saved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Plan başarıyla kaydedildi!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kaydetme hatası: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _saveAndNavigate() async {
    try {
      final saved = await _doSave();
      if (mounted) setState(() => _saved = true);
      if (mounted && saved != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlanDetailScreen(plan: saved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}
