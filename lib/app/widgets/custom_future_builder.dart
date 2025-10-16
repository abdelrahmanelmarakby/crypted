import 'package:crypted_app/app/widgets/custom_loading.dart';
import 'package:flutter/material.dart';

class CustomFutureBuilder<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(BuildContext context, T data) onData;
  final Widget? loadingWidget;
  final Widget Function(Object error)? errorWidget;
  final Function()? onErrorPressed;
  final bool usingMaterial;
  const CustomFutureBuilder({
    super.key,
    required this.future,
    required this.onData,
    this.loadingWidget,
    this.errorWidget,
    this.usingMaterial = false,
    this.onErrorPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ?? CustomLoading();
        }
        if (snapshot.hasError) {
          return Text('err: ${snapshot.error}');
          // CustomErrorWidget(
          //   error: snapshot.error.toString(),
          //   onPressed: onErrorPressed,
          //   usingMaterial: usingMaterial,
          // );
        }
        if (snapshot.hasData) {
          return onData(context, snapshot.data as T);
        }
        return Text('err: ${snapshot.error}');
        // CustomErrorWidget(
        //   error: context.translate.something_went_wrong,
        //   onPressed: onErrorPressed,
        //   usingMaterial: usingMaterial,
        // );
      },
    );
  }
}
