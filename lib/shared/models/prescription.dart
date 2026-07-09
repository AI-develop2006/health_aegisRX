import 'dart:convert';

class MedicineItem {
  final String name;
  final String interval;
  final bool morning;
  final bool afternoon;
  final bool evening;
  final bool night;
  final bool beforeFood;
  final bool afterFood;
  final String customInstruction;
  final String duration;
  final String strength;

  MedicineItem({
    required this.name,
    required this.interval,
    this.morning = false,
    this.afternoon = false,
    this.evening = false,
    this.night = false,
    this.beforeFood = false,
    this.afterFood = false,
    this.customInstruction = '',
    this.duration = '30 days',
    this.strength = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'interval': interval,
    'morning': morning,
    'afternoon': afternoon,
    'evening': evening,
    'night': night,
    'beforeFood': beforeFood,
    'afterFood': afterFood,
    'customInstruction': customInstruction,
    'duration': duration,
    'strength': strength,
  };

  factory MedicineItem.fromJson(Map<String, dynamic> json) => MedicineItem(
    name: json['name'] ?? '',
    interval: json['interval'] ?? '',
    morning: json['morning'] ?? false,
    afternoon: json['afternoon'] ?? false,
    evening: json['evening'] ?? false,
    night: json['night'] ?? false,
    beforeFood: json['beforeFood'] ?? false,
    afterFood: json['afterFood'] ?? false,
    customInstruction: json['customInstruction'] ?? '',
    duration: json['duration'] ?? '30 days',
    strength: json['strength'] ?? '',
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
  final String? riskBand;
  final String? overrideReason;

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
    this.riskBand,
    this.overrideReason,
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
    'riskBand': riskBand,
    'overrideReason': overrideReason,
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
      riskBand: json['riskBand'],
      overrideReason: json['overrideReason'],
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
      riskBand: riskBand,
      overrideReason: overrideReason,
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
      riskBand: riskBand,
      overrideReason: overrideReason,
    );
  }
}
