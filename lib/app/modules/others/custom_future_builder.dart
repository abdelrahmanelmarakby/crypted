import 'package:flutter/material.dart';

import 'custom_error_widget.dart';
import 'loading_widget.dart';

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
          return loadingWidget ?? LoadingWidget(withMaterial: usingMaterial);
        } else if (snapshot.hasError) {
          if (usingMaterial) {
            return Material(
              child: Center(
                child: errorWidget != null
                    ? errorWidget!(snapshot.error ?? "")
                    : CustomErrorWidget(error: snapshot.error.toString()),
              ),
            );
          } else {
            return Center(
              child: errorWidget != null
                  ? errorWidget!(snapshot.error ?? "")
                  : CustomErrorWidget(
                      error: snapshot.error.toString(),
                      onPressed: onErrorPressed,
                    ),
            );
          }
        } else if (snapshot.hasData) {
          return onData(context, snapshot.data as T);
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
