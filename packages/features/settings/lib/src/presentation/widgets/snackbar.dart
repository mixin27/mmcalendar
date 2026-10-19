import 'package:flutter/material.dart';
import 'package:shared_ui_kit/shared_ui_kit.dart';

void showErrorSnackBar(BuildContext context, String message) =>
    context.showToast(message, kind: AppToastKind.error);
