class ServiceItem {
  final String id, name, masterId;
  final int durationMin;
  final num price;
  final bool isActive;
  ServiceItem(
      {required this.id,
      required this.name,
      required this.masterId,
      required this.durationMin,
      required this.price,
      required this.isActive});
  factory ServiceItem.fromMap(Map<String, dynamic> m) => ServiceItem(
      id: m['id'],
      name: m['name'],
      masterId: m['master_id'],
      durationMin: m['duration_min'] as int,
      price: m['price'] as num,
      isActive: (m['is_active'] ?? true) as bool);
}
