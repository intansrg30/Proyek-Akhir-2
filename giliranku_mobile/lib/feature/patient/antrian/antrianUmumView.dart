import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giliranku/core/datasources/apiDataSource.dart';
import 'package:giliranku/core/widgets/header.dart';
import 'package:giliranku/feature/patient/antrian/karcisView.dart';

class JenisLayanan {
  final int id;
  final String nama;
  const JenisLayanan({required this.id, required this.nama});

  factory JenisLayanan.fromJson(Map<String, dynamic> j) => JenisLayanan(
        id: (j['id'] ?? j['poly_id'] ?? 0) is int
            ? (j['id'] ?? j['poly_id'] ?? 0)
            : int.tryParse('${j['id'] ?? j['poly_id'] ?? 0}') ?? 0,
        nama: j['nama'] ?? j['poly_name'] ?? '',
      );
}

class Dokter {
  final int id;
  final String nama;
  final int kuotaNonJKN;
  const Dokter({required this.id, required this.nama, this.kuotaNonJKN = 0});

  factory Dokter.fromJson(Map<String, dynamic> j) => Dokter(
        id: (j['doctor_id'] ?? j['id'] ?? 0) is int
            ? (j['doctor_id'] ?? j['id'] ?? 0)
            : int.tryParse('${j['doctor_id'] ?? j['id'] ?? 0}') ?? 0,
        nama: j['doctor_name'] ?? j['nama'] ?? '',
        kuotaNonJKN: (j['kuota_non_jkn'] ?? 0) is int
            ? (j['kuota_non_jkn'] ?? 0)
            : int.tryParse('${j['kuota_non_jkn'] ?? 0}') ?? 0,
      );
}

class AntrianResult {
  final String noAntrian;
  final String noAntrianPoli;
  final String kodeBooking;
  final String poliklinik;
  final String dokter;
  final String tanggal;
  final String waktu;
  final String pembayaran;
  final String source;
  final String noRm;
  final String namaPasien;

  const AntrianResult({
    required this.noAntrian,
    required this.noAntrianPoli,
    required this.kodeBooking,
    required this.poliklinik,
    required this.dokter,
    required this.tanggal,
    required this.waktu,
    required this.pembayaran,
    required this.source,
    required this.noRm,
    required this.namaPasien,
  });

  factory AntrianResult.fromJson(Map<String, dynamic> j) => AntrianResult(
        noAntrian: j['no_antrian'] ?? '106',
        noAntrianPoli: j['no_antrian_poli'] ?? 'A-001',
        kodeBooking: j['kode_booking'] ?? '',
        poliklinik: j['poliklinik'] ?? '-',
        dokter: j['dokter'] ?? 'dr. -',
        tanggal: j['tanggal'] ?? '-',
        waktu: j['waktu'] ?? '-',
        pembayaran: j['pembayaran'] ?? 'Umum',
        source: j['source'] ?? 'smartphone',
        noRm: j['no_rm'] ?? '-',
        namaPasien: j['nama_pasien'] ?? '-',
      );
}

class AntrianView extends StatefulWidget {
  final Map<String, dynamic>? patientData;
  const AntrianView({super.key, this.patientData});

  @override
  State<AntrianView> createState() => _AntrianViewState();
}

