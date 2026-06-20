import 'dart:convert';

class MedicineItem {
  final String name;
  final String interval;

  MedicineItem({required this.name, required this.interval});

  Map<String, dynamic> toJson() => {
        'name': name,
        'interval': interval,
      };

  factory MedicineItem.fromJson(Map<String, dynamic> json) => MedicineItem(
        name: json['name'] ?? '',
        interval: json['interval'] ?? '',
      );
}

class Prescription {
  final String id;
  final String doctorName;
  final String hospitalName;
  final String patientName;
  final String disease;
  final String date;
  final String time;
  final List<MedicineItem> medicines;
  final String signature;
  final String doctorSignId;
  final bool isDispensed;

  Prescription({
    required this.id,
    required this.doctorName,
    required this.hospitalName,
    required this.patientName,
    required this.disease,
    required this.date,
    required this.time,
    required this.medicines,
    required this.signature,
    required this.doctorSignId,
    this.isDispensed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'doctorName': doctorName,
        'hospitalName': hospitalName,
        'patientName': patientName,
        'disease': disease,
        'date': date,
        'time': time,
        'medicines': medicines.map((m) => m.toJson()).toList(),
        'doctorSignId': doctorSignId,
      };

  factory Prescription.fromJson(Map<String, dynamic> json) {
    final list = json['medicines'] as List? ?? [];
    final meds = list.map((item) => MedicineItem.fromJson(item)).toList();
    return Prescription(
      id: json['id'] ?? '',
      doctorName: json['doctorName'] ?? '',
      hospitalName: json['hospitalName'] ?? '',
      patientName: json['patientName'] ?? '',
      disease: json['disease'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      medicines: meds,
      signature: json['signature'] ?? '',
      doctorSignId: json['doctorSignId'] ?? '',
      isDispensed: json['isDispensed'] ?? false,
    );
  }

  String getPayloadString() => jsonEncode(toJson());

  Prescription copyWith({bool? isDispensed}) {
    return Prescription(
      id: id,
      doctorName: doctorName,
      hospitalName: hospitalName,
      patientName: patientName,
      disease: disease,
      date: date,
      time: time,
      medicines: medicines,
      signature: signature,
      doctorSignId: doctorSignId,
      isDispensed: isDispensed ?? this.isDispensed,
    );
  }

  Prescription copyWithSignature(String newSig) {
    return Prescription(
      id: id,
      doctorName: doctorName,
      hospitalName: hospitalName,
      patientName: patientName,
      disease: disease,
      date: date,
      time: time,
      medicines: medicines,
      signature: newSig,
      doctorSignId: doctorSignId,
      isDispensed: isDispensed,
    );
  }
}
