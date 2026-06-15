import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giliranku/core/datasources/apiDataSource.dart';
import 'package:giliranku/core/widgets/header.dart';
import 'package:giliranku/feature/patient/antrian/antrianUmumView.dart';
import 'package:giliranku/feature/patient/antrian/karcisView.dart';

class AntrianBpjsView extends StatefulWidget {
  final Map<String, dynamic>? patientData;
  const AntrianBpjsView({super.key, this.patientData});

  @override
  State<AntrianBpjsView> createState() => _AntrianBpjsViewState();
}

class _AntrianBpjsViewState extends State<AntrianBpjsView>
    with SingleTickerProviderStateMixin {
  final _api = ApiDataSource();

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;

  final _nikCtrl = TextEditingController();

  List<Map<String, dynamic>> _rujukanList = [];
  Map<String, dynamic>? _selectedRujukan;
  bool _isLoadingRujukan = false;

  List<Dokter> _dokterList = [];
  bool _isLoadingDokter = false;
  int? _selectedDokterID;
  String _selectedDokterNama = '';

  String? _nikError;

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
      _nikCtrl.text = widget.patientData!['nik'] ?? '';
    }

    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nikCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_nikCtrl.text.trim().length >= 10) {
      await _cariRujukan();
    } else {
      setState(() {
        _rujukanList = [];
        _selectedRujukan = null;
        _dokterList = [];
        _selectedDokterID = null;
      });
    }
  }

  Future<void> _cariRujukan() async {
    setState(() => _nikError = null);
    if (_nikCtrl.text.trim().length < 10) {
      setState(() => _nikError = 'NIK tidak valid');
      return;
    }
    setState(() => _isLoadingRujukan = true);
    final list = await _api.fetchRujukanBpjs(_nikCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _rujukanList = list;
      _selectedRujukan = null;
      _dokterList = [];
      _selectedDokterID = null;
      _isLoadingRujukan = false;
    });
    if (list.isEmpty) {
      _showSnack('Rujukan tidak ditemukan untuk NIK ini.');
    }
  }

  Future<void> _loadDokter(int poliId) async {
    setState(() {
      _isLoadingDokter = true;
      _selectedDokterID = null;
      _selectedDokterNama = '';
      _dokterList = [];
    });
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      final list = await _api.getDokterByPoli(poliId, date);
      if (!mounted) return;
      setState(() {
        _dokterList = list.map((e) => Dokter.fromJson(e)).toList();
        if (_dokterList.isNotEmpty) {
          _selectedDokterID = _dokterList.first.id;
          _selectedDokterNama = _dokterList.first.nama;
        }
        _isLoadingDokter = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoadingDokter = false);
    }
  }

  Future<void> _daftarAntrian() async {
    setState(() => _nikError = null);

    if (_selectedRujukan == null) {
      _showSnack('Pilih rujukan terlebih dahulu');
      return;
    }
    if (!_isLoadingDokter && _dokterList.isEmpty) {
      _showSnack('Tidak ada dokter yang tersedia untuk rujukan anda');
      return;
    }
    if (_selectedDokterID == null) {
      _showSnack('Pilih dokter terlebih dahulu');
      return;
    }

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
        'nik'        : _nikCtrl.text.trim(),
        'no_rujukan' : _selectedRujukan!['no_rujukan'],
        'tipe'       : 'bpjs',
        'dokter_id'  : _selectedDokterID,
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
          ).animate(
              CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      transitionDuration: const Duration(milliseconds: 400),
    ));
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
              title: 'Antrian BPJS RSUD Porsea',
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
                          _buildInfoBpjs(),
                          const SizedBox(height: 16),
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

  Widget _buildInfoBpjs() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            width: 1.5),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFF3B82F6), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pastikan Anda sudah mendaftar rujukan dari Faskes tingkat 1 (Puskesmas/Klinik) sebelum mendaftar.',
              style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1E40AF),
                  fontWeight: FontWeight.w500,
                  height: 1.5),
            ),
          ),
        ],
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
          _label('Data Kepesertaan BPJS'),
          const SizedBox(height: 16),
          _field(
            ctrl: _nikCtrl,
            label: 'NIK / No. BPJS',
            hint: 'Masukkan NIK atau No. BPJS',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
            maxLength: 16,
            errorText: _nikError,
            formatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoadingRujukan ? null : _cariRujukan,
              icon: _isLoadingRujukan 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search, size: 18),
              label: const Text('Cari Rujukan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_rujukanList.isNotEmpty) ...[
            const SizedBox(height: 24),
            _label('Pilih Rujukan'),
            const SizedBox(height: 12),
            ..._rujukanList.map((ruj) => _buildRujukanCard(ruj)),
          ],
        ],
      ),
    );
  }

  Widget _buildRujukanCard(Map<String, dynamic> ruj) {
    final isSelected = _selectedRujukan == ruj;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRujukan = ruj;
        });
        _loadDokter(ruj['poli_id']);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0FAF6) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF0D9B86) : const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ruj['no_rujukan'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9B86))),
                if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF0D9B86), size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text('Poli: ${ruj['poli_nama']}', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
            if (isSelected) ...[
              const SizedBox(height: 4),
              if (_isLoadingDokter)
                const Text('Dokter: Memuat...', style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)))
              else if (_dokterList.isNotEmpty)
                Text('Dokter: ${_dokterList.first.nama}', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))
              else
                const Text('Dokter: Tidak tersedia', style: TextStyle(fontSize: 13, color: Colors.red)),
            ],
            const SizedBox(height: 4),
            Text('Faskes Asal: ${ruj['asal_faskes']}', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
            const SizedBox(height: 4),
            Text('Diagnosa: ${ruj['diagnosa']}', style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownDokter() {
    if (_isLoadingDokter) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9B86)),
          ),
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
            Icon(Icons.person_off_outlined, color: Color(0xFFEF4444), size: 20),
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

    return DropdownButtonFormField<int>(
      value: _selectedDokterID,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9B86), width: 2)),
      ),
      hint: const Text('Pilih Dokter', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
      isExpanded: true,
      items: _dokterList.map((d) {
        return DropdownMenuItem<int>(
          value: d.id,
          child: Text(d.nama, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedDokterID = val;
            _selectedDokterNama = _dokterList.firstWhere((e) => e.id == val).nama;
          });
        }
      },
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
                borderSide: const BorderSide(
                    color: Color(0xFFE5E7EB), width: 1.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF0D9B86), width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFFEF4444), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ],
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
}