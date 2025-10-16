import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CustomStreamBuilder<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) onData;
  final Widget? loadingWidget;
  final Function()? onErrorPressed;
  const CustomStreamBuilder({
    super.key,
    required this.stream,
    required this.onData,
    this.loadingWidget,
    this.onErrorPressed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? const CustomLoading();
        }
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Get.snackbar('Error on getting stream data $stream',
                snapshot.error.toString());
          });
          return const SizedBox();
        }
        if (snapshot.hasData) {
          return onData(context, snapshot.data as T);
        }
        return const Center(child: Text('No data available'));
      },
    );
  }
}
