import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;

class LoadingDialog extends StatefulWidget {
  const LoadingDialog({required this.task, required this.title, super.key});

  final TaskEither<Object, Unit> Function() task;
  final String title;

  static Future<Either<Object, Unit>?> showLoadingDialog(
    BuildContext context,
    TaskEither<Object, Unit> Function() task,
    String title,
  ) {
    return showDialog<Either<Object, Unit>>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => LoadingDialog(task: task, title: title),
    );
  }

  @override
  State<LoadingDialog> createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  late Stopwatch _stopwatch;

  var _completed = false;

  Future<void> executeTask() async {
    _stopwatch = Stopwatch()..start();
    final result = await widget.task().run();

    if (mounted) {
      setState(() {
        _completed = true;
      });
    }

    if (_stopwatch.elapsed < const Duration(seconds: 800)) {
      Future.delayed(
        const Duration(seconds: 1) - _stopwatch.elapsed,
        () {
          if (mounted) {
            Navigator.of(context).pop(result);
          }
        },
      );
    } else {
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    executeTask();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _completed,
      // onPopInvokedWithResult: (didPop, result) {
      //   if (_completed) {
      //     return Navigator.of(context).pop();
      //   }
      // },
      child: Center(
        child: Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            // very deep shadow, with three layers
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                offset: const Offset(0, 2),
                blurRadius: 4,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 10),
                blurRadius: 16,
                spreadRadius: 5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                offset: const Offset(0, 15),
                blurRadius: 32,
                spreadRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Enviando...',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Expanded(child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
