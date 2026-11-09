import 'package:{{package}}/features/{{feature}}/domain/repositories/{{snake}}_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{{snake}}_repository_impl.g.dart';

@riverpod
{{Pascal}}Repository {{camel}}Repository(Ref ref) {
  return {{Pascal}}RepositoryImpl();
}

class {{Pascal}}RepositoryImpl implements {{Pascal}}Repository {}
