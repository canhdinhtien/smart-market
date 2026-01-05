import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../constants/api_constants.dart';
import 'offline_queue_service.dart';
import '../../data/models/pending_operation.dart';

class SyncService {
  final ApiClient _apiClient;
  final OfflineQueueService _queueService;
  bool _isSyncing = false;
  
  SyncService(this._apiClient, this._queueService);
  
  bool get isSyncing => _isSyncing;
  
  Future<void> syncAll() async {
    if (_isSyncing) {
      return;
    }
    
    _isSyncing = true;
    
    try {
      final operations = await _queueService.getAll();
      
      for (final op in operations) {
        try {
          await _syncOperation(op);
          await _queueService.remove(op.id);
        } on DioException catch (e) {
          
          // Handle specific errors
          if (e.response?.statusCode == 404) {
            // Item was deleted on server, remove from queue
            await _queueService.remove(op.id);
          } else {
            await _queueService.incrementRetry(op.id);
            
            // Stop syncing if too many retries
            if (op.retryCount >= 3) {
              // Keep in queue but don't retry anymore
            }
          }
        } catch (e) {
          await _queueService.incrementRetry(op.id);
        }
      }
      
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<void> _syncOperation(PendingOperation op) async {
    
    switch (op.type) {
      case 'create_shopping_list':
        await _apiClient.dio.post(ApiConstants.shopping, data: op.data);
        break;
        
      case 'update_shopping_list':
        final id = op.data['id'];
        await _apiClient.dio.put(ApiConstants.shoppingDetail(id), data: op.data);
        break;
        
      case 'delete_shopping_list':
        final id = op.data['id'];
        await _apiClient.dio.delete(ApiConstants.shoppingDetail(id));
        break;
        
      case 'add_task':
        final listId = op.data['shopping_list_id'];
        await _apiClient.dio.post(ApiConstants.shoppingTasks(listId), data: op.data);
        break;
        
      case 'update_task':
        final taskId = op.data['id'];
        await _apiClient.dio.put(ApiConstants.shoppingTaskDetail(taskId), data: op.data);
        break;
        
      case 'delete_task':
        final taskId = op.data['id'];
        await _apiClient.dio.delete(ApiConstants.shoppingTaskDetail(taskId));
        break;
        
      default:
    }
  }
}
