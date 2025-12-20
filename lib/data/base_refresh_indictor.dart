import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';

class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator(
      {required this.child, required this.onRefresh, Key? key})
      : super(key: key);
  final Widget? child;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final state = store.state;

    return RefreshIndicator(
      color: state.accentColor,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: child ??
          Icon(
            Icons.refresh,
            color: state.accentColor,
          ),
    );
  }
}
