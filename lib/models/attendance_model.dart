class AttendanceModel {
  final String? id; // Tambahkan ini jika butuh referensi ID absen
  final String namaGuru;
  final String? nip; // Sesuai Resource kamu
  final String tanggal;
  final String jamMasuk;
  final String jamPulang;
  final String status;

  AttendanceModel({
    this.id,
    required this.namaGuru,
    this.nip,
    required this.tanggal,
    required this.jamMasuk,
    required this.jamPulang,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id']?.toString(),
      namaGuru: json['nama_guru'] ?? '-',
      nip: json['nip'] ?? '-',
      tanggal: json['tanggal'] ?? '-',
      jamMasuk: json['jam_masuk'] ?? '--:--',
      jamPulang: json['jam_pulang'] ?? '--:--',
      status: json['status'] ?? '-',
    );
  }
}