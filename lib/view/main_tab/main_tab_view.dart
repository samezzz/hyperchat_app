import 'package:flutter/material.dart';

import '../home/home_view.dart';
import '../measure/measure_view.dart';
import '../chat/chat_view.dart';
import '../history/history_view.dart';
import '../insights/insights_view.dart';
import '../../common/colo_extension.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int selectTab = 0;
  final PageStorageBucket pageBucket = PageStorageBucket();
  Widget currentTab = const HomeView();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TColor.toggleDarkMode(isDarkMode);

    return Scaffold(
      backgroundColor: TColor.bgColor,
      body: PageStorage(bucket: pageBucket, child: currentTab),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15),
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              selectTab = 1;
              currentTab = const MeasureView();
            });
          },
          backgroundColor: isDarkMode
              ? TColor.primaryColor1
              : TColor.primaryColor1,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          child: Icon(
            selectTab == 1 ? Icons.favorite : Icons.favorite_outline,
            color: TColor.white,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Color.fromARGB(255, 80, 80, 80).withOpacity(0.5)
              : Color.fromARGB(255, 224, 194, 255).withOpacity(0.5),
          boxShadow: [
            BoxShadow(
              color: TColor.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomAppBar(
            elevation: 0,
            color: Colors.transparent,
            notchMargin: 0,
            shape: const CircularNotchedRectangle(),
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left side buttons
                  Row(
                    children: [
                      _buildNavItem(
                        icon: selectTab == 0 ? Icons.home : Icons.home_outlined,
                        isSelected: selectTab == 0,
                        onTap: () {
                          setState(() {
                            selectTab = 0;
                            currentTab = const HomeView();
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildNavItem(
                        icon: selectTab == 2 ? Icons.chat : Icons.chat_outlined,
                        isSelected: selectTab == 2,
                        onTap: () {
                          setState(() {
                            selectTab = 2;
                            currentTab = const ChatView();
                          });
                        },
                      ),
                    ],
                  ),
                  // Right side buttons
                  Row(
                    children: [
                      _buildNavItem(
                        icon: selectTab == 3 ? Icons.history : Icons.history_outlined,
                        isSelected: selectTab == 3,
                        onTap: () {
                          setState(() {
                            selectTab = 3;
                            currentTab = const HistoryView();
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      _buildNavItem(
                        icon: selectTab == 4 ? Icons.insights : Icons.insights_outlined,
                        isSelected: selectTab == 4,
                        onTap: () {
                          setState(() {
                            selectTab = 4;
                            currentTab = const InsightsView();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color.fromARGB(0, 0, 0, 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isSelected ? TColor.primaryColor1 : TColor.subTextColor,
            size: 30,
          ),
        ),
      ),
    );
  }
}
