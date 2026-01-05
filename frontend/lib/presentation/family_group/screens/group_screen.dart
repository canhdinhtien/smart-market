import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/components/fade_in_slide.dart';
import '../../../../core/components/primary_button.dart';
import '../../../../core/components/custom_text_field.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/group_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../food/screens/food_manager_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<GroupProvider>(context, listen: false).fetchGroups());
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameController = TextEditingController();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: EdgeInsets.zero,
              content: GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.group_add_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('Tạo Nhóm Mới', 
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Kết nối gia đình để cùng quản lý thực phẩm hiệu quả hơn.', 
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Tên nhóm',
                      hint: 'Ví dụ: Gia đình nhỏ, Ký túc xá...',
                      controller: nameController,
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Tạo Nhóm ngay',
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          Provider.of<GroupProvider>(context, listen: false).createGroup(nameController.text);
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        if (groupProvider.isLoading && groupProvider.groups.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (groupProvider.groups.isEmpty) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: _buildNoGroupView(context),
          );
        }

        final currentGroup = groupProvider.currentGroup;
        final bool isGroupAdmin = currentGroup?['admin_user_id']?.toString() == authProvider.userId?.toString();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, groupProvider, isGroupAdmin),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSectionHeader('Thành viên', 'trong ${currentGroup?['name']}'),
                    const SizedBox(height: 12),
                    
                    if (groupProvider.isMembersLoading && (currentGroup?['members'] as List?)?.isEmpty != false)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: AppColors.primary)))
                    else if (groupProvider.membersError != null && (currentGroup?['members'] as List?)?.isEmpty != false)
                      Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Column(children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(groupProvider.membersError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        TextButton(onPressed: () => groupProvider.fetchGroupMembers(currentGroup?['id']), child: const Text('Thử lại')),
                      ])))
                    else ...?(currentGroup?['members'] as List?)?.asMap().entries.map((entry) {
                      int index = entry.key;
                      var member = entry.value;
                      return FadeInSlide(delay: 0.4 + (index * 0.05), child: _buildMemberCard(context, member, groupProvider, isGroupAdmin));
                    }),
                    
                    const SizedBox(height: 16),
                    
                    const SizedBox(height: 100), // Spacing for fab or end
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: isGroupAdmin ? _buildFAB(context, groupProvider) : null,
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return FadeInSlide(
      delay: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 16),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context, GroupProvider provider) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddMemberDialog(context, provider),
          borderRadius: BorderRadius.circular(20),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context, GroupProvider groupProvider, bool isGroupAdmin) {
    final memberCount = (groupProvider.currentGroup?['members'] as List?)?.length ?? 0;
    
    return SliverAppBar(
      expandedHeight: 220.0,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
      ),
      actions: [
        if (isGroupAdmin)
          IconButton(
            onPressed: () => _showEditGroupNameDialog(context, groupProvider),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
          ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: LayoutBuilder(
          builder: (context, constraints) {
            final double percentage = (constraints.maxHeight - kToolbarHeight) / (220.0 - kToolbarHeight);
            return Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                        Colors.white.withOpacity(0.95),
                        Colors.white,
                      ],
                      stops: const [0.0, 0.3, 0.8, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'GIA ĐÌNH',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 34,
                          letterSpacing: -1.5,
                          height: 1.1,
                          shadows: [
                            const Shadow(color: Colors.white, blurRadius: 15),
                            Shadow(color: Colors.white.withOpacity(0.8), blurRadius: 30),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ColorFilter.mode(Colors.white.withOpacity(0.4), BlendMode.srcOver),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.2),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                            ),
                            child: Row(
                              children: [
                                _buildHeaderStat('$memberCount', 'Thành viên', AppColors.primary),
                                Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                                _buildHeaderStat(isGroupAdmin ? 'Admin' : 'Member', 'Vai trò', Colors.blue.shade700),
                                Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 12)),
                                _buildGroupChip(groupProvider),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String count, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(count, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16, height: 1)),
        Text(label.toUpperCase(), style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6), fontWeight: FontWeight.w800, fontSize: 8, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildGroupChip(GroupProvider provider) {
    final groupName = provider.currentGroup?['name'] ?? 'Chọn nhóm';
    return GestureDetector(
      onTap: () => _showGroupPicker(context, provider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              groupName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1))],
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  void _showEditGroupNameDialog(BuildContext context, GroupProvider provider) {
    final nameController = TextEditingController(text: provider.currentGroup?['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Đổi tên nhóm', style: TextStyle(fontWeight: FontWeight.bold)),
        content: CustomTextField(
          label: 'Tên nhóm mới',
          controller: nameController,
          hint: 'Nhập tên nhóm...',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await provider.updateGroupName(nameController.text);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, GroupProvider provider) {
    final searchController = TextEditingController();
    bool isSearching = false;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Thêm thành viên', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text('Tìm kiếm người dùng bằng tên hoặc email để mời vào nhóm.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'Tìm kiếm',
                  hint: 'Nhập tên hoặc email...',
                  controller: searchController,
                  prefixIcon: Icons.search_rounded,
                  onChanged: (val) async {
                    setModalState(() => isSearching = true);
                    await provider.searchUsers(val, currentUserId: currentUserId);
                    setModalState(() => isSearching = false);
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Consumer<GroupProvider>(
                    builder: (context, prov, child) {
                      if (isSearching) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                      }
                      
                      if (searchController.text.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded, size: 64, color: Colors.grey[200]),
                              const SizedBox(height: 16),
                              const Text('Bắt đầu tìm kiếm...', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      if (prov.searchResults.isEmpty) {
                        return const Center(child: Text('Không tìm thấy người dùng phù hợp', style: TextStyle(color: Colors.grey)));
                      }

                      return ListView.builder(
                        itemCount: prov.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = prov.searchResults[index];
                          final bool alreadyInGroup = (prov.currentGroup?['members'] as List?)?.any((m) => m['id'].toString() == user['id'].toString()) ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    (user['name']?.toString() ?? 'U').isNotEmpty ? user['name'].toString()[0].toUpperCase() : 'U',
                                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user['name'] ?? 'Người dùng', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(user['email'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                if (alreadyInGroup)
                                  const Text('Đã tham gia', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold))
                                else
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await prov.addMember(user['id']);
                                        if (context.mounted) Navigator.pop(context);
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Đã thêm ${user['name']} vào nhóm')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      elevation: 0,
                                    ),
                                    child: const Text('Thêm', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, Map member, GroupProvider provider, bool isCurrentUserAdmin) {
    bool isMemberAdmin = member['role'] == 'Admin' || 
                         member['id']?.toString() == provider.currentGroup?['admin_user_id']?.toString();
    String email = member['email']?.toString() ?? 'Không có email';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (isMemberAdmin ? AppColors.primary : Colors.blueGrey).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: (isMemberAdmin ? AppColors.primary : Colors.blueGrey).withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isMemberAdmin ? AppColors.primary : Colors.blueGrey,
                      (isMemberAdmin ? AppColors.primary : Colors.blueGrey).withOpacity(0.5)
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: (isMemberAdmin ? AppColors.primary : Colors.blueGrey).withOpacity(0.1),
                        child: Text(
                          (member['name']?.toString() ?? 'U').isNotEmpty 
                              ? member['name'].toString()[0].toUpperCase() 
                              : 'U',
                          style: TextStyle(
                            color: isMemberAdmin ? AppColors.primary : Colors.blueGrey, 
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      if (isMemberAdmin)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 14),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member['name']?.toString() ?? 'Người dùng', 
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xFF1A1D1E), letterSpacing: -0.5)
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isMemberAdmin ? AppColors.primary : Colors.grey).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isMemberAdmin ? 'CHỦ NHÓM' : 'THÀNH VIÊN',
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 0.5,
                              color: isMemberAdmin ? AppColors.primary : Colors.grey.shade600
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentUserAdmin && !isMemberAdmin)
                    PopupMenuButton(
                      icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.person_remove_rounded, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Text('Xóa khỏi nhóm', style: TextStyle(color: Colors.red, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'remove') {
                          try {
                            await provider.removeMember(member['id']);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showGroupPicker(BuildContext context, GroupProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gia đình của bạn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...provider.groups.map((group) {
              final isSelected = group['id'].toString() == provider.currentGroup?['id']?.toString();
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.groups_rounded,
                    color: isSelected ? Colors.white : Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(
                  group['name'].toString(),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                onTap: () {
                  Navigator.pop(context);
                  provider.selectGroup(group['id']);
                },
              );
            }).toList(),
            const Divider(height: 32),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
              ),
              title: const Text('Tạo nhóm mới', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                _showCreateGroupDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGroupView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_3_rounded, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 32),
            const Text(
              'Gần như đơn độc...', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary)
            ),
            const SizedBox(height: 12),
            const Text(
              'Hãy tạo nhóm để cùng người thân quản lý thực phẩm thông minh hơn mỗi ngày.', 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14)
            ),
            const SizedBox(height: 40),
            PrimaryButton(
              text: 'Bắt đầu tạo nhóm', 
              onPressed: () => _showCreateGroupDialog(context)
            ),
          ],
        ),
      ),
    );
  }
}