import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NFCKosovaApp());
}

class NFCKosovaApp extends StatelessWidget {
  const NFCKosovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NFCKosova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF0284C7),
        cardColor: const Color(0xFF1E293B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFF10B981),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Të dhënat globale të thjeshta (In-Memory State)
  final List<ChatMessage> _messages = [
    ChatMessage(
      sender: "Ortaku",
      text: "Ofertë dërguar: Restaurant 'Dielli' - 20 Kartela me çmim 15€.",
      isOffer: true,
      time: "10:30",
    ),
  ];

  final Map<DateTime, List<TerminItem>> _terminet = {};
  final List<SaleRecord> _sales = [
    SaleRecord(date: DateTime.now().subtract(const Duration(days: 3)), count: 4, pricePerUnit: 15),
    SaleRecord(date: DateTime.now().subtract(const Duration(days: 2)), count: 8, pricePerUnit: 12),
    SaleRecord(date: DateTime.now().subtract(const Duration(days: 1)), count: 2, pricePerUnit: 15),
    SaleRecord(date: DateTime.now(), count: 6, pricePerUnit: 15),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatScreen(
        messages: _messages,
        onSendMessage: (msg) => setState(() => _messages.add(msg)),
      ),
      TermineScreen(
        terminet: _terminet,
        onAddTermin: (date, termin) {
          setState(() {
            final key = DateTime(date.year, date.month, date.day);
            _terminet.putIfAbsent(key, () => []).add(termin);
          });
        },
      ),
      LeaderboardScreen(
        sales: _sales,
        onAddSale: (sale) => setState(() => _sales.add(sale)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.nfc, color: Color(0xFF38BDF8)),
            const SizedBox(width: 8),
            const Text(
              'NFCKosova',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 2,
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        selectedIndex: _currentIndex,
        indicatorColor: const Color(0xFF0284C7).withOpacity(0.4),
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF38BDF8)),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: Color(0xFF38BDF8)),
            label: 'Termine',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard, color: Color(0xFF38BDF8)),
            label: 'Leaderboard',
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 1. MODULI CHAT (Oferta, Foto, Video, Custom Emoji)
// ----------------------------------------------------
class ChatMessage {
  final String sender;
  final String text;
  final bool isOffer;
  final String time;
  final String? mediaType; // 'photo' ose 'video'

  ChatMessage({
    required this.sender,
    required this.text,
    this.isOffer = false,
    required this.time,
    this.mediaType,
  });
}

