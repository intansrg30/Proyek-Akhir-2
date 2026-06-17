import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:giliranku/core/theme/theme.dart';

const double _hospitalLat = 2.4340809;
const double _hospitalLng = 99.156413;
final LatLng _hospitalLatLng = LatLng(_hospitalLat, _hospitalLng);

class LokasiRSView extends StatefulWidget {
  final String hospitalName;
  final String hospitalAddress;

  const LokasiRSView({
    super.key,
    required this.hospitalName,
    required this.hospitalAddress,
  });

  @override
  State<LokasiRSView> createState() => _LokasiRSViewState();
}

class _LokasiRSViewState extends State<LokasiRSView> {
  final MapController _mapController = MapController();

  Position? _userPosition;
  String _userAddress = 'Mengambil lokasi...';
  String _distanceText = '-';
  bool _locationLoading = true;
  bool _locationDenied = false;

  @override
  void initState() {
    super.initState();
    _requestLocationAndLoad();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationAndLoad() async {
    setState(() {
      _locationLoading = true;
      _locationDenied = false;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationDenied = true;
          _locationLoading = false;
        });
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _locationDenied = true;
            _locationLoading = false;
          });
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _locationDenied = true;
          _locationLoading = false;
        });
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    if (!mounted) return;
    _userPosition = position;

    final dist = _haversineDistance(
      position.latitude,
      position.longitude,
      _hospitalLat,
      _hospitalLng,
    );

    setState(() {
      _distanceText = '${dist.toStringAsFixed(1)} km';
      _locationLoading = false;
      _userAddress = 'Mengambil alamat...';
    });

    _fitBounds(position);

    final address = await _reverseGeocode(position.latitude, position.longitude);
    if (!mounted) return;
    setState(() => _userAddress = address);
  }

  double _haversineDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLng = _deg2rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _deg2rad(double deg) => deg * pi / 180;

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).toList();
        return parts.join(', ');
      }
    } catch (_) {}
    return 'Tidak dapat mengambil alamat';
  }

  void _fitBounds(Position userPosition) {
    final userLatLng = LatLng(userPosition.latitude, userPosition.longitude);

    final bounds = LatLngBounds(userLatLng, _hospitalLatLng);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  void _recenter() {
    final pos = _userPosition;
    if (pos == null) return;
    _mapController.move(
      LatLng(pos.latitude, pos.longitude),
      15,
    );
  }

  Future<void> _openDirections() async {
    final pos = _userPosition;
    Uri uri;

    if (pos != null) {
      uri = Uri.parse(
        'google.navigation:q=$_hospitalLat,$_hospitalLng&mode=d',
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=${pos.latitude},${pos.longitude}'
        '&destination=$_hospitalLat,$_hospitalLng'
        '&travelmode=driving',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$_hospitalLat,$_hospitalLng'
        '&travelmode=driving',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[
      Marker(
        point: _hospitalLatLng,
        width: 48,
        height: 48,
        child: Tooltip(
          message: widget.hospitalName,
          child: const Icon(
            Icons.local_hospital_rounded,
            color: AppColors.primary,
            size: 40,
            shadows: [Shadow(blurRadius: 6, color: Colors.black26)],
          ),
        ),
      ),
    ];

    final pos = _userPosition;
    if (pos != null) {
      markers.add(
        Marker(
          point: LatLng(pos.latitude, pos.longitude),
          width: 48,
          height: 48,
          child: const Tooltip(
            message: 'Lokasi Anda',
            child: Icon(
              Icons.person_pin_circle_rounded,
              color: Color(0xFF4C9BE8),
              size: 40,
              shadows: [Shadow(blurRadius: 6, color: Colors.black26)],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _hospitalLatLng,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.gliranku_mobile',
                      maxZoom: 19,
                    ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter',
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: _recenter,
                    child: const Icon(Icons.my_location,
                        color: AppColors.primary, size: 20),
                  ),
                ),

                if (_locationDenied)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'retry',
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: _requestLocationAndLoad,
                      child: const Icon(Icons.refresh,
                          color: Colors.orange, size: 20),
                    ),
                  ),
              ],
            ),
          ),

          _buildInfoPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Lokasi & Arah ke ${widget.hospitalName}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.local_hospital_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.hospitalName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.hospitalAddress,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              if (_locationLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Mengambil lokasi Anda...',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_locationDenied)
                _buildDeniedBanner()
              else
                _buildLocationStats(),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openDirections,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text(
                    'Petunjuk Arah',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatChip(
              Icons.social_distance_rounded,
              'Jarak ke RSUD Porsea',
              _distanceText,
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary,
            ),
            const SizedBox(width: 12),
            _buildStatChip(
              Icons.directions_car_rounded,
              'Estimasi Lama Perjalanan',
              _estimateDriveTime(),
              Colors.orange.withValues(alpha: 0.1),
              Colors.orange.shade700,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.person_pin_circle_rounded,
                size: 18, color: Color(0xFF4C9BE8)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lokasi Anda',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _userAddress,
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, String value, Color bgColor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: color.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeniedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded,
              color: Colors.orange.shade700, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Izin lokasi diperlukan untuk menghitung jarak. Ketuk tombol refresh di peta untuk mencoba lagi.',
              style: TextStyle(
                  fontSize: 12, color: Colors.orange.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _estimateDriveTime() {
    final pos = _userPosition;
    if (pos == null) return '-';
    final dist = _haversineDistance(
        pos.latitude, pos.longitude, _hospitalLat, _hospitalLng);
    final minutes = (dist / 40 * 60).round();
    if (minutes < 60) return '$minutes mnt';
    return '${(minutes / 60).floor()} jam ${minutes % 60} mnt';
  }
}