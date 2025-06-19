import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/models/subscription_model.dart';

class Abonnement extends StatefulWidget {
  const Abonnement({super.key});

  @override
  State<Abonnement> createState() => _AbonnementState();
}

class _AbonnementState extends State<Abonnement> {
  final SupabaseClient supabase = Supabase.instance.client;
  late final SubscriptionRepository _subscriptionRepository;

  bool _isLoading = true;
  bool _isSubscribed = false;
  SubscriptionType? _typeAbonnement;
  SubscriptionModel? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _subscriptionRepository = SubscriptionRepository(supabase);
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        try {
          final subscription = await _subscriptionRepository.getSubscription(
            user.id,
          );
          setState(() {
            _currentSubscription = subscription;
            _isSubscribed = subscription.isValid;
            _typeAbonnement = subscription.subscriptionType;
          });
        } catch (e) {
          setState(() {
            _currentSubscription = null;
            _isSubscribed = false;
            _typeAbonnement = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'abonnement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSubscription() async {
    if (_typeAbonnement == null && !_isSubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un type d'abonnement"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Utilisateur non connecté"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isSubscribed) {
        await _subscriptionRepository.cancelSubscription(user.id);
      } else {
        if (_typeAbonnement == null) {
          throw Exception("Type d'abonnement non sélectionné");
        }
        await _subscriptionRepository.createSubscription(
          userId: user.id,
          subscriptionType: _typeAbonnement!,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isSubscribed
                ? "Désabonnement effectué avec succès"
                : "Abonnement effectué avec succès",
          ),
          backgroundColor: const Color(0xFF66BB6A),
        ),
      );

      await _checkSubscriptionStatus();
    } catch (e) {
      debugPrint('Erreur lors de l\'opération d\'abonnement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Une erreur est survenue lors de l'opération. Veuillez réessayer.",
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Abonnement'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choisissez votre type d\'abonnement',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (!_isSubscribed) ...[
                    for (final type in SubscriptionType.values)
                      _buildSubscriptionCard(
                        title: type.displayName,
                        prix: type == SubscriptionType.daily
                            ? '2€/jour'
                            : '30€/mois',
                        description: type == SubscriptionType.daily
                            ? 'Accès aux notifications pendant 24h'
                            : 'Accès aux notifications pendant 30 jours',
                        isSelected: _typeAbonnement == type,
                        onSelect: () => setState(() => _typeAbonnement = type),
                      ),
                  ] else ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Abonnement actif : ${_currentSubscription?.subscriptionType.displayName}',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (_currentSubscription?.expiresAt != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Expire le : ${_formatDate(_currentSubscription!.expiresAt!)}',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _toggleSubscription,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSubscribed
                          ? Colors.red
                          : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _isSubscribed ? 'Se désabonner' : 'S\'abonner',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubscriptionCard({
    required String title,
    required String prix,
    required String description,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isSelected ? 8 : 1,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    prix,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(description, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
