import 'package:flutter/material.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final ScrollController _scrollController = ScrollController();
  final int targetElementIndex = 49;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToElement(targetElementIndex);
    });
  }

  void _scrollToElement(int index) {
    if (_scrollController.hasClients) {
      final double itemExtent =
          56; // Adjust this value based on your item height
      final double scrollOffset = itemExtent * index;
      _scrollController.animateTo(
        scrollOffset,
        duration:
            Duration(seconds: 2), // Adjust the animation duration as needed
        curve: Curves.easeInCirc, // Adjust the animation curve as needed
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Page'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: 100,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: Icon(Icons.person),
            title: Text('Person ${index + 1}'),
          );
        },
      ),
    );
  }
}
