import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

enum SubscriptionType {
  daily,
  monthly;

  String get displayName {
    switch (this) {
      case SubscriptionType.daily:
        return 'Journalier';
      case SubscriptionType.monthly:
        return 'Mensuel';
    }
  }

  Duration get duration {
    switch (this) {
      case SubscriptionType.daily:
        return const Duration(days: 1);
      case SubscriptionType.monthly:
        return const Duration(days: 30);
    }
  }
}

@JsonSerializable()
class SubscriptionModel {
  final String userId;
  final bool isActive;
  @JsonKey(fromJson: _subscriptionTypeFromJson, toJson: _subscriptionTypeToJson)
  final SubscriptionType subscriptionType;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionModel({
    required this.userId,
    required this.isActive,
    required this.subscriptionType,
    required this.startedAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static SubscriptionType _subscriptionTypeFromJson(String value) {
    return SubscriptionType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => SubscriptionType.monthly,
    );
  }

  static String _subscriptionTypeToJson(SubscriptionType type) => type.name;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  bool get isValid =>
      isActive && (expiresAt == null || expiresAt!.isAfter(DateTime.now()));
}
