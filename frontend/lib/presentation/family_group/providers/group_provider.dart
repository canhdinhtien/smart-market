import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class GroupProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<Map<String, dynamic>> _groups = [];
  Map<String, dynamic>? _homeGroup;
  Map<String, dynamic>? _managementGroup;
  String? _error;
  String? _membersError;
  bool _isLoading = false;
  bool _isMembersLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  GroupProvider(this._apiClient);

  List<Map<String, dynamic>> get groups => _groups;
  Map<String, dynamic>? get homeGroup => _homeGroup;
  Map<String, dynamic>? get managementGroup => _managementGroup;
  
  // Backward compatibility (defaults to managementGroup)
  Map<String, dynamic>? get currentGroup => _managementGroup;
  
  String? get error => _error;
  String? get membersError => _membersError;
  bool get isLoading => _isLoading;
  bool get isMembersLoading => _isMembersLoading;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  void clearState() {
    _groups = [];
    _homeGroup = null;
    _managementGroup = null;
    _error = null;
    _membersError = null;
    _isLoading = false;
    _isMembersLoading = false;
    _searchResults = [];
    notifyListeners();
  }

  Future<void> fetchGroups() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.groups);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        List<dynamic>? fetchedList;
        if (data is List) {
          fetchedList = data;
        } else if (data is Map) {
          // Comprehensive check for possible keys
          fetchedList = data['groups'] ?? data['data'] ?? data['results'] ?? data['list'];
          if (fetchedList == null && data.values.any((v) => v is List)) {
             // Fallback: take the first value that is a list
             fetchedList = data.values.firstWhere((v) => v is List) as List?;
          }
        }
        
        if (fetchedList != null) {
          _groups = fetchedList.map((e) => Map<String, dynamic>.from(e)).toList();
        } else {
          _groups = [];
        }
        
        // Handle selection and synchronization
        if (_groups.isNotEmpty) {
          // 1. Sync homeGroup
          if (_homeGroup != null) {
            final String homeId = _homeGroup!['id'].toString();
            try {
              _homeGroup = _groups.firstWhere((g) => g['id'].toString() == homeId);
            } catch (_) {
              _homeGroup = _groups.first;
            }
          } else {
            _homeGroup = _groups.first;
          }

          // 2. Sync managementGroup
          if (_managementGroup != null) {
            final String mgmtId = _managementGroup!['id'].toString();
            try {
              _managementGroup = _groups.firstWhere((g) => g['id'].toString() == mgmtId);
            } catch (_) {
              _managementGroup = _groups.first;
            }
          } else {
            _managementGroup = _groups.first;
          }

          // Notify UI that groups are here
          notifyListeners();

          // 3. Robust member fetching
          if (_managementGroup != null) {
            fetchGroupMembers(_managementGroup!['id']);
          }
        } else {
          _homeGroup = null;
          _managementGroup = null;
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải danh sách nhóm';
      // In case of error, we keep old groups if they exist, or clear if absolutely failed
      if (_groups.isEmpty) {
        _homeGroup = null;
        _managementGroup = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectHomeGroup(dynamic groupId) async {
    if (groupId == null) return;
    final group = _groups.firstWhere(
      (g) => g['id'].toString() == groupId.toString(),
      orElse: () => <String, dynamic>{},
    );
    if (group.isNotEmpty) {
      _homeGroup = group;
      notifyListeners();
    }
  }

  Future<void> selectManagementGroup(dynamic groupId) async {
    if (groupId == null) return;
    final group = _groups.firstWhere(
      (g) => g['id'].toString() == groupId.toString(),
      orElse: () => <String, dynamic>{},
    );
    if (group.isNotEmpty) {
      _managementGroup = group;
      notifyListeners();
      await fetchGroupMembers(_managementGroup!['id']);
    }
  }

  // Backward compatibility
  Future<void> selectGroup(dynamic groupId) => selectManagementGroup(groupId);

  Future<void> fetchGroupMembers(dynamic groupId) async {
    if (groupId == null) return;
    _isMembersLoading = true;
    _membersError = null;
    notifyListeners();

    try {
      await _fetchGroupMembersQuietly(groupId);
    } finally {
      _isMembersLoading = false;
      notifyListeners();
    }
  }
  // Internal helper for background sync
  Future<void> _fetchGroupMembersQuietly(dynamic groupId) async {
    if (groupId == null) return;
    try {
      final response = await _apiClient.dio.get(ApiConstants.groupMembers(groupId));
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic>? memberList;
        if (data is List) {
          memberList = data;
        } else if (data is Map) {
          memberList = data['members'] ?? data['users'] ?? data['data'];
        }
        if (memberList != null) {
          final mappedMembers = memberList.map((m) => Map<String, dynamic>.from(m)).toList();
          if (_managementGroup != null && _managementGroup!['id'].toString() == groupId.toString()) {
            _managementGroup!['members'] = mappedMembers;
          }
          if (_homeGroup != null && _homeGroup!['id'].toString() == groupId.toString()) {
            _homeGroup!['members'] = mappedMembers;
          }
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Quiet fetch error: $e');
    }
  }

  Future<void> createGroup(String name) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _apiClient.dio.post(ApiConstants.groups, data: {'name': name});
      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchGroups();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Lỗi khi tạo nhóm';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateGroupName(String newName) async {
    if (_managementGroup == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.groups}/${_managementGroup!['id']}',
        data: {'name': newName}
      );
      if (response.statusCode == 200) {
        await fetchGroups();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Lỗi khi cập nhật tên nhóm';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchUsers(String query, {dynamic currentUserId}) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.searchUsers(query));
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> users = [];
        if (data is Map && data.containsKey('users')) {
          users = data['users'] as List;
        } else if (data is List) {
          users = data;
        }

        // Filter out users who are already members or the current user
        final existingMemberIds = (_managementGroup?['members'] as List?)
            ?.map((m) => m['id'].toString())
            .toList() ?? [];
        
        final adminId = _managementGroup?['admin_user_id']?.toString();

        _searchResults = users.where((u) {
          final String uid = u['id'].toString();
          final String email = u['email']?.toString() ?? '';
          final bool isAlreadyMember = existingMemberIds.contains(uid);
          final bool isSelf = (currentUserId != null && uid == currentUserId.toString()) || (adminId != null && uid == adminId);
          final bool isReservedAdmin = email == 'canhva20047@gmail.com';
          
          return !isAlreadyMember && !isSelf && !isReservedAdmin;
        }).map((u) => Map<String, dynamic>.from(u)).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Lỗi khi tìm kiếm người dùng';
      _searchResults = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMemberByEmail(String email) async {
    if (_managementGroup == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final searchResponse = await _apiClient.dio.get(ApiConstants.searchUsers(email));
      String? targetUserId;
      if (searchResponse.statusCode == 200) {
        final data = searchResponse.data;
        List users = [];
        if (data is Map && data.containsKey('users')) {
          users = data['users'] as List;
        } else if (data is List) {
          users = data;
        }

        if (users.isNotEmpty) {
          targetUserId = users[0]['id']?.toString();
        }
      }

      if (targetUserId == null || targetUserId.isEmpty) throw Exception('Không tìm thấy người dùng với email: $email');
      final parsedId = int.tryParse(targetUserId);
      await addMember(parsedId ?? targetUserId);
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Lỗi khi thêm thành viên';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addMember(dynamic userId) async {
    if (_managementGroup == null) return;
    _error = null;
    // Note: We don't set _isLoading here to avoid global spinners
    
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.groupMembers(_managementGroup!['id']),
        data: {'userId': userId}
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sync in background immediately
        await _fetchGroupMembersQuietly(_managementGroup!['id']);
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Lỗi khi thêm thành viên';
      rethrow;
    }
  }

  Future<void> removeMember(dynamic userId) async {
    if (_managementGroup == null) return;
    try {
      final response = await _apiClient.dio.delete(ApiConstants.groupMember(_managementGroup!['id'], userId));
      if (response.statusCode == 200) {
        // Locally remove to provide instant feedback
        if (_managementGroup != null && _managementGroup!['members'] is List) {
          (_managementGroup!['members'] as List).removeWhere((m) => m['id'].toString() == userId.toString());
          notifyListeners();
        }
        // Then sync with server quietly
        _fetchGroupMembersQuietly(_managementGroup!['id']);
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Lỗi khi xóa thành viên';
      rethrow;
    }
  }
}
