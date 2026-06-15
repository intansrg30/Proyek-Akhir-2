import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:giliranku/core/constants/apiConstants.dart';
import 'package:giliranku/core/models/pasienModel.dart';
import 'package:giliranku/core/models/kontrolRutinModel.dart';
import 'package:giliranku/core/models/notifikasiModel.dart';

class ApiDataSource {
  static final ApiDataSource _instance = ApiDataSource._internal();
  factory ApiDataSource() => _instance;
  ApiDataSource._internal();

  final http.Client _client = http.Client();
  final Duration _timeout = ApiConstants.timeout;
  String? authToken;

  Uri _uri(String endpoint) {
    String base;
    if (endpoint.startsWith('/antrian') || endpoint.startsWith('/kiosk') || endpoint.startsWith('/tickets')) {
      base = ApiConstants.antrianBaseUrl;
    } else if (endpoint.startsWith('/pasien') || endpoint.startsWith('/notifikasi') || endpoint.startsWith('/kontrol-rutin')) {
      base = ApiConstants.pasienBaseUrl;
    } else if (endpoint.startsWith('/poliklinik') || endpoint.startsWith('/dokter') || endpoint.startsWith('/informasi')) {
      base = ApiConstants.masterBaseUrl;
    } else {
      base = ApiConstants.masterBaseUrl;
    }
    return Uri.parse('$base$endpoint');
  }
  
  Map<String, String> get _jsonHeaders {
    final headers = {'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  void setToken(String? token) {
    authToken = token;
  }

  Future<PasienModel?> loginPasien(String username, String password) async {
    try {
      final res = await _client
          .post(
            _uri(ApiConstants.pasienLogin),
            headers: _jsonHeaders,
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final data = body['data'] as Map<String, dynamic>;
        if (data['token'] != null) {
          setToken(data['token'] as String);
          return PasienModel.fromJson(data['patient'] as Map<String, dynamic>);
        } else {
          return PasienModel.fromJson(data);
        }
      }
      return PasienModel(
        nik: '',
        name: '',
        phone: body['message'] as String? ?? 'Login gagal',
      );
    } catch (e) {
      debugPrint('ApiDataSource.loginPasien: $e');
      return null;
    }
  }

  Future<PasienModel?> registerPasien(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .post(
            _uri(ApiConstants.pasienRegister),
            headers: _jsonHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        final resData = body['data'] as Map<String, dynamic>;
        if (resData['token'] != null) {
          setToken(resData['token'] as String);
          return PasienModel.fromJson(resData['patient'] as Map<String, dynamic>);
        }
        return PasienModel.fromJson(resData);
      }
      return PasienModel(
        nik: '',
        name: '',
        phone: body['message'] as String? ?? 'Registrasi gagal',
      );
    } catch (e) {
      debugPrint('ApiDataSource.registerPasien: $e');
      return null;
    }
  }

