import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showErrorToast(BuildContext context, String message) {
  toastification
    ..dismissAll()
    ..show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Row(
        children: [
          Expanded(
            child: Text(
              message,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.refresh,
            color: Theme.of(context).colorScheme.onError,
          ),
        ],
      ),
      alignment: Alignment.topCenter,
      primaryColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
      boxShadow: lowModeShadow,
      showProgressBar: false,
      animationDuration: Durations.medium1,
      // callbacks: ToastificationCallbacks(
      //   onTap: (toastItem) {
      //     if (context.mounted) {
      //       ref.invalidate(timebankInfoProvider);
      //     }
      //     toastification.dismiss(toastItem);
      //   },
      // ),
    );
}
