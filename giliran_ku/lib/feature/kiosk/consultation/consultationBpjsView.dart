import 'package:flutter/material.dart';

class ConsultationBpjsView extends StatelessWidget {
  const ConsultationBpjsView({super.key});

  static const Color _dark = Color(0xFF0A7D67);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF6),
      appBar: AppBar(
        backgroundColor: _dark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pasien BPJS'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE6F5F0), Color(0xFFF0FAF6), Color(0xFFFAFFFE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5F0E6),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.engineering_rounded,
                    size: 48,
                    color: Color(0xFF0A7D67),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Fitur Dalam Tahapan Pengembangan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF063D2C),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mohon maaf, layanan pendaftaran antrian BPJS saat ini masih dalam tahap pengembangan. Fitur ini akan segera tersedia dalam pembaruan mendatang.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF2E7A60),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text(
                      'Kembali',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}