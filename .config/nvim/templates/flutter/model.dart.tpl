import 'package:json_annotation/json_annotation.dart';

part '{{snake}}_model.g.dart';

@JsonSerializable(createJsonSchema: true, fieldRename: FieldRename.snake)
class {{Pascal}}Model {
  final int id;

  {{Pascal}}Model({required this.id});

  factory {{Pascal}}Model.fromJson(Map<String, dynamic> json) =>
      _${{Pascal}}ModelFromJson(json);

  Map<String, dynamic> toJson() => _${{Pascal}}ModelToJson(this);

  static const jsonSchema = _${{Pascal}}ModelJsonSchema;
}
