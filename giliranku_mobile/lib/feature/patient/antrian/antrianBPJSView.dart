import 'package:flutter/material.dart';
import 'package:giliranku/core/widgets/header.dart';

class AntrianBpjsView extends StatelessWidget {
  final Map<String, dynamic>? patientData;
  const AntrianBpjsView({super.key, this.patientData});

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
              title: 'Antrian BPJS',
            ),
            Expanded(
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
                          color: const Color(0xFFE0F7F4),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: const Icon(
                          Icons.engineering_rounded,
                          size: 48,
                          color: Color(0xFF0D9B86),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Fitur Dalam Tahapan Pengembangan',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Mohon maaf, layanan pendaftaran antrian BPJS saat ini masih dalam tahap pengembangan. Fitur ini akan segera tersedia dalam pembaruan mendatang.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
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
                            backgroundColor: const Color(0xFF0D9B86),
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
          ],
        ),
      ),
    );
  }
}