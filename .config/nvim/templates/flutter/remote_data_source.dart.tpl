import 'package:{{package}}/core/network/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '{{snake}}_remote_data_source.g.dart';

@riverpod
{{Pascal}}RemoteDataSource {{camel}}RemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return {{Pascal}}RemoteDataSource(apiClient);
}

class {{Pascal}}RemoteDataSource {
  final ApiClient _apiClient;

  {{Pascal}}RemoteDataSource(this._apiClient);
}
