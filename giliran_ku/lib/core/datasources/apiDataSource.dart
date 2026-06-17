import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/apiConstants.dart';
import 'package:giliran_ku/core/models/doctorModel.dart';
import 'package:giliran_ku/core/models/patientModel.dart';
import 'package:giliran_ku/core/models/poliModel.dart';
import 'package:giliran_ku/core/models/ticketModel.dart';
import 'package:giliran_ku/core/datasources/apiException.dart';

class QueueApi {
  QueueApi._internal({http.Client? client})
      : _client = client ?? http.Client();

  static final QueueApi _instance = QueueApi._internal();

  factory QueueApi() => _instance;

  final http.Client _client;

  Future<Ticket> createBpjsTicket(String nikOrBpjs) async {
    final payload = await _post('/kiosk/bpjs', {
      'nik_or_bpjs': nikOrBpjs,
    });
    final data = _dataMap(payload);
    return Ticket.fromJson(data);
  }

  Future<Patient> validateNik(String nik) async {
    final payload = await _post('/antrian/cek-nik', {'nik': nik});
    final data = _dataMap(payload);
    return Patient(
      nik: nik,
      name: data['nama_pasien'] ?? '-',
    );
  }

  Future<List<Poli>> getPoliList({String? tanggal}) async {
    final payload = await _get(
      '/antrian/layanan',
      queryParameters: tanggal != null ? {'tanggal': tanggal} : null,
    );
    final data = _dataList(payload);
    return data
        .map((item) => Poli(
              id: '${item['id'] ?? item['poly_id'] ?? ''}',
              name: item['nama'] ?? item['poly_name'] ?? '',
            ))
        .toList();
  }

  Future<List<Doctor>> getDoctors(String poliId, String date) async {
    final payload = await _get(
      '/dokter/poli/$poliId',
      queryParameters: {'tanggal': date},
    );
    final data = _dataList(payload);
    return data.map((item) {
      if (item is Map<String, dynamic>) {
        return Doctor.fromJson(item);
      }
      return Doctor(id: '', name: '', poliId: poliId);
    }).toList();
  }

  Future<List<dynamic>> fetchRujukanBpjs(String nik) async {
    final payload = await _get('/kiosk/bpjs/rujukan/$nik');
    return _dataList(payload);
  }

  Future<Ticket> createGeneralTicket({
    required String nik,
    required Poli poli,
    required Doctor doctor,
    required bool isPasienLama,
    String? namaPasien,
    String? telepon,
  }) async {
    final payload = await _post('/antrian', {
      'nik': nik,
      'nama_pasien': isPasienLama ? '-' : (namaPasien ?? '-'),
      'telepon': isPasienLama ? '-' : (telepon ?? '-'),
      'poli_id': int.parse(poli.id),
      'dokter_id': int.parse(doctor.id),
      'is_pasien_lama': isPasienLama,
    });
    final data = _dataMap(payload);
    return Ticket.fromJson(data);
  }

  Future<Ticket> createBpjsTicketDynamic({
    required String nik,
    required String noRujukan,
    required int dokterId,
  }) async {
    final payload = await _post('/antrian/bpjs', {
      'nik': nik,
      'no_rujukan': noRujukan,
      'source': 'kiosk',
      'dokter_id': dokterId,
    });
    final data = _dataMap(payload);
    return Ticket.fromJson(data);
  }

  Future<Ticket> getNextPharmacyTicket() async {
    final payload = await _post('/kiosk/farmasi', null);
    final data = _dataMap(payload);
    return Ticket.fromJson(data);
  }

  Future<Ticket> getTicketByBookingCode(String code) async {
    final payload = await _get('/kiosk/booking/$code');
    final data = _dataMap(payload);
    return Ticket.fromJson(data);
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    return _request('GET', path, queryParameters: queryParameters);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic>? body,
  ) async {
    return _request('POST', path, body: body);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    http.Response response;

    if (method == 'GET') {
      response = await _client.get(uri);
    } else if (method == 'POST') {
      response = await _client.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: body == null ? null : jsonEncode(body),
      );
    } else {
      throw ApiException('Metode HTTP tidak didukung');
    }

    final decoded = _decodeBody(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    }

    final errorDetail = _extractError(decoded);
    final message = errorDetail ?? 'Gagal memproses permintaan';
    throw ApiException(message);
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    String baseStr;
    if (path.startsWith('/antrian') || path.startsWith('/kiosk') || path.startsWith('/tickets')) {
      baseStr = ApiConfig.antrianBaseUrl;
    } else if (path.startsWith('/pasien') || path.startsWith('/notifikasi') || path.startsWith('/kontrol-rutin')) {
      baseStr = ApiConfig.pasienBaseUrl;
    } else if (path.startsWith('/poliklinik') || path.startsWith('/dokter') || path.startsWith('/informasi')) {
      baseStr = ApiConfig.masterBaseUrl;
    } else {
      baseStr = ApiConfig.masterBaseUrl;
    }

    final base = Uri.parse(baseStr);
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final resolvedPath = '$basePath$normalizedPath';
    return base.replace(path: resolvedPath, queryParameters: queryParameters);
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return {};
    }
  }

  String? _extractError(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) {
        return error;
      }
      final message = decoded['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return null;
  }

  Map<String, dynamic> _dataMap(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw ApiException('Format data dari server tidak valid');
  }

  List<dynamic> _dataList(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is List) {
      return data;
    }
    return [];
  }
}