import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Abonnement extends StatefulWidget {
  const Abonnement({super.key});

  @override
  State<Abonnement> createState() => _AbonnementState();
}

class _AbonnementState extends State<Abonnement> {
  final SupabaseClient supabase = Supabase.instance.client;

  bool _isLoading = true;
  bool _isSubscribed = false;
  String? _typeAbonnement;
  String? _currentSubscriptionType;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final response = await supabase
            .from('collecte')
            .select('type_abonnement, abonnement_actif')
            .eq('user_id', user.id)
            .single();

        setState(() {
          _isSubscribed = response['abonnement_actif'] ?? false;
          _currentSubscriptionType = response['type_abonnement'];
          _typeAbonnement = _currentSubscriptionType;
        });
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

    try {
      await supabase.from('collecte').upsert({
        'user_id': user.id,
        'type_abonnement': _typeAbonnement,
        'abonnement_actif': !_isSubscribed,
      });

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de l'opération : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestion de l\'abonnement',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF66BB6A),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF66BB6A).withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Card
                    _buildStatusCard(theme),
                    const SizedBox(height: 32),

                    // Subscription Options
                    if (!_isSubscribed) ...[
                      Text(
                        'Choisissez votre forfait',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez l\'option qui vous convient le mieux',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildSubscriptionOption('Mensuel', '9.99€', 'par mois', [
                        'Accès illimité à toutes les fonctionnalités',
                        'Support premium 24/7',
                        'Mises à jour prioritaires',
                      ]),
                      const SizedBox(height: 16),
                      _buildSubscriptionOption('Annuel', '99.99€', 'par an', [
                        'Tout le forfait mensuel',
                        'Deux mois gratuits',
                        'Fonctionnalités exclusives',
                      ], isPopular: true),
                    ],

                    // Action Button
                    const SizedBox(height: 32),
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isSubscribed
                  ? const Color(0xFF66BB6A).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isSubscribed ? Icons.check_circle : Icons.access_time,
              size: 48,
              color: _isSubscribed ? const Color(0xFF66BB6A) : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isSubscribed ? 'Abonnement actif' : 'Aucun abonnement actif',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _isSubscribed ? const Color(0xFF66BB6A) : Colors.grey[700],
            ),
          ),
          if (_isSubscribed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF66BB6A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _currentSubscriptionType ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF66BB6A),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubscriptionOption(
    String title,
    String price,
    String period,
    List<String> features, {
    bool isPopular = false,
  }) {
    final bool isSelected = _typeAbonnement == title;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF66BB6A)
              : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => setState(() => _typeAbonnement = title),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPopular)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: Color(0xFF66BB6A)),
                        SizedBox(width: 4),
                        Text(
                          'Plus populaire',
                          style: TextStyle(
                            color: Color(0xFF66BB6A),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF66BB6A),
                              ),
                        ),
                        Text(period, style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: Color(0xFF66BB6A),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Color(0xFF66BB6A),
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sélectionné',
                          style: TextStyle(
                            color: Color(0xFF66BB6A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _toggleSubscription,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSubscribed
              ? Colors.red[400]
              : const Color(0xFF66BB6A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSubscribed
                  ? Icons.cancel_outlined
                  : Icons.check_circle_outline,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _isSubscribed ? 'Se désabonner' : 'Confirmer l\'abonnement',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
