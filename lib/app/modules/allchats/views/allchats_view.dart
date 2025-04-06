import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/allchats_controller.dart';

class AllchatsView extends GetView<AllchatsController> {
  const AllchatsView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AllchatsView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'AllchatsView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
