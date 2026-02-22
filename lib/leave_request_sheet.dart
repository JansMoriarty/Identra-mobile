import 'dart:io';
import 'package:flutter/material.dart';
import 'package:identra_mobile_flutter/services/leave_service.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

// Asumsi AppColors kamu
class AppColors {
  static const Color cardBg = Color(0xFF1F222E);
  static const Color primaryBlue = Color(0xFF4E6AF3);
  static const Color redBg = Color(0xFF382229);
  static const Color redIcon = Color(0xFFFF3B30);
  static const Color orangeBg = Color(0xFF3E2B25);
  static const Color orangeIcon = Color(0xFFFF9500);
  static const Color blueBg = Color(0xFF22314F);
  static const Color blueIcon = Color(0xFF4E6AF3);
}

class LeaveRequestSheet extends StatefulWidget {
  const LeaveRequestSheet({super.key});

  @override
  State<LeaveRequestSheet> createState() => _LeaveRequestSheetState();
}

class _LeaveRequestSheetState extends State<LeaveRequestSheet> {
  // Sesuai Enum di Laravel: izin, sakit, cuti
  String selectedType = 'sakit';
  DateTime? startDate;
  DateTime? endDate;
  File? _selectedImage;

  final TextEditingController _reasonController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;

  // Fungsi Pilih Tanggal
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryBlue,
              surface: AppColors.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          if (endDate == null || endDate!.isBefore(startDate!)) {
            endDate = picked;
          }
        } else {
          endDate = picked;
        }
      });
    }
  }

  // Fungsi Pilih Gambar
  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        // Agar aman jika layar kecil
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Pengajuan Izin",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                )
              ],
            ),
            const SizedBox(height: 24),

            // --- PILIH TIPE IZIN ---
            const _LabelForm(label: "Alasan Berhalangan"),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeChip('sakit', Icons.medication_rounded,
                    AppColors.redBg, AppColors.redIcon),
                const SizedBox(width: 10),
                _buildTypeChip('izin', Icons.assignment_ind_rounded,
                    AppColors.orangeBg, AppColors.orangeIcon),
                const SizedBox(width: 10),
                _buildTypeChip('cuti', Icons.event_busy_rounded,
                    AppColors.blueBg, AppColors.blueIcon),
              ],
            ),

            const SizedBox(height: 24),

            // --- PILIH TANGGAL ---
            const _LabelForm(label: "Durasi Waktu"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDateTile("Mulai", startDate, true)),
                const SizedBox(width: 12),
                Expanded(child: _buildDateTile("Selesai", endDate, false)),
              ],
            ),

            const SizedBox(height: 24),

            // --- INPUT ALASAN ---
            const _LabelForm(label: "Keterangan Alasan"),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration("Tulis alasan detail di sini..."),
            ),

            const SizedBox(height: 24),

            // --- LAMPIRAN FOTO ---
            const _LabelForm(label: "Lampiran Foto (Bukti)"),
            const SizedBox(height: 12),
            _buildImagePickerArea(),

            const SizedBox(height: 32),

            // --- TOMBOL SUBMIT ---
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Kirim Pengajuan",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTypeChip(
      String label, IconData icon, Color bgColor, Color iconColor) {
    bool isSelected = selectedType == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedType = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected
                    ? iconColor.withOpacity(0.5)
                    : Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? iconColor : Colors.white24, size: 24),
              const SizedBox(height: 8),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(String title, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: AppColors.primaryBlue, size: 16),
                const SizedBox(width: 8),
                Text(
                  date == null ? "Pilih" : DateFormat('dd/MM/yy').format(date),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerArea() {
    return GestureDetector(
      onTap: () => _showPickerOptions(),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined,
                      color: Colors.white10, size: 32),
                  const SizedBox(height: 8),
                  const Text("Upload Foto Bukti",
                      style: TextStyle(color: Colors.white10, fontSize: 12)),
                ],
              ),
      ),
    );
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
            title: const Text("Kamera", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.photo_library, color: AppColors.primaryBlue),
            title: const Text("Galeri", style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
      filled: true,
      fillColor: AppColors.cardBg,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primaryBlue)),
    );
  }

  // LOGIKA KIRIM DATA
  // Di dalam class _LeaveRequestSheetState

  void _submitData() async {
    // 1. Cegah double submit jika masih loading
    if (isLoading) return;

    if (startDate == null ||
        endDate == null ||
        _reasonController.text.isEmpty) {
      _showSnackBar("Harap lengkapi semua data dan tanggal!", Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    String formattedStart = DateFormat('yyyy-MM-dd').format(startDate!);
    String formattedEnd = DateFormat('yyyy-MM-dd').format(endDate!);

    try {
      // 3. Panggil Service dengan await
      bool success = await LeaveService().submitLeaveRequest(
        jenis: selectedType,
        tanggalMulai: formattedStart,
        tanggalSelesai: formattedEnd,
        alasan: _reasonController.text,
        image: _selectedImage,
      );

      if (success) {
        _showSnackBar("Pengajuan berhasil dikirim!", Colors.green);
        if (mounted) Navigator.pop(context);
      } else {
        _showSnackBar("Gagal mengirim pengajuan.", Colors.red);
      }
    } catch (e) {
      // 4. MENANGKAP PESAN ERROR DARI LARAVEL
      // e akan berisi string "Anda sudah membuat pengajuan..."
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      // Pastikan loading dimatikan apapun hasilnya
      if (mounted) setState(() => isLoading = false);
    }
  }

// Helper untuk notifikasi cepat
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}

class _LabelForm extends StatelessWidget {
  final String label;
  const _LabelForm({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500));
  }
}
