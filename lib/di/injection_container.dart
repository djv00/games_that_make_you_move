import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

// 👇 确认这里的文件名与实际生成的一致：
// 常见名：'injectable.config.dart' 或你项目里的 'injection_container.config.dart'
import 'injection_container.config.dart';

final getIt = GetIt.instance;

@injectableInit
Future<GetIt> configure() async {
  // 新版用扩展方法 init()，而不是 $initGetIt(...)
  return getIt.init();
}