  Future<PasienModel?> getProfile(String nik) async {
    try {
      final res = await _client
          .get(_uri('${ApiConstants.pasienProfile}/$nik'), headers: _jsonHeaders)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return PasienModel.fromJson(
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('ApiDataSource.getProfile: $e');
    }
    return null;
  }

  Future<PasienModel?> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .put(
            _uri(ApiConstants.pasienProfile),
            headers: _jsonHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return PasienModel.fromJson(
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('ApiDataSource.updateProfile: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getInformasi() async {
    try {
      final res = await _client.get(_uri(ApiConstants.informasi)).timeout(_timeout);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiDataSource.getInformasi: $e');
    }
    return null;
  }

  Future<bool> updateInformasi(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .put(
            _uri(ApiConstants.informasi),
            headers: _jsonHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.updateInformasi: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchPoliklinik() async {
    try {
      final res = await _client.get(_uri(ApiConstants.poliklinik)).timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to fetch poliklinik');
    } catch (e) {
      debugPrint('ApiDataSource.fetchPoliklinik: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchRujukanBpjs(String nik) async {
    try {
      final res = await _client
          .get(_uri('/antrian/bpjs/rujukan/$nik'), headers: _jsonHeaders)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiDataSource.fetchRujukanBpjs: $e');
    }
    return [];
  }

  Future<bool> createPoli(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .post(_uri(ApiConstants.poliklinik), headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_timeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiDataSource.createPoli: $e');
      return false;
    }
  }

  Future<bool> updatePoli(int id, Map<String, dynamic> data) async {
    try {
      final res = await _client
          .put(_uri('${ApiConstants.poliklinik}/$id'), headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.updatePoli: $e');
      return false;
    }
  }

  Future<bool> deletePoli(int id) async {
    try {
      final res = await _client.delete(_uri('${ApiConstants.poliklinik}/$id')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.deletePoli: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchDokterByPoly(int? polyId, [String? tanggal]) async {
    try {
      var url = ApiConstants.dokter;
      if (polyId != null) {
        url += '?poly_id=$polyId';
        if (tanggal != null) {
          url += '&tanggal=$tanggal';
        }
      } else if (tanggal != null) {
        url += '?tanggal=$tanggal';
      }
      final res = await _client.get(_uri(url)).timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to fetch dokter');
    } catch (e) {
      debugPrint('ApiDataSource.fetchDokter: $e');
      rethrow;
    }
  }

  Future<bool> createDokter(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .post(_uri(ApiConstants.dokter), headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_timeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiDataSource.createDokter: $e');
      return false;
    }
  }

  Future<bool> updateDokter(int id, Map<String, dynamic> data) async {
    try {
      final res = await _client
          .put(_uri('${ApiConstants.dokter}/$id'), headers: _jsonHeaders, body: jsonEncode(data))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.updateDokter: $e');
      return false;
    }
  }

  Future<bool> deleteDokter(int id) async {
    try {
      final res = await _client.delete(_uri('${ApiConstants.dokter}/$id')).timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.deleteDokter: $e');
      return false;
    }
  }

  Future<List<KontrolRutinModel>> fetchAllKontrolRutin() async {
    try {
      final res = await _client
          .get(_uri(ApiConstants.kontrolRutinAll))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data']
                    as List<dynamic>? ??
                [])
            .map((e) => KontrolRutinModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiDataSource.fetchAllKontrolRutin: $e');
    }
    return [];
  }

  Future<List<KontrolRutinModel>> fetchKontrolRutinByNik(String nik) async {
    try {
      final res = await _client
          .get(_uri('${ApiConstants.kontrolRutinByNik}/$nik'), headers: _jsonHeaders)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data']
                    as List<dynamic>? ??
                [])
            .map((e) => KontrolRutinModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiDataSource.fetchKontrolRutinByNik: $e');
    }
    return [];
  }

  Future<KontrolRutinModel?> createKontrolRutin({
    required String nik,
    required DateTime controlDate,
    String? notes,
  }) async {
    try {
      final res = await _client
          .post(
            _uri(ApiConstants.kontrolRutin),
            headers: _jsonHeaders,
            body: jsonEncode({
              'nik': nik,
              'control_date': controlDate.toUtc().toIso8601String(),
              'notes': notes ?? '',
            }),
          )
          .timeout(_timeout);
      if (res.statusCode == 201) {
        return KontrolRutinModel.fromJson(
          (jsonDecode(res.body) as Map<String, dynamic>)['data']
              as Map<String, dynamic>,
        );
      }
      debugPrint('createKontrolRutin failed (${res.statusCode}): ${res.body}');
    } catch (e) {
      debugPrint('ApiDataSource.createKontrolRutin: $e');
    }
    return null;
  }

  Future<bool> deleteKontrolRutin(int id) async {
    try {
      final res = await _client
          .delete(_uri('${ApiConstants.kontrolRutin}/$id'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.deleteKontrolRutin: $e');
    }
    return false;
  }

  Future<List<NotifikasiModel>> fetchNotifikasiByNik(String nik) async {
    try {
      final res = await _client
          .get(_uri('${ApiConstants.notifikasiByNik}/$nik'), headers: _jsonHeaders)
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data']
                    as List<dynamic>? ??
                [])
            .map((e) => NotifikasiModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('ApiDataSource.fetchNotifikasiByNik: $e');
    }
    return [];
  }

  Future<bool> deleteNotifikasi(int id) async {
    try {
      final res = await _client
          .delete(_uri('${ApiConstants.notifikasi}/$id'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.deleteNotifikasi: $e');
    }
    return false;
  }

  Future<bool> nikExists(String nik) async {
    try {
      final res = await _client
          .get(_uri('${ApiConstants.pasienProfile}/$nik'), headers: _jsonHeaders)
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.nikExists: $e');
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getJenisLayanan() async {
    try {
      final res = await _client
          .get(_uri('/antrian/layanan'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data']
                    as List<dynamic>? ??
                [])
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiDataSource.getJenisLayanan: $e');
    }
    return [
      {'id': 1, 'nama': 'Poli Umum', 'kode': 'PU'},
      {'id': 2, 'nama': 'Poli Gigi', 'kode': 'PG'},
      {'id': 3, 'nama': 'Poli Anak', 'kode': 'PA'},
      {'id': 4, 'nama': 'Poli Kandungan', 'kode': 'PK'},
      {'id': 5, 'nama': 'Poli Penyakit Dalam', 'kode': 'PP'},
      {'id': 6, 'nama': 'Poli Mata', 'kode': 'PM'},
    ];
  }

  Future<Map<String, dynamic>> cekNIK(String nik) async {
    try {
      final res = await _client
          .post(
            _uri('/antrian/cek-nik'),
            headers: _jsonHeaders,
            body: jsonEncode({'nik': nik}),
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('ApiDataSource.cekNIK: $e');
    }
    return {'success': true, 'data': <String, dynamic>{'is_valid': true}};
  }

  Future<Map<String, dynamic>> createAntrian(
      Map<String, dynamic> body) async {
    try {
      final isBpjs = body['tipe'] == 'bpjs';
      final path = isBpjs ? '/antrian/bpjs' : '/antrian';
      final payload = isBpjs
          ? {
              'nik': body['nik'],
              'no_rujukan': body['no_rujukan'],
              'source': 'smartphone',
            }
          : body;

      final res = await _client
          .post(
            _uri(path),
            headers: _jsonHeaders,
            body: jsonEncode(payload),
          )
          .timeout(_timeout);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      final msg =
          (jsonDecode(res.body) as Map<String, dynamic>)['message'] as String?
              ?? 'Gagal membuat antrian';
      throw Exception(msg);
    } catch (e) {
      debugPrint('ApiDataSource.createAntrian: $e');
      rethrow;
    }
  }



  Future<List<Map<String, dynamic>>> getDokterByPoli(int poliId, [String? tanggal]) async {
    try {
      var url = '${ApiConstants.dokter}/poli/$poliId';
      if (tanggal != null && tanggal.isNotEmpty) {
        url += '?tanggal=$tanggal';
      }
      final res = await _client
          .get(_uri(url))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data']
                    as List<dynamic>? ??
                [])
            .cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to get dokter by poli');
    } catch (e) {
      debugPrint('ApiDataSource.getDokterByPoli: $e');
      rethrow;
    }
  }

  Future<dynamic> getRiwayatAntrian(String nik) async {
    try {
      final res = await _client
          .get(_uri('/antrian/riwayat/$nik'), headers: _jsonHeaders)
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return body['data'];
      }
      return [];
    } catch (e) {
      debugPrint('ApiDataSource.getRiwayatAntrian: $e');
      return [];
    }
  }

  Future<bool> deleteAntrian(String kodeBooking) async {
    try {
      final res = await _client
          .delete(_uri('/antrian/$kodeBooking'))
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.deleteAntrian: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchDashboardStats() async {
    try {
      final res = await _client
          .get(_uri(ApiConstants.antrianDashboardStats))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as Map<String, dynamic>)['data']
            as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('ApiDataSource.fetchDashboardStats: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchKunjunganStats(String period) async {
    try {
      final res = await _client
          .get(_uri('${ApiConstants.antrianKunjunganStats}?period=$period'))
          .timeout(_timeout);
      if (res.statusCode == 200) {
        return ((jsonDecode(res.body) as Map<String, dynamic>)['data']
        
                    as List<dynamic>? ??
                [])
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiDataSource.fetchKunjunganStats: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> setDokterStatusKhusus(Map<String, dynamic> data) async {
    try {
      final res = await _client
          .post(
            _uri(ApiConstants.dokterStatusKhusus),
            headers: _jsonHeaders,
            body: jsonEncode(data),
          )
          .timeout(_timeout);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return body['data'] as Map<String, dynamic>?;
      }
      return {'error': body['message'] ?? 'Gagal menyimpan status'};
    } catch (e) {
      debugPrint('ApiDataSource.setDokterStatusKhusus: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDokterStatusKhusus(int dokterID) async {
    try {
      final res = await _client
          .get(
            _uri('${ApiConstants.dokterStatusKhusus}/$dokterID'),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        return ((body['data'] as List<dynamic>?) ?? [])
            .cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('ApiDataSource.getDokterStatusKhusus: $e');
    }
    return [];
  }

  Future<bool> deleteDokterStatusKhusus(int id) async {
    try {
      final res = await _client
          .delete(
            _uri('${ApiConstants.dokterStatusKhusus}/$id'),
            headers: _jsonHeaders,
          )
          .timeout(_timeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiDataSource.deleteDokterStatusKhusus: $e');
      return false;
    }
  }
}