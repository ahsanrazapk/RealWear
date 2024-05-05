import 'package:flutter/foundation.dart';

import 'base_mixin.dart';

class BaseViewModel extends ChangeNotifier with BaseMixin {
  @protected
  void setState() => notifyListeners();
}