class ChatScreen extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage) onSendMessage;

  const ChatScreen({super.key, required this.messages, required this.onSendMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _customEmojis = ["💳", "🔥", "🤝", "📈", "⭐", "💼", "📍", "✅"];

  void _send(String text, {bool isOffer = false, String? mediaType}) {
    if (text.trim().isEmpty && mediaType == null) return;
    final now = DateFormat('HH:mm').format(DateTime.now());
    widget.onSendMessage(ChatMessage(
      sender: "Unë",
      text: text,
      isOffer: isOffer,
      time: now,
      mediaType: mediaType,
    ));
    _controller.clear();
  }

  void _showOfferDialog() {
    final bizController = TextEditingController();
    final priceController = TextEditingController();
    final cardsController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Krijo Ofertë Biznesi 💼'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bizController,
              decoration: const InputDecoration(labelText: 'Emri i Biznesit (psh. Caffe X)'),
            ),
            TextField(
              controller: cardsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Numri i Kartelave'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Çmimi për copë (€)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Anulo')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              final biz = bizController.text;
              final cards = cardsController.text;
              final price = priceController.text;
              if (biz.isNotEmpty) {
                _send("Ofertë për: $biz\nSasia: $cards kartela | Çmimi: $price€/copë", isOffer: true);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Dërgo Ofertën', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: widget.messages.length,
            itemBuilder: (context, i) {
              final m = widget.messages[i];
              final isMe = m.sender == "Unë";
              return Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: m.isOffer
                        ? const Color(0xFF065F46)
                        : (isMe ? const Color(0xFF0369A1) : const Color(0xFF334155)),
                    borderRadius: BorderRadius.circular(12),
                    border: m.isOffer ? Border.all(color: const Color(0xFF34D399), width: 1.2) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (m.isOffer)
                        const Row(
                          children: [
                            Icon(Icons.local_offer, size: 16, color: Color(0xFF6EE7B7)),
                            SizedBox(width: 4),
                            Text("OFERTË ZYRTARE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6EE7B7))),
                          ],
                        ),
                      if (m.mediaType != null)
                        Container(
                          height: 120,
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Icon(
                              m.mediaType == 'photo' ? Icons.image : Icons.videocam,
                              size: 40,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      Text(m.text, style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(m.time, style: const TextStyle(fontSize: 10, color: Colors.white60)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Shiriti i Emojive Custom
        Container(
          height: 38,
          color: const Color(0xFF1E293B),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _customEmojis.length,
            itemBuilder: (ctx, idx) => GestureDetector(
              onTap: () => _controller.text += _customEmojis[idx],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(_customEmojis[idx], style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
        // Shiriti i shkrimit
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          color: const Color(0xFF0F172A),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFF10B981)),
                onPressed: _showOfferDialog,
                tooltip: 'Shto Ofertë',
              ),
              IconButton(
                icon: const Icon(Icons.photo, color: Colors.white70),
                onPressed: () => _send("Foto e ngarkuar", mediaType: 'photo'),
              ),
              IconButton(
                icon: const Icon(Icons.videocam, color: Colors.white70),
                onPressed: () => _send("Video e ngarkuar", mediaType: 'video'),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Shkruaj mesazh...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
                onPressed: () => _send(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 2. MODULI TERMINE (Kalendar & Njoftime 12:00 / 18:00)
// ----------------------------------------------------
class TerminItem {
  final String businessName;
  final String note;
  final String time;

  TerminItem({required this.businessName, required this.note, required this.time});
}

class TermineScreen extends StatefulWidget {
  final Map<DateTime, List<TerminItem>> terminet;
  final Function(DateTime, TerminItem) onAddTermin;

  const TermineScreen({super.key, required this.terminet, required this.onAddTermin});

  @override
  State<TermineScreen> createState() => _TermineScreenState();
}

class _TermineScreenState extends State<TermineScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<TerminItem> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return widget.terminet[key] ?? [];
  }

  void _showAddDialog() {
    if (_selectedDay == null) return;
    final bizController = TextEditingController();
    final noteController = TextEditingController();
    final timeController = TextEditingController(text: "14:00");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Shto Termin (${DateFormat('dd/MM/yyyy').format(_selectedDay!)})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: bizController,
              decoration: const InputDecoration(labelText: 'Emri i Biznesit'),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Ora e Takimit (psh. 13:30)'),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Shënim / Detaje'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mbyll')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () {
              if (bizController.text.isNotEmpty) {
                widget.onAddTermin(
                  _selectedDay!,
                  TerminItem(
                    businessName: bizController.text,
                    note: noteController.text,
                    time: timeController.text,
                  ),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ruaj Terminin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2025, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            // Ngjyra e datës ndërron kur ka termin
            markerDecoration: const BoxDecoration(
              color: Color(0xFF10B981), // E gjelbër me pikë/highlight kur ka termin
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFF0284C7).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF38BDF8),
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
        ),
        const Divider(color: Colors.white12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Takimet e ditës së zgjedhur:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.add_alarm, color: Color(0xFF10B981)),
                onPressed: _showAddDialog,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_active, color: Color(0xFFFBBF24), size: 18),
              SizedBox(width: 8),
              Text(
                "Njoftimet aktive cdo ditë në 12:00 dhe 18:00",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: selectedEvents.isEmpty
              ? const Center(child: Text("Nuk ka asnjë termin për këtë datë.", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  itemCount: selectedEvents.length,
                  itemBuilder: (ctx, i) {
                    final item = selectedEvents[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: const Color(0xFF1E293B),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF0284C7),
                          child: Icon(Icons.business, color: Colors.white),
                        ),
                        title: Text(item.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${item.time} - ${item.note}"),
                        trailing: const Icon(Icons.check_circle_outline, color: Color(0xFF10B981)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 3. MODULI LEADERBOARD (Shitjet & Grafiku me Vizë)
// ----------------------------------------------------
class SaleRecord {
  final DateTime date;
  final int count;
  final double pricePerUnit;

  SaleRecord({required this.date, required this.count, required this.pricePerUnit});

  double get total => count * pricePerUnit;
}

class LeaderboardScreen extends StatefulWidget {
  final List<SaleRecord> sales;
  final Function(SaleRecord) onAddSale;

  const LeaderboardScreen({super.key, required this.sales, required this.onAddSale});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedCount = 1; // 1-10
  double _pricePerUnit = 15.0; // euro në copë

  void _recordSale() {
    widget.onAddSale(SaleRecord(
      date: DateTime.now(),
      count: _selectedCount,
      pricePerUnit: _pricePerUnit,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Shitja u deklarua: ${_selectedCount * _pricePerUnit}€!"),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalRevenue = widget.sales.fold(0, (sum, item) => sum + item.total);
    int totalCards = widget.sales.fold(0, (sum, item) => sum + item.count);

    // Krijimi i pikave të grafikut (spots)
    List<FlSpot> spots = [];
    for (int i = 0; i < widget.sales.length; i++) {
      spots.add(FlSpot(i.toDouble(), widget.sales[i].total));
    }
    if (spots.isEmpty) spots = [const FlSpot(0, 0)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kartelat e Përmbledhjes
          Row(
            children: [
              Expanded(
                child: _buildStatCard("Totali Shitjeve", "$totalCards Copë", Icons.credit_card, const Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard("Fituar këtë Muaj", "$totalRevenue €", Icons.euro, const Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Formulari për Deklarimin e Shitjes
          Card(
            color: const Color(0xFF1E293B),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Deklaro Shitje të Re", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text("Numri i Kartelave: "),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: _selectedCount,
                        dropdownColor: const Color(0xFF1E293B),
                        items: List.generate(10, (index) => index + 1)
                            .map((e) => DropdownMenuItem(value: e, child: Text("$e copë")))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCount = val ?? 1),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Çmimi për copë (€): "),
                      const SizedBox(width: 10),
                      DropdownButton<double>(
                        value: _pricePerUnit,
                        dropdownColor: const Color(0xFF1E293B),
                        items: [10.0, 12.0, 15.0, 20.0, 25.0]
                            .map((e) => DropdownMenuItem(value: e, child: Text("$e €")))
                            .toList(),
                        onChanged: (val) => setState(() => _pricePerUnit = val ?? 15.0),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Totali i Llogaritur: ${_selectedCount * _pricePerUnit} €",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text("Regjistro Shitjen", style: TextStyle(color: Colors.white)),
                      onPressed: _recordSale,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Grafiku me vizë (Line Chart)
          const Text("Ecuria e Shitjeve (Dita me Ditë)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.only(right: 18, left: 10, top: 16, bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: const Color(0xFF38BDF8),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF38BDF8).withOpacity(0.15),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white60)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
