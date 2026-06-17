import 'package:giliran_ku/core/datasources/apiDataSource.dart';
import 'package:giliran_ku/core/models/doctorModel.dart';
import 'package:giliran_ku/core/models/patientModel.dart';
import 'package:giliran_ku/core/models/poliModel.dart';
import 'package:giliran_ku/core/models/ticketModel.dart';

class ConsultationController {
  ConsultationController({QueueApi? api}) : _api = api ?? QueueApi();

  final QueueApi _api;

  Future<Ticket> createTicketForBpjs(String nikOrBpjs) {
    return _api.createBpjsTicket(nikOrBpjs);
  }

  Future<List<dynamic>> fetchRujukanBpjs(String nik) {
    return _api.fetchRujukanBpjs(nik);
  }

  Future<Ticket> createBpjsTicketDynamic({
    required String nik,
    required String noRujukan,
    required int dokterId,
  }) {
    return _api.createBpjsTicketDynamic(
      nik: nik,
      noRujukan: noRujukan,
      dokterId: dokterId,
    );
  }

  Future<Patient> validateNik(String nik) {
    return _api.validateNik(nik);
  }

  Future<List<Poli>> fetchPoliList({String? tanggal}) {
    return _api.getPoliList(tanggal: tanggal);
  }

  Future<List<Doctor>> fetchDoctors(String poliId, String date) {
    return _api.getDoctors(poliId, date);
  }

  Future<Ticket> createTicketForGeneral({
    required String nik,
    required Poli poli,
    required Doctor doctor,
    required bool isPasienLama,
    String? namaPasien,
    String? telepon,
  }) {
    return _api.createGeneralTicket(
      nik: nik,
      poli: poli,
      doctor: doctor,
      isPasienLama: isPasienLama,
      namaPasien: namaPasien,
      telepon: telepon,
    );
  }
}