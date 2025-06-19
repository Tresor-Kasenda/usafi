import 'package:flutter/material.dart';
import 'package:projet_annuel/pages/auth/views/logger_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriquePage extends StatefulWidget {
  HistoriquePage({Key? key}) : super(key: key);

  @override
  _HistoriquePageState createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  final supabase = Supabase.instance.client;
  List<Map<String, String>> _collectes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollectes();
  }

  Future<void> _loadCollectes() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      final response = await supabase
          .from('collecte')
          .select('id, date_collecte, type_dechet, status')
          .eq('user_id', user.id)
          .eq('confirmation_utilisateur', true)
          .order('created_at', ascending: false);

      final List<Map<String, String>> loaded = [];

      for (final row in response) {
        loaded.add({
          'date': row['date_collecte']?.toString() ?? 'Non spécifiée',
          'type': row['type_dechet']?.toString() ?? 'Non spécifié',
          'status': row['status']?.toString() ?? 'Non spécifié',
          'id': row['id'].toString(),
        });
      }

      setState(() {
        _collectes = loaded;
        _isLoading = false;
      });
    } catch (e) {
      logger.e("Erreur chargement : $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCollecte(String id) async {
    try {
      await supabase.from('collecte').delete().eq('id', id);

      setState(() {
        _collectes.removeWhere((c) => c['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Collecte supprimée avec succès")),
      );
    } catch (e) {
      logger.e('Erreur suppression : $e');
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
        title: const Text('Historique'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.green.shade50,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _collectes.isEmpty
          ? const Center(child: Text('Aucune collecte faite.'))
          : ListView.builder(
              itemCount: _collectes.length,
              itemBuilder: (context, index) {
                final collecte = _collectes[index];
                return ListTile(
                  title: Text(collecte['date']!),
                  subtitle: Text(
                    "${collecte['type']!} — Statut : ${collecte['status']!}",
                  ),
                  leading: Icon(Icons.recycling, color: Colors.green.shade700),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Confirmer la suppression"),
                          content: const Text("Supprimer cette collecte ?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Annuler"),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteCollecte(collecte['id']!);
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
            ),
    );
  }
}
