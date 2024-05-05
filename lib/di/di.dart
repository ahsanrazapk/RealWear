import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wfveflutterexample/constants/constants.dart';
import 'package:wfveflutterexample/services/nav-service/i_nav_service.dart';
import 'package:wfveflutterexample/services/nav-service/nav_service.dart';


final inject = GetIt.instance;

Future<void> setupLocator() async {
  inject.registerSingletonAsync(() => SharedPreferences.getInstance());
  inject.registerLazySingleton<INavService>(() => NavService());
  inject.registerLazySingleton<Px>(() => Px());

}
