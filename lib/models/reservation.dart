enum ReservationStatus {
  pending('Menunggu'),
  confirmed('Dikonfirmasi'),
  seated('Tiba / Menempati Meja'),
  cancelled('Dibatalkan');

  final String label;
  const ReservationStatus(this.label);

  static ReservationStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'seated':
        return ReservationStatus.seated;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'pending':
      default:
        return ReservationStatus.pending;
    }
  }
}

class Reservation {
  final String id;
  final String customerName;
  final String phone;
  final String tableId;
  final String tableNumber;
  final DateTime date;
  final String time; // e.g. "19:00"
  final int guestCount;
  final ReservationStatus status;
  final String notes;
  final DateTime createdAt;

  const Reservation({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.tableId,
    required this.tableNumber,
    required this.date,
    required this.time,
    required this.guestCount,
    this.status = ReservationStatus.confirmed,
    this.notes = '',
    required this.createdAt,
  });

  bool get isPending => status == ReservationStatus.pending;
  bool get isConfirmed => status == ReservationStatus.confirmed;
  bool get isSeated => status == ReservationStatus.seated;
  bool get isCancelled => status == ReservationStatus.cancelled;

  factory Reservation.fromJson(Map<String, dynamic> json, {String? id}) {
    return Reservation(
      id: id ?? json['id'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      tableId: json['tableId'] as String? ?? '',
      tableNumber: json['tableNumber'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      time: json['time'] as String? ?? '19:00',
      guestCount: (json['guestCount'] as num?)?.toInt() ?? 2,
      status: ReservationStatus.fromString(json['status'] as String? ?? 'confirmed'),
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'phone': phone,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'date': date.toIso8601String(),
      'time': time,
      'guestCount': guestCount,
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Reservation copyWith({
    String? id,
    String? customerName,
    String? phone,
    String? tableId,
    String? tableNumber,
    DateTime? date,
    String? time,
    int? guestCount,
    ReservationStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      phone: phone ?? this.phone,
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      date: date ?? this.date,
      time: time ?? this.time,
      guestCount: guestCount ?? this.guestCount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
