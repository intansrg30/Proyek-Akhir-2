import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:giliran_ku/core/datasources/apiException.dart';
import 'package:giliran_ku/feature/kiosk/consultation/consultationController.dart';
import 'package:giliran_ku/core/models/doctorModel.dart';
import 'package:giliran_ku/core/models/poliModel.dart';
import 'package:giliran_ku/feature/kiosk/ticketView.dart';

class ConsultationGeneralView extends StatefulWidget {
  const ConsultationGeneralView({super.key});

  @override
  State<ConsultationGeneralView> createState() =>
      _ConsultationGeneralViewState();
}

class _ConsultationGeneralViewState extends State<ConsultationGeneralView> {
  static const Color _primary = Color(0xFF17A889);
  static const Color _dark = Color(0xFF0A7D67);
  static const Color _darkText = Color(0xFF063D2C);
  static const Color _mutedText = Color(0xFF2E7A60);
  static const Color _iconBg = Color(0xFFD5F0E6);
  static const Color _cardBorder = Color(0xFFC3E8D8);

  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController(text: '08');
  final ConsultationController _controller = ConsultationController();

  bool _isPasienLama = false;
  bool _loading = false;
  bool _loadingLayanan = false;
  bool _loadingDoctors = false;
  String? _error;
  String? _nikError;
  String? _namaError;
  String? _teleponError;

  List<Poli> _polis = [];
  Poli? _selectedPoli;
  List<Doctor> _doctors = [];
  Doctor? _selectedDoctor;

  @override
  void initState() {
    super.initState();
    _loadPolis();
    _nikController.addListener(_validateNik);
    _namaController.addListener(_validateNama);
    _teleponController.addListener(_validateTelepon);
  }

  void _validateNik() {
    final nik = _nikController.text.trim();
    setState(() {
      if (nik.isEmpty) {
        _nikError = null;
      } else if (nik.length < 16) {
        _nikError = 'NIK harus 16 karakter';
      } else if (nik.length > 16) {
        _nikError = 'NIK maksimal 16 karakter';
      } else {
        _nikError = null;
      }
    });
  }

