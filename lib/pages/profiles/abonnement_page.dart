import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  int _remainingDays = 0;

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
          // Connexion directe avec le repository pour obtenir tous les détails de l'abonnement
          final status = await _subscriptionRepository.getSubscriptionStatus(
            user.id,
          );

          if (status['hasActiveSubscription']) {
            setState(() {
              _currentSubscription =
                  status['subscription'] as SubscriptionModel;
              _isSubscribed = true;
              _typeAbonnement = _currentSubscription!.subscriptionType;
              _remainingDays = status['remainingDays'] as int;
            });
          } else {
            setState(() {
              _currentSubscription = null;
              _isSubscribed = false;
              _typeAbonnement = null;
              _remainingDays = 0;
            });
          }
        } catch (e) {
          setState(() {
            _currentSubscription = null;
            _isSubscribed = false;
            _typeAbonnement = null;
            _remainingDays = 0;
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
        // Connexion directe avec le repository pour annuler l'abonnement
        await _subscriptionRepository.cancelSubscription(user.id);
      } else {
        if (_typeAbonnement == null) {
          throw Exception("Type d'abonnement non sélectionné");
        }
        // Connexion directe avec le repository pour créer l'abonnement
        _currentSubscription = await _subscriptionRepository.createSubscription(
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
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.verified,
                              color: Theme.of(context).colorScheme.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Abonnement ${_currentSubscription?.subscriptionType.displayName} Actif',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const Divider(height: 30),
                            if (_currentSubscription?.expiresAt != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date d\'expiration:',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  Text(
                                    _formatDate(
                                      _currentSubscription!.expiresAt!,
                                    ),
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Temps restant:',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge,
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '$_remainingDays ${_remainingDays > 1 ? "jours" : "jour"}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _remainingDays < 3
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                      ),
                                      if (_remainingDays < 3)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(
                                            Icons.warning,
                                            color: Colors.red,
                                            size: 18,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }
}
