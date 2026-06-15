class PasienModel {
  final String nik;
  final String name;
  final String? username;
  final String? phone;
  final String? email;
  final String? bpjs;
  final String? bloodType;
  final String? gender;
  final String? address;
  final String? noRm;

  const PasienModel({
    required this.nik,
    required this.name,
    this.username,
    this.phone,
    this.email,
    this.bpjs,
    this.bloodType,
    this.gender,
    this.address,
    this.noRm,
  });

  factory PasienModel.fromJson(Map<String, dynamic> json) => PasienModel(
    nik: json['nik'] as String? ?? '',
    name: json['patient_name'] as String? ?? json['name'] as String? ?? '',
    username: json['username'] as String?,
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    bpjs: json['no_bpjs'] as String?,
    bloodType: json['golongan_darah'] as String?,
    gender: json['jenis_kelamin'] as String?,
    address: json['alamat'] as String?,
    noRm: json['no_rm'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'nik': nik,
    'patient_name': name,
    'username': username,
    'phone': phone,
    'email': email,
    'no_bpjs': bpjs,
    'golongan_darah': bloodType,
    'jenis_kelamin': gender,
    'alamat': address,
    'no_rm': noRm,
  };

  Map<String, dynamic> toMap() => {
    'nik': nik,
    'patient_name': name,
    'username': username,
    'phone': phone,
    'email': email,
    'no_bpjs': bpjs,
    'golongan_darah': bloodType,
    'jenis_kelamin': gender,
    'alamat': address,
    'no_rm': noRm,
  };
}