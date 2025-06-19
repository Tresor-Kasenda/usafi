import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_model.dart';

class SubscriptionRepository {
  final SupabaseClient _client;
  static const String _tableName = 'subscriptions';

  SubscriptionRepository(this._client);

  Future<SubscriptionModel> getSubscription(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('No subscription found for user');
      }

      return SubscriptionModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final subscription = await getSubscription(userId);
      return subscription.isValid;
    } catch (e) {
      return false;
    }
  }

  Future<SubscriptionModel> createSubscription({
    required String userId,
    required SubscriptionType subscriptionType,
  }) async {
    try {
      final now = DateTime.now();
      final expiresAt = now.add(subscriptionType.duration);

      final response = await _client
          .from(_tableName)
          .insert({
            'user_id': userId,
            'subscription_type': subscriptionType.name,
            'started_at': now.toIso8601String(),
            'expires_at': expiresAt.toIso8601String(),
            'is_active': true,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .maybeSingle();

      if (response == null) {
        throw Exception('Failed to create subscription');
      }

      return SubscriptionModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelSubscription(String userId) async {
    await _client
        .from(_tableName)
        .update({'is_active': false})
        .eq('user_id', userId);
  }

  Future<void> reactivateSubscription(String userId) async {
    await _client
        .from(_tableName)
        .update({'is_active': true})
        .eq('user_id', userId);
  }
}