class _AntrianViewState extends State<AntrianView>
    with TickerProviderStateMixin {
  final _api = ApiDataSource();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  bool _isLoadingLayanan = false;
  bool _isLoadingDokter = false;
  bool _isPasienLama = false;

  List<JenisLayanan> _layananList = [];
  List<Dokter> _dokterList = [];
  int? _selectedPoliID;
  String _selectedPoliNama = '';
  int? _selectedDokterID;
  String _selectedDokterNama = '';

  final _nikCtrl      = TextEditingController();
  final _namaCtrl     = TextEditingController();
  final _teleponCtrl  = TextEditingController(text: '+62');
  final _tanggalCtrl  = TextEditingController();

  String? _nikError;
  String? _namaError;
  String? _tanggalError;

  bool get _isLoggedIn =>
      widget.patientData != null &&
      widget.patientData!.containsKey('nik');

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    if (_isLoggedIn) {
      _nikCtrl.text  = widget.patientData!['nik'] ?? '';
      _namaCtrl.text = widget.patientData!['patient_name'] ?? '';
      final phone = widget.patientData!['phone'] as String?;
      if (phone != null && phone.isNotEmpty) {
        _teleponCtrl.text = phone;
      }
    }

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nikCtrl.dispose();
    _namaCtrl.dispose();
    _teleponCtrl.dispose();
    _tanggalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLayanan(String tanggal) async {
    setState(() {
      _isLoadingLayanan = true;
      _selectedPoliID = null;
      _selectedPoliNama = '';
      _selectedDokterID = null;
      _selectedDokterNama = '';
      _dokterList = [];
      _layananList = [];
    });
    try {
      final list = await _api.fetchAvailableLayanan(tanggal);
      if (!mounted) return;
      setState(() {
        _layananList = list.map((e) => JenisLayanan.fromJson(e)).toList();
        _isLoadingLayanan = false;
      });
    } catch (e) {
      setState(() => _isLoadingLayanan = false);
      _showSnack('Gagal memuat layanan: $e');
    }
  }

  Future<void> _onRefresh() async {
    if (_tanggalCtrl.text.isNotEmpty) {
      await _loadLayanan(_tanggalCtrl.text);
    }
  }

  Future<void> _loadDokter(int poliId, String tanggal) async {
    setState(() {
      _isLoadingDokter = true;
      _selectedDokterID = null;
      _selectedDokterNama = '';
      _dokterList = [];
    });
    try {
      final list = await _api.getDokterByPoli(
        poliId,
        tanggal.isNotEmpty ? tanggal : null,
      );
      if (!mounted) return;
      setState(() {
        _dokterList = list.map((e) => Dokter.fromJson(e)).toList();
        _isLoadingDokter = false;
      });
    } catch (e) {
      setState(() => _isLoadingDokter = false);
      _showSnack('Gagal memuat dokter: $e');
    }
  }

  Future<void> _daftarAntrian() async {
    setState(() {
      _nikError     = null;
      _namaError    = null;
      _tanggalError = null;
    });

    bool valid = true;
    if (_nikCtrl.text.trim().length < (_isPasienLama ? 4 : 10)) {
      setState(() => _nikError = 'NIK/No. RM tidak valid');
      valid = false;
    }
    if (!_isPasienLama && _namaCtrl.text.trim().isEmpty) {
      setState(() => _namaError = 'Nama tidak boleh kosong');
      valid = false;
    }
    if (!_isPasienLama) {
      final phone = _teleponCtrl.text.trim();
      if (phone == '+62' || phone.isEmpty || phone.length < 8) {
        _showSnack('Silakan masukkan nomor telepon yang valid');
        valid = false;
      }
    }
    if (_tanggalCtrl.text.trim().isEmpty) {
      setState(() => _tanggalError = 'Pilih tanggal kunjungan');
      valid = false;
    }
    if (_selectedPoliID == null) {
      _showSnack('Pilih poliklinik terlebih dahulu');
      return;
    }
    if (!_isLoadingDokter && _dokterList.isEmpty) {
      _showSnack('Tidak ada dokter tersedia untuk poli ini');
      return;
    }
    if (_selectedDokterID == null) {
      _showSnack('Pilih dokter terlebih dahulu');
      return;
    }
    if (!valid) return;

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pendaftaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Apakah data Anda sudah sesuai?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Kembali'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _processDaftarAntrian();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9B86), foregroundColor: Colors.white),
            child: const Text('Ya, Lanjutkan Pendaftaran'),
          ),
        ],
      ),
    );
  }

  Future<void> _processDaftarAntrian() async {
    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final res = await _api.createAntrian({
        'nik'             : _nikCtrl.text.trim(),
        'nama_pasien'     : _isPasienLama ? '-' : _namaCtrl.text.trim(),
        'telepon'         : _isPasienLama ? '-' : _teleponCtrl.text.trim(),
        'tanggal'         : _tanggalCtrl.text.trim(),
        'poli_id'         : _selectedPoliID,
        'dokter_id'       : _selectedDokterID,
        'poliklinik_nama' : _selectedPoliNama,
        'dokter_nama'     : _selectedDokterNama,
        'is_pasien_lama'  : _isPasienLama,
      });

      final data   = res['data'] as Map<String, dynamic>? ?? {};
      final result = AntrianResult.fromJson(data);

      if (mounted) {
        setState(() => _isLoading = false);
        _goToKarcis(result);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack('Gagal mendaftar: $e');
    }
  }

  void _goToKarcis(AntrianResult result) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, a, __) => KarcisView(result: result),
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
  }

  Future<void> _pilihTanggal() async {
    final now   = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      selectableDayPredicate: (day) => day.weekday != DateTime.sunday,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0D9B86),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final tanggalStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        _tanggalCtrl.text = tanggalStr;
        _tanggalError = null;
      });
      _loadLayanan(tanggalStr);
    }
  }

  void _showSnack(String msg, {bool isError = true}) {
    msg = msg.replaceAll('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF0D9B86),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            AppHeader(
              mode: HeaderMode.page,
              title: 'Antrian Umum RSUD Porsea',
            ),
            Expanded(
              child: FadeTransition(
                      opacity: _fadeAnim,
                      child: RefreshIndicator(
                        onRefresh: _onRefresh,
                        color: const Color(0xFF0D9B86),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                _buildFormCard(),
                                const SizedBox(height: 28),
                                _buildDaftarButton(),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildFormCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Status Pasien'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPasienLama = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isPasienLama ? const Color(0xFFE0F2F1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: !_isPasienLama ? Border.all(color: const Color(0xFF25A699)) : Border.all(color: Colors.transparent),
                    ),
                    child: Center(
                      child: Text('Pasien Baru',
                          style: TextStyle(
                            fontWeight: !_isPasienLama ? FontWeight.bold : FontWeight.normal,
                            color: !_isPasienLama ? const Color(0xFF25A699) : Colors.grey,
                          )),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isPasienLama = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isPasienLama ? const Color(0xFFE0F2F1) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: _isPasienLama ? Border.all(color: const Color(0xFF25A699)) : Border.all(color: Colors.transparent),
                    ),
                    child: Center(
                      child: Text('Pasien Lama',
                          style: TextStyle(
                            fontWeight: _isPasienLama ? FontWeight.bold : FontWeight.normal,
                            color: _isPasienLama ? const Color(0xFF25A699) : Colors.grey,
                          )),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _label('Data Pasien'),
          const SizedBox(height: 16),

          _field(
            ctrl: _nikCtrl,
            label: _isPasienLama ? 'NIK / No. Rekam Medis' : 'NIK',
            hint: _isPasienLama ? 'Masukkan NIK atau No. RM' : 'Masukkan NIK (16 digit)',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 16,
            errorText: _nikError,
          ),
          const SizedBox(height: 16),

          if (!_isPasienLama) ...[
            _field(
              ctrl: _namaCtrl,
              label: 'Nama Lengkap',
              hint: 'Masukkan nama lengkap',
              icon: Icons.person_outline_rounded,
              errorText: _namaError,
            ),
            const SizedBox(height: 16),

            _field(
              ctrl: _teleponCtrl,
              label: 'Nomor Telepon',
              hint: '+62',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
          ],

          _fieldTanggal(),
          const SizedBox(height: 20),

          _label('Pilihan Poliklinik'),
          const SizedBox(height: 4),
          _buildDropdownPoli(),
          const SizedBox(height: 16),

          _label('Pilih Dokter'),
          const SizedBox(height: 12),
          _buildDropdownDokter(),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
          letterSpacing: 0.3));

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? errorText,
    bool readOnly = false,
    List<TextInputFormatter>? formatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: formatters,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly
                ? const Color(0xFF6B7280)
                : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFFBFC5CF), fontSize: 14),
            prefixIcon:
                Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            suffixIcon: readOnly
                ? const Icon(Icons.lock_outline_rounded,
                    color: Color(0xFFD1D5DB), size: 16)
                : null,
            counterText: '',
            errorText: errorText,
            filled: true,
            fillColor: readOnly
                ? const Color(0xFFF3F4F6)
                : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: readOnly
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFFE5E7EB),
                    width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF0D9B86), width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFEF4444), width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _fieldTanggal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Kunjungan',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pilihTanggal,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _tanggalError != null
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: Color(0xFF9CA3AF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _tanggalCtrl.text.isEmpty
                        ? 'Pilih tanggal kunjungan'
                        : _tanggalCtrl.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: _tanggalCtrl.text.isEmpty
                          ? const Color(0xFFBFC5CF)
                          : const Color(0xFF111827),
                      fontWeight: _tanggalCtrl.text.isEmpty
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
        if (_tanggalError != null) ...[
          const SizedBox(height: 6),
          Text(_tanggalError!,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFEF4444))),
        ],
      ],
    );
  }

  Widget _buildDropdownPoli() {
    if (_tanggalCtrl.text.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                color: Color(0xFFD1D5DB), size: 20),
            SizedBox(width: 12),
            Text('Pilih tanggal kunjungan terlebih dahulu',
                style: TextStyle(
                    color: Color(0xFFBFC5CF), fontSize: 14)),
          ],
        ),
      );
    }

    if (_isLoadingLayanan) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF0D9B86)),
            ),
            SizedBox(width: 12),
            Text('Memuat data poliklinik...',
                style: TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14)),
          ],
        ),
      );
    }

    if (_layananList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD97706), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada poliklinik tersedia pada tanggal ini.',
                style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedPoliID == null
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF0D9B86),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedPoliID,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text('Pilih poliklinik',
                style:
                    TextStyle(color: Color(0xFFBFC5CF), fontSize: 14)),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9CA3AF)),
          ),
          borderRadius: BorderRadius.circular(12),
          items: _layananList
              .map((l) => DropdownMenuItem<int>(
                    value: l.id,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(l.nama,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827))),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedPoliID = v;
              _selectedPoliNama = _layananList
                  .firstWhere((l) => l.id == v,
                      orElse: () =>
                          const JenisLayanan(id: 0, nama: 'Poli Umum'))
                  .nama;
            });
            if (v != null) _loadDokter(v, _tanggalCtrl.text);
          },
        ),
      ),
    );
  }

  Widget _buildDropdownDokter() {
    if (_selectedPoliID == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_search_outlined,
                color: Color(0xFFD1D5DB), size: 20),
            SizedBox(width: 12),
            Text('Pilih poliklinik terlebih dahulu',
                style: TextStyle(
                    color: Color(0xFFBFC5CF), fontSize: 14)),
          ],
        ),
      );
    }

    if (_isLoadingDokter) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFF0D9B86)),
            ),
            SizedBox(width: 12),
            Text('Memuat data dokter...',
                style: TextStyle(
                    color: Color(0xFF9CA3AF), fontSize: 14)),
          ],
        ),
      );
    }

    if (_dokterList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_off_outlined,
                color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada dokter tersedia untuk poli ini.',
                style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDokterID == null
              ? const Color(0xFFE5E7EB)
              : const Color(0xFF0D9B86),
          width: 1.5,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedDokterID,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text('Pilih dokter',
                style:
                    TextStyle(color: Color(0xFFBFC5CF), fontSize: 14)),
          ),
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF9CA3AF)),
          ),
          borderRadius: BorderRadius.circular(12),
          items: _dokterList
              .map((d) => DropdownMenuItem<int>(
                    value: d.id,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(d.nama,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF111827))),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: d.kuotaNonJKN > 0
                                  ? const Color(0xFFD1FAE5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Kuota: ${d.kuotaNonJKN}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: d.kuotaNonJKN > 0
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedDokterID = v;
              _selectedDokterNama = _dokterList
                  .firstWhere((d) => d.id == v,
                      orElse: () => const Dokter(id: 0, nama: '-'))
                  .nama;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDaftarButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _daftarAntrian,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9B86),
          disabledBackgroundColor:
              const Color(0xFF0D9B86).withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Daftar Sekarang',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 60,
            decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}