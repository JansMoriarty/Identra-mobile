import 'dart:math';
import 'package:flutter/material.dart';
import 'package:identra_mobile_flutter/main_navigation.dart';
import 'package:intl/intl.dart';
import '../services/voucher_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VoucherPage extends StatefulWidget {
  const VoucherPage({super.key});

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage>
    with SingleTickerProviderStateMixin {
  final VoucherService _voucherService = VoucherService();
  late TabController _tabController;

  Key _marketKey = UniqueKey();
  Key _inventoryKey = UniqueKey();
  Key _historyKey = UniqueKey();

  final String baseUrl =
      "https://spinningly-proscientific-renay.ngrok-free.dev/api";
  String? token;

  // Data Poin Sementara (Nanti dioverride oleh FutureBuilder)
  int userPoints = 0;
  String userRank = "Guru Teladan";

  // Filter Shop
  String selectedFilter = "All";
  final List<String> filters = ["All", "WFH", "Absensi"];

  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));

    // 1. Jalankan fetch profile
    _profileFuture = _voucherService.getProfile();

    // 2. Ambil nilai current_points dan masukkan ke variabel lokal
    _profileFuture.then((data) {
      if (mounted && data.isNotEmpty) {
        setState(() {
          // Pastikan key-nya sesuai dengan JSON API: 'current_points'
          userPoints = data['current_points'] ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF131A2A), // Dark Background
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabPill(),
            _buildHeaderBanner(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMarketplaceTab(), // Index 0 (Shop)
                  _buildInventoryTab(), // Index 1 (My Item)
                  _buildMutationTab(), // Index 2 (History)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // HEADER COMPONENTS
  // ==========================================

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MainNavigation()),
              );
            },
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Poin & Reward",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20), // Spacer untuk menyeimbangkan posisi title
        ],
      ),
    );
  }

  Widget _buildTabPill() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2638), // Warna dasar pill gelap
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildTabButton("Shop", Icons.shopping_bag, 0),
          _buildTabButton("My Item", Icons.shopping_basket, 1),
          _buildTabButton("History", Icons.history, 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, int index) {
    bool isActive = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF4E65F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14, color: isActive ? Colors.white : Colors.white54),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        var points = snapshot.data?['current_points'] ?? userPoints;
        var rank = snapshot.data?['rank_name'] ?? userRank;

        return Container(
          width: double.infinity,
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // GANTI 'assets/images/bg_point_banner.png' DENGAN PATH GAMBARMU
            image: const DecorationImage(
              image: AssetImage('assets/images/bg_point_banner.png'),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4E65F1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // BADGE RANKING
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFC247).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: Color(0xFFFFC247), size: 14),
                      const SizedBox(width: 6),
                      Text(
                        rank,
                        style: const TextStyle(
                          color: Color(0xFFFFC247),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // POINTS
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.monetization_on,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "$points",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "PTS",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 1: SHOP (MARKETPLACE)
  // ==========================================
  // ==========================================
  // TAB 1: SHOP (MARKETPLACE)
  // ==========================================
  Widget _buildMarketplaceTab() {
    return Column(
      children: [
        // FILTER BUTTONS ROW
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: filters.map((filter) {
              bool isSelected = selectedFilter == filter;
              return GestureDetector(
                onTap: () => setState(() => selectedFilter = filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4E65F1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // GRID MARKETPLACE
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            key: _marketKey,
            future: _voucherService.getVouchers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState("Shop kosong");
              }

              return GridView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio:
                        0.72, // Sedikit diubah agar konten text tidak sesak
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final item = snapshot.data![index];

                    int cost = item['point_cost'] ?? 0;
                    String title = item['item_name'] ?? "Voucher";
                    String type = item['item_type'] ?? '';

                    int remaining = item['remaining_quota'] ?? 0;
                    int limit = item['monthly_limit'] ?? 0;

                    bool isLimitReached = item['is_limit_reached'] ?? false;
                    bool canBuy = userPoints >= cost && !isLimitReached;

                    /// LOGIC ICON & COLOR TEMA
                    IconData iconData;
                    Color iconColor;

                    switch (type) {
                      case 'LATE_WAVER':
                        iconData = Icons.access_time_filled_rounded;
                        iconColor = const Color(0xFFFFC247); // Blue
                        break;
                      case 'WFH_PASS':
                        iconData = Icons.home_work_rounded;
                        iconColor = const Color(0xFFFF6459); // Coral/Red
                        break;
                      case 'LEAVE_PERMISSION':
                        iconData = Icons.event_available_rounded;
                        iconColor = const Color(0xFFFFC247); // Yellow/Amber
                        break;
                      default:
                        iconData = Icons.card_giftcard;
                        iconColor = Colors.white70;
                    }

                    return Opacity(
                      opacity: isLimitReached ? 0.6 : 1,
                      child: Stack(
                        children: [
                          /// MAIN TICKET STRUCTURE
                          ClipPath(
                            clipper: TicketClipper(
                                cutY: 80.0), // Garis potong di 80px
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF1B2030), // Warna background bawah (gelap)
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.04)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  /// 1. TOP SECTION (WRAPPER BERWARNA SESUAI GAMBAR)
                                  /// 1. TOP SECTION (WRAPPER BERWARNA DENGAN RADIUS)
                                  Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      // Memberikan radius hanya di bagian atas saja
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      // Background atas menggunakan warna icon transparan
                                      color: iconColor.withOpacity(0.12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        iconData,
                                        color: iconColor,
                                        size: 38,
                                      ),
                                    ),
                                  ),

                                  /// 2. DASHED CUT LINE (TEPAT DI TENGAH CLIPPER)
                                  SizedBox(
                                    height: 1,
                                    child: CustomPaint(
                                      painter: TicketDashedLinePainter(
                                        color: iconColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ),

                                  /// 3. BOTTOM CONTENT
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          14, 14, 14, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// TITLE
                                          Text(
                                            title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              height: 1.5,
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          /// ROW POIN & SISA STOK
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Section Koin
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.monetization_on,
                                                    size: 14,
                                                    color: Colors.amber,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    "$cost Poin",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Section Sisa Stok
                                              Text(
                                                limit == 0
                                                    ? "~"
                                                    : isLimitReached
                                                        ? "Habis"
                                                        : "Sisa $remaining",
                                                style: TextStyle(
                                                  color: isLimitReached
                                                      ? Colors.redAccent
                                                      : Colors.white54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const Spacer(),

                                          /// CTA BUTTON
                                          GestureDetector(
                                            onTap: () => canBuy
                                                ? _handleRedeem(item)
                                                : _showError(isLimitReached
                                                    ? "Limit habis"
                                                    : "Poin tidak cukup"),
                                            child: Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                color: canBuy
                                                    ? const Color(0xFF4A65E6)
                                                    : Colors.grey.shade800,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                isLimitReached
                                                    ? "Sold Out"
                                                    : "Tukar",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          /// LABEL OVERLAY (OPSIONAL)
                          if (isLimitReached)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "LIMIT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  });
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: MY ITEMS (INVENTORY)
  // ==========================================
  Widget _buildInventoryTab() {
    return FutureBuilder<List<dynamic>>(
      key: _inventoryKey,
      future: _voucherService.getMyTokens(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("Inventory kosong");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final token = snapshot.data![index];
            final item = token['item'];
            bool isUsed = token['status'] != 'AVAILABLE';

            // Set warna berdasarkan tipe item
            String title = item['item_name'] ?? "Token";
            Color cardColor = isUsed
                ? Colors.grey.shade800
                : (title.toLowerCase().contains('absen') ||
                        title.toLowerCase().contains('terlambat')
                    ? const Color(0xFF4E65F1)
                    : const Color(0xFF00B09B));

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: ClipPath(
                clipper: SideCutoutClipper(), // Memotong bagian Kanan saja
                child: Container(
                  height: 140, // Fixed height agar bentuk clipper sempurna
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Garis putus-putus pembatas (Manual drawing menggunakan CustomPaint)
                      Positioned(
                        left: 100,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          size: const Size(1, double.infinity),
                          painter: DashedLinePainter(),
                        ),
                      ),
                      Row(
                        children: [
                          // Bagian Kiri (Icon)
                          SizedBox(
                            width: 100,
                            child: Center(
                              child: Icon(
                                title.toLowerCase().contains('terlambat')
                                    ? Icons.history_toggle_off
                                    : Icons.maps_home_work,
                                color: isUsed ? Colors.white54 : Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          // Bagian Kanan (Detail Text)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 16, right: 30, top: 20, bottom: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isUsed
                                          ? Colors.white54
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Text(
                                      isUsed
                                          ? "Sudah Digunakan"
                                          : "Gunakan token ini untuk kebutuhan absen/keterlambatan.",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isUsed
                                            ? Colors.white38
                                            : Colors.white70,
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isUsed ? token['status'] : "Tersedia",
                                      style: TextStyle(
                                        color: isUsed
                                            ? Colors.white54
                                            : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // TAB 3: HISTORY (MUTATION) TIMELINE
  // ==========================================
  Widget _buildMutationTab() {
    return FutureBuilder<List<dynamic>>(
      key: _historyKey,
      future: _voucherService.getMutationHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState("Belum ada riwayat");
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final log = snapshot.data![index];
            int amount = log['amount'] is String
                ? int.parse(log['amount'])
                : log['amount'];

            bool isCredit = amount > 0;
            bool isExchange = log['description']
                .toString()
                .toLowerCase()
                .contains('penukaran');

            // Sesuaikan warna persis seperti UI
            Color iconColor = isCredit
                ? const Color(0xFF00D261) // Hijau Reward
                : (isExchange
                    ? const Color(0xFFFFC247)
                    : const Color(0xFFFF5E5E)); // Kuning Penukaran, Merah Denda

            IconData iconData = isCredit
                ? Icons.schedule
                : (isExchange ? Icons.monetization_on : Icons.schedule);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kolom Timeline
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2638),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor, width: 2),
                      ),
                      child: Icon(iconData, size: 14, color: iconColor),
                    ),
                    if (index != snapshot.data!.length - 1)
                      Container(
                        height: 60,
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child:
                            CustomPaint(painter: VerticalDashedLinePainter()),
                      )
                  ],
                ),
                const SizedBox(width: 16),
                // Kolom Kartu
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2638), // Dark card
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['description'] ?? "Transaksi",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('dd MMM yyyy')
                                    .format(DateTime.parse(log['created_at'])),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "${isCredit ? '+' : ''}$amount",
                          style: TextStyle(
                            color: iconColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 50, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  // ==========================================
  // ACTION LOGICS
  // ==========================================
  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _handleRedeem(Map<String, dynamic> item) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2638),
        title: const Text("Konfirmasi", style: TextStyle(color: Colors.white)),
        content: Text(
            "Tukar ${item['point_cost']} poin untuk ${item['item_name']}?",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text("Batal", style: TextStyle(color: Colors.white54))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4E65F1)),
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text("Tukar", style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Tampilkan loading indikator (Opsional tapi disarankan)
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // 2. Pastikan ID dikirim sebagai Integer (Paksa konversi jika perlu)
        final int itemId = int.parse(item['id'].toString());

        final result = await _voucherService.redeemVoucher(itemId);

        // Tutup loading indikator
        Navigator.pop(context);

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("Berhasil menukar poin!"),
              backgroundColor: Colors.green));

          setState(() {
            _marketKey = UniqueKey();
            _inventoryKey = UniqueKey();
            _historyKey = UniqueKey();
            _profileFuture = _voucherService.getProfile();
          });
        } else {
          _showError(result['message'] ?? "Gagal menukar");
        }
      } catch (e) {
        Navigator.pop(context); // Tutup loading jika error
        _showError("Terjadi kesalahan: $e");
      }
    }
  }
}

// ==========================================
// CUSTOM CLIPPERS & PAINTERS
// ==========================================

// Memotong SETENGAH lingkaran hanya di sisi KANAN
class SideCutoutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(size.width, 0);
    // Potongan kanan
    path.lineTo(size.width, size.height / 2 - 15);
    path.arcToPoint(
      Offset(size.width, size.height / 2 + 15),
      radius: const Radius.circular(15),
      clockwise: false,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

// Melukis garis putus-putus vertikal untuk tiket
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 6, dashSpace = 6, startY = 10;
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    while (startY < size.height - 10) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Garis putus-putus untuk Timeline History
class VerticalDashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 4, dashSpace = 4, startY = 0;
    final paint = Paint()
      ..color = Colors.white30
      ..strokeWidth = 1.5;
    while (startY < size.height) {
      canvas.drawLine(Offset(size.width / 2, startY),
          Offset(size.width / 2, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class TicketClipper extends CustomClipper<Path> {
  final double cutY; // Tambahkan agar tinggi potongan tiket presisi

  TicketClipper({this.cutY = 80.0});

  @override
  Path getClip(Size size) {
    const cutRadius = 14.0;
    Path path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0);

    // Kanan
    path.lineTo(size.width, cutY - cutRadius);
    path.arcToPoint(
      Offset(size.width, cutY + cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);

    // Kiri
    path.lineTo(0, cutY + cutRadius);
    path.arcToPoint(
      Offset(0, cutY - cutRadius),
      radius: const Radius.circular(cutRadius),
      clockwise: false,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TicketClipper oldClipper) =>
      oldClipper.cutY != cutY;
}

// Tambahkan Color parameter agar garis titik-titik sama dengan warna Icon
class TicketDashedLinePainter extends CustomPainter {
  final Color color;

  TicketDashedLinePainter({this.color = Colors.white54});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    var dashWidth = 6.0;
    var dashSpace = 6.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant TicketDashedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
