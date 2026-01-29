import 'package:flutter/material.dart';
import '../models/user_data.dart';
import '../widgets/analysis_summary_widget.dart';
import 'supplements_page.dart';
import 'diet_page.dart';
import 'main_page.dart';
import 'calendar_page.dart';
import 'my_page.dart';

class HomePage extends StatefulWidget {
  final UserData userData;

  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2; // 홈을 기본으로 설정

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      SupplementsPage(userData: widget.userData),
      DietPage(userData: widget.userData),
      MainPage(userData: widget.userData),
      CalendarPage(userData: widget.userData),
      MyPage(userData: widget.userData),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF2196F3), // 파란색
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: '영양제',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: '식단',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '월별',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'MyPage',
          ),
        ],
      ),
    );
  }
}