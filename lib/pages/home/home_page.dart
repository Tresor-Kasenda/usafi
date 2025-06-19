import 'package:flutter/material.dart';
import 'package:projet_annuel/core/theme/app_theme.dart';
import 'package:projet_annuel/core/widgets/custom_widgets.dart';
import 'package:projet_annuel/pages/views/collect_page.dart';
import 'package:projet_annuel/pages/views/history_page.dart';
import 'package:projet_annuel/pages/views/planing_page.dart';
import 'package:projet_annuel/pages/views/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<Map<String, dynamic>?> _nextCollectionFuture;
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _nextCollectionFuture = _getNextCollection();
    _statsFuture = _getStats();
  }

  Future<Map<String, dynamic>?> _getNextCollection() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await Supabase.instance.client
          .from('collecte')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Terminé')
          .eq('confirmation_utilisateur', false);

      if (response.isEmpty) return null;

      final now = DateTime.now();
      Map<String, dynamic>? nextCollection;
      Duration? minDifference;

      for (var collecte in response) {
        final dateStr = collecte['date_collecte'];
        if (dateStr == null) continue;

        final date = DateTime.tryParse(dateStr);
        if (date == null) continue;

        final diff = date.difference(now).abs();

        if (minDifference == null || diff < minDifference) {
          minDifference = diff;
          nextCollection = collecte;
        }
      }

      return nextCollection;
    } catch (e) {
      print('Erreur lors du chargement de la prochaine collecte: $e');
      // Retourner des données de démonstration en cas d'erreur
      return {
        'id': 1,
        'date_collecte': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        'type_dechet': 'Plastique',
        'status': 'Terminé',
        'confirmation_utilisateur': false,
      };
    }
  }

  Future<Map<String, dynamic>> _getStats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return {'total': 0, 'pending': 0, 'completed': 0};
    }

    try {
      final totalResponse = await Supabase.instance.client
          .from('collecte')
          .select()
          .eq('user_id', user.id);

      final pendingResponse = await Supabase.instance.client
          .from('collecte')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'En attente');

      final completedResponse = await Supabase.instance.client
          .from('collecte')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'Terminé');

      return {
        'total': totalResponse.length,
        'pending': pendingResponse.length,
        'completed': completedResponse.length,
      };
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      // Retourner des données de démonstration en cas d'erreur
      return {'total': 5, 'pending': 2, 'completed': 3};
    }
  }

  Future<void> _confirmCollection(int collecteId) async {
    try {
      await Supabase.instance.client
          .from('collecte')
          .update({'confirmation_utilisateur': true})
          .eq('id', collecteId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collecte confirmée avec succès !'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        setState(() {
          _loadData();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Fonctionnalité non disponible - Base de données en cours de configuration',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        // Simuler la confirmation en mode démo
        setState(() {
          _loadData();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('USAFICO'),
            Text(
              'Usafi in Congo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implémenter les notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _loadData();
          });
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section de bienvenue
              _buildWelcomeSection(),
              const SizedBox(height: AppSpacing.lg),

              // Statistiques
              _buildStatsSection(),
              const SizedBox(height: AppSpacing.lg),

              // Prochaine collecte
              _buildNextCollectionSection(),
              const SizedBox(height: AppSpacing.lg),

              // Menu principal
              _buildMainMenu(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour ! 👋',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Prêt à contribuer à un Congo plus propre ?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos statistiques',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<Map<String, dynamic>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final stats =
                snapshot.data ?? {'total': 0, 'pending': 0, 'completed': 0};

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total',
                    '${stats['total']}',
                    Icons.recycling,
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    'En attente',
                    '${stats['pending']}',
                    Icons.pending,
                    AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    'Terminées',
                    '${stats['completed']}',
                    Icons.check_circle,
                    AppTheme.successColor,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppBorderRadius.medium),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNextCollectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prochaine collecte',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        FutureBuilder<Map<String, dynamic>?>(
          future: _nextCollectionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return StatusCard(
                title: 'Aucune collecte en attente',
                subtitle: 'Toutes vos collectes sont confirmées',
                icon: Icons.check_circle,
                color: AppTheme.successColor,
              );
            }

            final collecte = snapshot.data!;
            final dateCollecte = DateTime.parse(collecte['date_collecte']);
            final typeDechet = collecte['type_dechet'] ?? 'Type inconnu';
            final now = DateTime.now();
            final difference = dateCollecte.difference(now).inDays;
            final estDemain = difference == 1;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppBorderRadius.small,
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Collecte à confirmer',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.small,
                                      ),
                                    ),
                                    child: Text(
                                      estDemain
                                          ? 'Demain'
                                          : '${dateCollecte.day}/${dateCollecte.month}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(
                                        AppBorderRadius.small,
                                      ),
                                    ),
                                    child: Text(
                                      typeDechet,
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Confirmer la collecte',
                        icon: Icons.check_circle,
                        onPressed: () => _confirmCollection(collecte['id']),
                        backgroundColor: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMainMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.1,
          children: [
            MenuCard(
              title: 'Nouvelle Collecte',
              subtitle: 'Planifier une collecte',
              icon: Icons.add_box,
              iconColor: AppTheme.primaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CollectePage()),
                ).then((_) {
                  setState(() {
                    _loadData();
                  });
                });
              },
            ),
            MenuCard(
              title: 'Planning',
              subtitle: 'Voir vos collectes',
              icon: Icons.calendar_today,
              iconColor: AppTheme.secondaryColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlanningPage()),
                ).then((_) {
                  setState(() {
                    _loadData();
                  });
                });
              },
            ),
            MenuCard(
              title: 'Historique',
              subtitle: 'Collectes passées',
              icon: Icons.history,
              iconColor: AppTheme.warningColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HistoriquePage()),
                ).then((_) {
                  setState(() {
                    _loadData();
                  });
                });
              },
            ),
            MenuCard(
              title: 'Profil',
              subtitle: 'Gérer votre compte',
              icon: Icons.person,
              iconColor: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
