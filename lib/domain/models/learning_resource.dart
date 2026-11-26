import '../enums/app_enums.dart';

class LearningResource {
  const LearningResource({required this.type, this.name, this.url});

  final ResourceType type;
  final String? name;
  final String? url;

  String get displayTitle {
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return '${type.label} · $trimmed';
    }
    return type.label;
  }

  LearningResource copyWith({ResourceType? type, String? name, String? url}) {
    return LearningResource(
      type: type ?? this.type,
      name: name ?? this.name,
      url: url ?? this.url,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
    'url': url,
  };

  factory LearningResource.fromJson(Map<String, dynamic> json) =>
      LearningResource(
        type: ResourceType.values.byName(json['type'] as String),
        name: json['name'] as String?,
        url: json['url'] as String?,
      );
}
