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
          .select('*')
          .eq('user_id', userId)
          .single();

      return SubscriptionModel.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('No subscription found for user: ${e.toString()}');
    }
  }

  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('is_active, expires_at')
          .eq('user_id', userId)
          .single();

      final isActive = response['is_active'] as bool;
      final expiresAtStr = response['expires_at'] as String?;

      if (!isActive) return false;
      if (expiresAtStr == null) return true;

      final expiresAt = DateTime.parse(expiresAtStr);
      return expiresAt.isAfter(DateTime.now());
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

      final subscriptionData = {
        'user_id': userId,
        'subscription_type': subscriptionType.name,
        'started_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _client.from(_tableName).insert(subscriptionData);

      // Créer directement l'objet à partir des données insérées
      return SubscriptionModel(
        userId: userId,
        isActive: true,
        subscriptionType: subscriptionType,
        startedAt: now,
        expiresAt: expiresAt,
        createdAt: now,
        updatedAt: now,
      );
    } catch (e) {
      throw Exception('Failed to create subscription: ${e.toString()}');
    }
  }

  Future<void> cancelSubscription(String userId) async {
    try {
      final now = DateTime.now();
      await _client
          .from(_tableName)
          .update({'is_active': false, 'updated_at': now.toIso8601String()})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to cancel subscription: ${e.toString()}');
    }
  }

  Future<SubscriptionModel> reactivateSubscription(String userId) async {
    try {
      final now = DateTime.now();

      // Mise à jour de l'abonnement
      await _client
          .from(_tableName)
          .update({'is_active': true, 'updated_at': now.toIso8601String()})
          .eq('user_id', userId);

      // Récupération de l'abonnement mis à jour
      return await getSubscription(userId);
    } catch (e) {
      throw Exception('Failed to reactivate subscription: ${e.toString()}');
    }
  }

  /// Retourne le nombre de jours restants avant l'expiration de l'abonnement
  /// Retourne 0 si l'abonnement n'est pas actif ou a déjà expiré
  Future<int> getRemainingDays(String userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('is_active, expires_at')
          .eq('user_id', userId)
          .single();

      final isActive = response['is_active'] as bool;
      final expiresAtStr = response['expires_at'] as String?;

      if (!isActive || expiresAtStr == null) return 0;

      final expiresAt = DateTime.parse(expiresAtStr);
      final now = DateTime.now();

      if (expiresAt.isBefore(now)) return 0;

      return expiresAt.difference(now).inDays +
          1; // +1 pour inclure le jour actuel
    } catch (e) {
      return 0;
    }
  }

  /// Vérifie si l'utilisateur a un abonnement actif et retourne les détails
  /// incluant le nombre de jours restants
  Future<Map<String, dynamic>> getSubscriptionStatus(String userId) async {
    try {
      final hasSubscription = await hasActiveSubscription(userId);

      if (!hasSubscription) {
        return {
          'hasActiveSubscription': false,
          'remainingDays': 0,
          'subscription': null,
        };
      }

      final subscription = await getSubscription(userId);
      final remainingDays = await getRemainingDays(userId);

      return {
        'hasActiveSubscription': true,
        'remainingDays': remainingDays,
        'subscription': subscription,
      };
    } catch (e) {
      return {
        'hasActiveSubscription': false,
        'remainingDays': 0,
        'subscription': null,
        'error': e.toString(),
      };
    }
  }
}
