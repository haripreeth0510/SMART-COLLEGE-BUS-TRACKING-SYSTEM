/// Represents a bus entity as stored in Firestore.
class BusModel {
  final String busId;
  final String busNumber;
  final String? numberPlate;
  final int? capacity;

  BusModel({
    required this.busId,
    required this.busNumber,
    this.numberPlate,
    this.capacity,
  });

  factory BusModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return BusModel(
      busId: docId ?? map['busId'] ?? '',
      busNumber: map['busNumber'] ?? 'Unknown Bus',
      numberPlate: map['numberPlate'],
      capacity: map['capacity'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'busId': busId,
      'busNumber': busNumber,
      'numberPlate': numberPlate,
      'capacity': capacity,
    };
  }
}
