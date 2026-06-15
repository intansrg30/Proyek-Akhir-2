import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:giliranku/feature/patient/home/homeView.dart';
import 'package:giliranku/core/repositories/pasienRepository.dart';
import 'package:giliranku/core/services/sessionService.dart';
import 'package:giliranku/core/datasources/apiDataSource.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _nikCtrl = TextEditingController();
  final _namaCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _teleponCtrl = TextEditingController();

  final _nikFocus = FocusNode();
  final _namaFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _teleponFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  final _pasienRepo = PasienRepository();
  final _sessionService = SessionService();

  Future<void> _daftar() async {
    final nik = _nikCtrl.text.trim();
    final nama = _namaCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final telepon = _teleponCtrl.text.trim();

    if (nik.isEmpty || nama.isEmpty || username.isEmpty || password.isEmpty) {
      _showError('Semua kolom wajib harus diisi');
      return;
    }
    if (nik.length != 16) {
      _showError('NIK harus 16 digit');
      return;
    }
    if (username.length < 4) {
      _showError('Username minimal 4 karakter');
      return;
    }
    if (password.length < 6) {
      _showError('Password minimal 6 karakter');
      return;
    }

    setState(() => _isLoading = true);
    final patient = await _pasienRepo.register({
      'nik': nik,
      'patient_name': nama,
      'username': username,
      'password': password,
      'phone': telepon,
    });
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (patient == null) {
      _showError('Tidak dapat terhubung ke server.');
      return;
    }
    if (patient.nik.isEmpty) {
      _showError(patient.phone ?? 'Registrasi gagal');
      return;
    }

    final token = ApiDataSource().authToken;
    await _sessionService.savePatient(patient, token: token);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registrasi berhasil!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeView(patientData: patient.toMap())),
      (route) => false,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _nikCtrl.dispose();
    _namaCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _teleponCtrl.dispose();
    _nikFocus.dispose();
    _namaFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _teleponFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF25A699),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -15),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Daftar Akun",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          "Buat akun baru untuk melanjutkan",
                          style: TextStyle(color: Colors.grey),
                        ),

                        const SizedBox(height: 20),

                        _buildInput(
                          controller: _nikCtrl,
                          focusNode: _nikFocus,
                          nextFocus: _namaFocus,
                          hint: 'NIK (16 digit)',
                          icon: Icons.credit_card,
                          keyboardType: TextInputType.number,
                          maxLength: 16,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                        ),

                        const SizedBox(height: 12),

                        _buildInput(
                          controller: _namaCtrl,
                          focusNode: _namaFocus,
                          nextFocus: _usernameFocus,
                          hint: 'Nama Lengkap',
                          icon: Icons.badge_outlined,
                        ),

                        const SizedBox(height: 12),

                        _buildInput(
                          controller: _usernameCtrl,
                          focusNode: _usernameFocus,
                          nextFocus: _passwordFocus,
                          hint: 'Username (min. 4 karakter)',
                          icon: Icons.person,
                        ),

                        const SizedBox(height: 12),

                        _buildPasswordInput(),

                        const SizedBox(height: 12),

                        _buildInput(
                          controller: _teleponCtrl,
                          focusNode: _teleponFocus,
                          hint: 'No. Telepon (opsional)',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25A699),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: _isLoading ? null : _daftar,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Daftar",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                text: "Sudah punya akun? ",
                                style: TextStyle(color: Colors.grey),
                                children: [
                                  TextSpan(
                                    text: "Masuk",
                                    style: TextStyle(
                                      color: Color(0xFF25A699),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textInputAction:
          nextFocus != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocus != null) {
          FocusScope.of(context).requestFocus(nextFocus);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      style: const TextStyle(color: Colors.black),
      cursorColor: const Color(0xFF25A699),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF25A699)),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordCtrl,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) => FocusScope.of(context).requestFocus(_teleponFocus),
      style: const TextStyle(color: Colors.black),
      cursorColor: const Color(0xFF25A699),
      decoration: InputDecoration(
        hintText: 'Password (min. 6 karakter)',
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.lock, color: Color(0xFF25A699)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
