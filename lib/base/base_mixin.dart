import '../constants/constants.dart';
import '../di/di.dart';
import '../services/nav-service/i_nav_service.dart';

mixin BaseMixin {
  final INavService _navigator = inject<INavService>();
  final Px _dimens = inject<Px>();

  INavService get navigator => _navigator;

  Px get dimens => _dimens;
}
