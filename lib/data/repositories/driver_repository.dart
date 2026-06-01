import '../mock/mock_data.dart';
import '../models/driver.dart';

/// Fleet data source. The mock keeps an in-memory list seeded from [MockData].
abstract class DriverRepository {
  Future<List<Driver>> getDrivers();
  Future<Driver?> getDriver(String id);
  Future<Driver> setStatus(String id, DriverStatus status);
  List<Driver> get current;
}

class MockDriverRepository implements DriverRepository {
  final List<Driver> _drivers = [...MockData.drivers];

  @override
  List<Driver> get current => List.unmodifiable(_drivers);

  @override
  Future<List<Driver>> getDrivers() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return List.unmodifiable(_drivers);
  }

  @override
  Future<Driver?> getDriver(String id) async {
    final i = _drivers.indexWhere((d) => d.id == id);
    return i == -1 ? null : _drivers[i];
  }

  @override
  Future<Driver> setStatus(String id, DriverStatus status) async {
    final i = _drivers.indexWhere((d) => d.id == id);
    if (i == -1) throw StateError('Driver $id not found');
    _drivers[i] = _drivers[i].copyWith(status: status);
    return _drivers[i];
  }
}
