class Booking {
  final String id, masterId, clientId, serviceId, status;
  final DateTime startAt, endAt;
  Booking(
      {required this.id,
      required this.masterId,
      required this.clientId,
      required this.serviceId,
      required this.startAt,
      required this.endAt,
      required this.status});
  factory Booking.fromMap(Map<String, dynamic> m) => Booking(
      id: m['id'],
      masterId: m['master_id'],
      clientId: m['client_id'],
      serviceId: m['service_id'],
      startAt: DateTime.parse(m['start_at']).toUtc(),
      endAt: DateTime.parse(m['end_at']).toUtc(),
      status: m['status']);
}