  void _validateNama() {
    final nama = _namaController.text.trim();
    setState(() {
      if (nama.isEmpty) {
        _namaError = null;
      } else if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(nama)) {
        _namaError = 'Nama hanya boleh berisi huruf';
      } else {
        _namaError = null;
      }
    });
  }

  void _validateTelepon() {
    final telepon = _teleponController.text.trim();
    setState(() {
      if (telepon.isEmpty) {
        _teleponError = null;
      } else if (!RegExp(r'^[0-9]*$').hasMatch(telepon)) {
        _teleponError = 'Nomor telepon hanya boleh berisi angka';
      } else {
        _teleponError = null;
      }
    });
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  Future<void> _loadPolis() async {
    setState(() {
      _loadingLayanan = true;
      _error = null;
      _polis = [];
      _selectedPoli = null;
      _doctors = [];
      _selectedDoctor = null;
    });
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final polis = await _controller.fetchPoliList(tanggal: today);
      if (!mounted) return;
      setState(() {
        _polis = polis;
        _loadingLayanan = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _readError(error);
        _loadingLayanan = false;
      });
    }
  }

  Future<void> _loadDoctors(Poli poli) async {
    setState(() {
      _loadingDoctors = true;
      _doctors = [];
      _selectedDoctor = null;
    });
    try {
      final date = DateTime.now().toIso8601String().split('T')[0];
      final doctors = await _controller.fetchDoctors(poli.id, date);
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        _loadingDoctors = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _submit() async {
    final nik = _nikController.text.trim();
    final nama = _namaController.text.trim();
    final telepon = _teleponController.text.trim();

    if (nik.isEmpty) {
      setState(() => _error = 'Masukkan NIK');
      return;
    }
    if (nik.length != 16) {
      setState(() => _error = 'NIK harus 16 karakter');
      return;
    }
    if (!RegExp(r'^[0-9]*$').hasMatch(nik)) {
      setState(() => _error = 'NIK hanya boleh berisi angka');
      return;
    }

    if (!_isPasienLama) {
      if (nama.isEmpty || telepon.isEmpty) {
        setState(() => _error = 'Nama Lengkap dan Nomor Telepon harus diisi');
        return;
      }
      if (!RegExp(r'^[a-zA-Z\s]*$').hasMatch(nama)) {
        setState(() => _error = 'Nama hanya boleh berisi huruf');
        return;
      }
      if (_namaError != null) {
        setState(() => _error = 'Periksa kembali data Nama');
        return;
      }
      if (!RegExp(r'^[0-9]*$').hasMatch(telepon)) {
        setState(() => _error = 'Nomor telepon hanya boleh berisi angka');
        return;
      }
      if (_teleponError != null) {
        setState(() => _error = 'Periksa kembali data Nomor Telepon');
        return;
      }
    }

    if (_nikError != null) {
      setState(() => _error = 'Periksa kembali data NIK');
      return;
    }
    if (_selectedPoli == null || _selectedDoctor == null) {
      setState(() => _error = 'Pilih poli dan dokter terlebih dahulu');
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
            const Text('Apakah data anda sudah sesuai?'),
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
              _processSubmit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: _dark, foregroundColor: Colors.white),
            child: const Text('Ya, Cetak Tiket'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubmit() async {
    final nik = _nikController.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ticket = await _controller.createTicketForGeneral(
        nik: nik,
        poli: _selectedPoli!,
        doctor: _selectedDoctor!,
        isPasienLama: _isPasienLama,
        namaPasien: _namaController.text.trim(),
        telepon: _teleponController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TicketView(ticket: ticket)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _readError(error));
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _readError(Object error) {
    if (error is ApiException) return error.message;
    return 'Terjadi kesalahan. Coba lagi.';
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: const Color(0xFFF5FBF8),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      counterText: '',
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      floatingLabelStyle: const TextStyle(color: _primary),
      hintStyle: const TextStyle(color: Colors.black54),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pasien Umum'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F5F0), Color(0xFFF0FAF6), Color(0xFFFAFFFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildToggle(),
            const SizedBox(height: 16),
            if (_error != null) ...[
              _buildErrorBanner(),
              const SizedBox(height: 12),
            ],
            _buildIdentitasCard(context),
            const SizedBox(height: 16),
            _buildLayananCard(context),
            const SizedBox(height: 24),
            _buildSubmitButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pasien Umum',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _darkText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Silakan lengkapi data pasien dan pilih poli tujuan.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: _mutedText),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          _toggleOption(
            label: 'Pasien Baru',
            selected: !_isPasienLama,
            onTap: () => setState(() => _isPasienLama = false),
          ),
          _toggleOption(
            label: 'Pasien Lama',
            selected: _isPasienLama,
            onTap: () => setState(() => _isPasienLama = true),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _dark : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? Colors.white : _mutedText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context,
      {required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _iconBg,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _dark, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _darkText,
              ),
        ),
      ],
    );
  }

  Widget _buildIdentitasCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context,
              icon: Icons.person_outline, title: 'Identitas Pasien'),
          const SizedBox(height: 16),
          if (_nikError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.red, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _nikError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          TextField(
            controller: _nikController,
            keyboardType: TextInputType.number,
            maxLength: 16,
            inputFormatters: [
              LengthLimitingTextInputFormatter(16),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: _inputDecoration(
              label: _isPasienLama ? 'NIK / No. Rekam Medis' : 'NIK',
              hint: 'Contoh: 1203010101010001',
              icon: Icons.badge_outlined,
            ),
          ),
          if (!_isPasienLama) ...[
            const SizedBox(height: 16),
            if (_namaError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _namaError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _namaController,
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[a-zA-Z\s]'),
                ),
              ],
              decoration: _inputDecoration(
                label: 'Nama Lengkap',
                hint: 'Masukkan nama pasien',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 12),
            if (_teleponError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _teleponError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            TextField(
              controller: _teleponController,
              keyboardType: TextInputType.phone,
              decoration: _inputDecoration(
                label: 'Nomor Telepon',
                hint: '08xxxxxxxxxx',
                icon: Icons.phone_outlined,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLayananCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context,
              icon: Icons.apartment_outlined, title: 'Pilih Layanan & Dokter'),
          const SizedBox(height: 16),
          if (_loadingLayanan)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: _primary),
              ),
            )
          else if (_polis.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tidak ada poliklinik tersedia hari ini.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<Poli>(
              value: _selectedPoli,
              decoration: _inputDecoration(
                label: 'Poliklinik',
                icon: Icons.apartment_outlined,
              ),
              items: _polis.map((p) {
                return DropdownMenuItem<Poli>(
                  value: p,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedPoli = val;
                  _selectedDoctor = null;
                });
                if (val != null) _loadDoctors(val);
              },
            ),
          const SizedBox(height: 12),
          if (_loadingDoctors)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(color: _primary),
              ),
            )
          else if (_selectedPoli != null && _doctors.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_outlined,
                      color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tidak ada dokter tersedia hari ini.',
                    style: TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<Doctor>(
              value: _selectedDoctor,
              decoration: _inputDecoration(
                label: 'Dokter',
                icon: Icons.medical_services_outlined,
              ),
              selectedItemBuilder: (BuildContext context) {
                return _doctors.map<Widget>((Doctor d) {
                  return Text(
                    d.name,
                    overflow: TextOverflow.ellipsis,
                  );
                }).toList();
              },
              items: _doctors.map((d) {
                return DropdownMenuItem<Doctor>(
                  value: d,
                  child: RichText(
                    text: TextSpan(
                      text: d.name,
                      style: const TextStyle(color: Colors.black87, fontSize: 15),
                      children: [
                        TextSpan(
                          text: ' (Sisa Kuota: ${d.kuota})',
                          style: TextStyle(
                            color: d.kuota > 0 ? const Color(0xFF17A889) : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDoctor = val),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _submit,
        icon: _loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.print_outlined, size: 20),
        label: Text(
          _loading ? 'Mencetak...' : 'Cetak Tiket Umum',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _dark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}