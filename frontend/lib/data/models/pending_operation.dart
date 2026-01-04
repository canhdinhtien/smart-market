import 'package:hive/hive.dart';

part 'pending_operation.g.dart';

@HiveType(typeId: 0)
class PendingOperation extends HiveObject {
  @HiveField(0)
  final String id; // UUID
  
  @HiveField(1)
  final String type; // 'create_list', 'update_list', 'delete_list', 'add_task', etc.
  
  @HiveField(2)
  final Map<String, dynamic> data; // Operation payload
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final int retryCount;
  
  @HiveField(5)
  final String? tempId; // Temporary ID for optimistic updates

  PendingOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
    this.tempId,
  });
  
  @override
  String toString() {
    return 'PendingOperation(id: $id, type: $type, tempId: $tempId, retryCount: $retryCount)';
  }
}
