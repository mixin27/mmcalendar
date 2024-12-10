import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context) {
  showAdaptiveDialog(
    context: context,
    builder: (context) {
      return const AlertDialog(
        content: Center(
          child: CupertinoActivityIndicator(),
        ),
      );
    },
  );
}
