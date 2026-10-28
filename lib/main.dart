import 'package:flutter/material.dart';
import 'pages/adjustment_work_page.dart';
import 'pages/stock_management_page.dart';

void main() {
  runApp(const ReedNoteApp());
}

class ReedNoteApp extends StatelessWidget {
  const ReedNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReedNote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber.shade800,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainRootPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// 2ページ構成を管理するルート画面
// ==========================================
class MainRootPage extends StatefulWidget {
  const MainRootPage({super.key});

  static void switchPage(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainRootPageState>();
    state?.setPage(index);
  }

  @override
  State<MainRootPage> createState() => _MainRootPageState();
}

class _MainRootPageState extends State<MainRootPage> {
  int _currentIndex = 0; // 0: 削り・調整 (メイン), 1: 素材ストック管理

  void setPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdjustmentWorkPage(),
          MainStockNavigationPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note),
            selectedIcon: Icon(Icons.edit_note, color: Colors.amber),
            label: '1. リード管理・調整',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Colors.amber),
            label: '2. 素材ストック管理',
          ),
        ],
      ),
    );
  }
}