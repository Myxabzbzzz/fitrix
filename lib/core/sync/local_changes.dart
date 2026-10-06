import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pinged whenever the user changes something that is synced (a plan, the
/// workout history, a chat). The sync engine listens and pushes the change
/// shortly after; with nobody signed in the pings go nowhere.
///
/// Changes applied *by* sync don't ping, so sync never triggers itself.
class LocalChanges {
  final _controller = StreamController<void>.broadcast(sync: true);

  Stream<void> get stream => _controller.stream;

  void notify() {
    if (!_controller.isClosed) _controller.add(null);
  }

  void dispose() => _controller.close();
}

final localChangesProvider = Provider<LocalChanges>((ref) {
  final changes = LocalChanges();
  ref.onDispose(changes.dispose);
  return changes;
});
