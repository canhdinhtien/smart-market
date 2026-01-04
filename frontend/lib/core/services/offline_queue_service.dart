import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/pending_operation.dart';

class OfflineQueueService {
  static const String _boxName = 'offline_queue';
  late Box<PendingOperation> _box;
  final _uuid = const Uuid();
  bool _initialized = false;
  
  Future<void> init() async {
    if (!_initialized) {
      _box = await Hive.openBox<PendingOperation>(_boxName);
      _initialized = true;
    }
  }
  
  // Add operation to queue
  Future<String> enqueue({
    required String type,
    required Map<String, dynamic> data,
    String? tempId,
  }) async {
    await init();
    
    final operation = PendingOperation(
      id: _uuid.v4(),
      type: type,
      data: data,
      timestamp: DateTime.now(),
      tempId: tempId,
    );
    
    await _box.put(operation.id, operation);
    return operation.id;
  }
  
  // Get all pending operations
  Future<List<PendingOperation>> getAll() async {
    await init();
    final operations = _box.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return operations;
  }
  
  // Remove operation after successful sync
  Future<void> remove(String id) async {
    await init();
    await _box.delete(id);
  }
  
  // Update retry count
  Future<void> incrementRetry(String id) async {
    await init();
    final op = _box.get(id);
    if (op != null) {
      final updated = PendingOperation(
        id: op.id,
        type: op.type,
        data: op.data,
        timestamp: op.timestamp,
        retryCount: op.retryCount + 1,
        tempId: op.tempId,
      );
      await _box.put(id, updated);
    }
  }
  
  // Clear all (for testing or reset)
  Future<void> clear() async {
    await init();
    await _box.clear();
  }
  
  // Get count
  Future<int> get count async {
    await init();
    return _box.length;
  }
}
