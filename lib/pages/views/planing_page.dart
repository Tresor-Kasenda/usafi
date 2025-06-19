import 'package:flutter/material.dart';
import 'package:projet_annuel/pages/auth/views/logger_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlanningPage extends StatefulWidget {
  PlanningPage({super.key});

  @override
  _PlanningPageState createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, String>>> _futureCollectes;

  @override
  void initState() {
    super.initState();
    _loadCollectes();
  }

  void _loadCollectes() {
    _futureCollectes = _getCollectes();
  }

  /*
  Future<List<Map<String, String>>> _getCollectes() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final response = await supabase
        .from('planification')
        .select('id, date_collecte, type_dechet, status')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (response == null) {
      throw Exception("Erreur de récupération des données");
    }

    List<Map<String, String>> collectes = [];

    for (final row in response) {
      collectes.add({
        'date': row['date_collecte']?.toString() ?? 'Non spécifiée',
        'type': row['type_dechet']?.toString() ?? 'Non spécifié',
        'status': row['status']?.toString() ?? 'Non spécifié',
        'id': row['id'].toString(),
      });
    }

    return collectes;
  }
*/
  Future<List<Map<String, String>>> _getCollectes() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    // Vérifie si l'utilisateur a un abonnement actif
    final userResponse = await supabase
        .from('collecte')
        .select('abonnement_actif')
        .eq('user_id', user.id)
        .single();

    if (userResponse == null || userResponse['abonnement_actif'] != true) {
      // Si abonnement inactif, on retourne une liste vide
      return [];
    }

    // Requête pour récupérer les collectes planifiées
    final response = await supabase
        .from('planification')
        .select('id, date_collecte, type_dechet, status, collecte(status)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    if (response == null) {
      throw Exception("Erreur de récupération des données");
    }

    List<Map<String, String>> collectes = [];

    for (final row in response) {
      final collecteStatus = row['collecte'] != null
          ? row['collecte']['status']
          : null;

      // Inclure uniquement les collectes non terminées
      if (collecteStatus != 'Terminé') {
        collectes.add({
          'date': row['date_collecte']?.toString() ?? 'Non spécifiée',
          'type': row['type_dechet']?.toString() ?? 'Non spécifié',
          'status': row['status']?.toString() ?? 'Non spécifié',
          'id': row['id'].toString(),
        });
      }
    }

    return collectes;
  }

  Future<void> _deletePlanification(String planificationId) async {
    try {
      // Supprimer la planification — le trigger supprimera la collecte liée
      final result = await supabase
          .from('planification')
          .delete()
          .eq('id', planificationId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Planification  supprimée avec succès")),
      );

      // Recharger les données affichées
      setState(() {
        _futureCollectes = _getCollectes();
      });

      // Revenir à la page précédente
      Navigator.pop(context);
    } catch (e) {
      logger.e("Erreur lors de la suppression : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la suppression")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Planification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.green.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Planifications récentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<Map<String, String>>>(
                future: _futureCollectes,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('Aucune collecte planifiée.'),
                    );
                  }

                  final collectes = snapshot.data!;

                  return ListView.builder(
                    itemCount: collectes.length,
                    itemBuilder: (context, index) {
                      final collecte = collectes[index];
                      return ListTile(
                        title: Text(collecte['date']!),
                        subtitle: Text(
                          "${collecte['type']!} — Statut : ${collecte['status']!}",
                        ),
                        leading: Icon(
                          Icons.recycling,
                          color: Colors.green.shade700,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Confirmer la suppression"),
                                content: const Text(
                                  "Êtes-vous sûr de vouloir supprimer cette collecte ?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deletePlanification(collecte['id']!);
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Supprimer"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
