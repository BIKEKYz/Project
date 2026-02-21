import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/stores/activity_store.dart';
import '../theme/app_colors.dart';

class NotificationBell extends StatelessWidget {
  final ActivityStore activityStore;
  final String lang;

  const NotificationBell({
    super.key,
    required this.activityStore,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unread = activityStore.unreadCount;

    return GestureDetector(
      onTap: () => _showNotificationSheet(context, isDark),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3028)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_none_rounded,
              size: 22,
              color: isDark ? const Color(0xFF7DC99A) : AppColors.primary,
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showNotificationSheet(BuildContext context, bool isDark) {
    // Mark all as read when opening
    activityStore.markAllRead();

    final sheetBg = isDark ? const Color(0xFF1A2820) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A5040)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Text(
                      lang == 'en' ? 'Activity' : 'กิจกรรมวันนี้',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFF7DC99A)
                            : AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    if (activityStore.events.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          activityStore.clearAll();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          lang == 'en' ? 'Clear all' : 'ล้างทั้งหมด',
                          style: GoogleFonts.notoSansThai(
                            fontSize: 13,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // List
              Expanded(
                child: activityStore.events.isEmpty
                    ? _buildEmpty(isDark)
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                        itemCount: activityStore.events.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final event = activityStore.events[i];
                          return _ActivityTile(
                            event: event,
                            lang: lang,
                            isDark: isDark,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🌱', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            lang == 'en' ? 'No activity yet' : 'ยังไม่มีกิจกรรม',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF5A7A65) : AppColors.outline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lang == 'en'
                ? 'Water plants or add favorites to see activity here'
                : 'รดน้ำหรือบันทึกต้นไม้เพื่อดูกิจกรรม',
            style: GoogleFonts.notoSansThai(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF3A5040)
                  : AppColors.outline.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final ActivityEvent event;
  final String lang;
  final bool isDark;

  const _ActivityTile({
    required this.event,
    required this.lang,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3028) : const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0),
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: event.color.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(event.icon, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title(lang),
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFD4E8DC)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.timeAgo(lang),
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF5A7A65)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
          ),
          // Plant emoji
          Text(event.plantEmoji, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
