
import 'package:flutter/material.dart';
import 'package:aitaku/screens/MapScreen/map-screen.dart';

class Base extends StatefulWidget {
  const Base({Key? key}) : super(key: key);

  @override
  State<Base> createState() => _BaseState();
}

class _BaseState extends State<Base> {

  int _currentIndex = 0;

  void _tapNavItem(int selectIndex) {
    setState(() {
      _currentIndex = selectIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(
        child: MapScreen(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: '今すぐ呼ぶ',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '設定'),
        ],
        currentIndex: _currentIndex,
        fixedColor: Theme.of(context).colorScheme.onPrimary,
        onTap: _tapNavItem,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
