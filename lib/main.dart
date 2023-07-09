import 'package:flutter/material.dart';

import 'package:qrscanner/generate_screen.dart';
import 'qr_view_screen.dart';
import 'bottom_navigation.dart';

void main() => runApp(const MaterialApp(home: MyHome()));

class MyHome extends StatefulWidget {
  const MyHome({Key? key}) : super(key: key);

  @override
  _MyHomeState createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  int _selectedIndex = 1;

  static final List<Widget> _screens = <Widget>[
    GenerateScreen(),
    QRViewScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: _screens.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: CustomBottomBoxBar(
        onIndexChange: (int val) {
          setState(() {
            _selectedIndex = val;
          });
        },
        inicialIndex: _selectedIndex,
        items: [
          CustomBottomBoxBarItem(Icons.create_outlined, Text('Generate')),
          CustomBottomBoxBarItem(
              Icons.qr_code_scanner_outlined, Text('Qr Scan')),
        ],
      ),
    );
  }
}
