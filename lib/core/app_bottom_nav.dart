import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'routes.dart';

/// Bottom navigation: 4 tabs (cùng flow với web)
///   0 - Lộ trình (Roadmap)
///   1 - Từ vựng (Vocabulary)
///   2 - Lịch sử (History)
///   3 - Cá nhân (Account)
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == currentIndex) return;
          String route;
          switch (index) {
            case 0:
              route = AppRoutes.roadmap;
              break;
            case 1:
              route = AppRoutes.vocabulary;
              break;
            case 2:
              route = AppRoutes.examHistory;
              break;
            case 3:
              route = AppRoutes.account;
              break;
            default:
              return;
          }
          Navigator.pushReplacementNamed(context, route);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Lộ trình',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: 'Từ vựng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Lịch sử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}
