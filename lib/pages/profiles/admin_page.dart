import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:projet_annuel/pages/auth/views/logger_page.dart';
import 'package:projet_annuel/pages/views/error_page.dart';
import 'package:projet_annuel/services/sms_reminder_config.dart';
import 'package:projet_annuel/services/supabase_config.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initSupabase();
    runApp(const AdminApp());
  } catch (e) {
    runApp(ErrorApp(e.toString()));
  }
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usafico Admin',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AdminDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int commandesTerminee = 0;
  int commandesEnCours = 0;
  int utilisateur = 0;
  double totalDechets = 0;
  int agent = 0;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    final supabase = Supabase.instance.client;

    // Nombre de commandes en cours
    final commandes = await supabase
        .from('collecte')
        .select('id')
        .eq('status', 'En cours');

    final commandes2 = await supabase
        .from('collecte')
        .select('id')
        .eq('status', 'Terminé');
    final utilisateurs = await supabase.from('utilisateurs').select('id');
    final agents = await supabase.from("agents").select('id');
    // Somme des déchets collectés
    final quantites = await supabase
        .from('collecte')
        .select('quantite')
        .not('quantite', 'is', null);

    double somme = 0;
    for (final row in quantites) {
      final q = double.tryParse(row['quantite'].toString()) ?? 0;
      somme += q;
    }

    setState(() {
      commandesEnCours = commandes.length;
      commandesTerminee = commandes2.length;
      totalDechets = somme;
      utilisateur = utilisateurs.length;
      agent = agents.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // --- SIDEBAR ---
          Container(
            width: 220,
            color: Colors.teal.shade700,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 50,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Admin Panel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                buildMenuItem(Icons.dashboard, 'Dashboard', () {}),
                buildMenuItem(Icons.shopping_cart, 'Commandes', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CommandesPage()),
                  );
                }),
                buildMenuItem(Icons.map, 'Cartes', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartesPage()),
                  );
                }),
                buildMenuItem(Icons.bar_chart, 'Analyse', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartesPage()),
                  );
                }),
                buildMenuItem(Icons.support_agent, 'Gestion personnels', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GestionPersonnelPage(),
                    ),
                  );
                }),
                buildMenuItem(Icons.people, 'Agriculteurs', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AgriculteursPage()),
                  );
                }),
                buildMenuItem(Icons.supervised_user_circle, 'Utilisateurs', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const UsersPage()),
                  );
                }),
                buildMenuItem(Icons.message, 'Rappels', () async {
                  final service = SmsReminderService();
                  await service.sendAwarenessReminders();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rappels envoyés')),
                    );
                  }
                }),
              ],
            ),
          ),

          // --- CONTENU PRINCIPAL ---
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // HEADER
                  Container(
                    height: 60,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 20,
                        color: Color.fromARGB(255, 20, 20, 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // CORPS DU DASHBOARD
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Ligne 1 : Calendrier
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: TableCalendar(
                                    firstDay: DateTime.utc(2020, 1, 1),
                                    lastDay: DateTime.utc(2030, 12, 31),
                                    focusedDay: DateTime.now(),
                                    headerStyle: const HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                    ),
                                    calendarStyle: const CalendarStyle(
                                      todayDecoration: BoxDecoration(
                                        color: Colors.teal,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  dashboardInfoCard(
                                    Icons.shopping_cart,
                                    "Commandes en cours",
                                    "$commandesEnCours",
                                  ),
                                  const SizedBox(height: 16),
                                  dashboardInfoCard(
                                    Icons.delete,
                                    "Déchets collectés",
                                    "${totalDechets.toStringAsFixed(1)} kg",
                                  ),
                                  const SizedBox(height: 16),
                                  dashboardInfoCard(
                                    Icons.people,
                                    "Nombres utilisateurs",
                                    "$utilisateur",
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Ligne 2 : Statistiques
                        Row(
                          children: [
                            Expanded(
                              child: dashboardInfoCard(
                                Icons.shopping_cart,
                                "Commandes termines",
                                "$commandesTerminee",
                              ),
                            ),
                            Expanded(
                              child: dashboardInfoCard(
                                Icons.support_agent,
                                "Agents sur terrain",
                                "$agent",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }

  Widget dashboardInfoCard(IconData icon, String title, String data) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.teal.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.teal),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(data, style: TextStyle(color: Colors.teal.shade800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AgriculteursPage extends StatefulWidget {
  const AgriculteursPage({super.key});

  @override
  State<AgriculteursPage> createState() => _AgriculteursPageState();
}

class _AgriculteursPageState extends State<AgriculteursPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _agriculteurs = [];
  bool _isLoading = false;

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerAgriculteurs();
  }

  Future<void> _chargerAgriculteurs() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase.from('agriculteurs').select().order('nom');
      setState(() {
        _agriculteurs = List<Map<String, dynamic>>.from(data as List);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement agriculteurs : $e")),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterAgriculteur() async {
    final nom = _nomController.text.trim();
    final phone = _telController.text.trim();
    final email = _emailController.text.trim();

    if (nom.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs")),
      );
      return;
    }

    try {
      await supabase.from('agriculteurs').insert({
        'nom': nom,
        'phone': phone,
        'email': email,
      });

      _nomController.clear();
      _telController.clear();
      _emailController.clear();

      await _chargerAgriculteurs();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur ajout agriculteur : $e")));
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri params = Uri(scheme: 'mailto', path: email);

    try {
      // Pour le web, utilise window.open directement
      if (kIsWeb) {
        html.window.open(params.toString(), '_blank');
      } else {
        if (await canLaunchUrl(params)) {
          await launchUrl(params, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d’ouvrir le client mail')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lancement email : $e")));
    }
  }

  // Lancement appel
  Future<void> _launchPhone(String phone) async {
    final Uri params = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(params)) {
      await launchUrl(params);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de passer l’appel')),
      );
    }
  }

  Widget buildListeAgriculteurs() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_agriculteurs.isEmpty) {
      return const Center(child: Text("Aucun agriculteur trouvé."));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _agriculteurs.length,
      itemBuilder: (context, index) {
        final agr = _agriculteurs[index];
        final nom = agr['nom'] ?? '';
        final email = agr['email'] ?? '';
        final phone = agr['phone'] ?? '';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.person, color: Colors.teal),
            title: Text(
              nom,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    if (phone.isNotEmpty) _launchPhone(phone);
                  },
                  child: Text(
                    '📞 $phone',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    if (email.isNotEmpty) _launchEmail(email);
                  },
                  child: Text(
                    '✉️ $email',
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildFormulaire() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nomController,
          decoration: const InputDecoration(
            labelText: 'Nom Complet',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _telController,
          decoration: const InputDecoration(
            labelText: 'Téléphone',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _ajouterAgriculteur,
          child: const Text('Ajouter agriculteur'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des agriculteurs'),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "Ajouter un agriculteur",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: buildFormulaire(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Fermer"),
                ),
              ],
            ),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [const SizedBox(height: 8), buildListeAgriculteurs()],
            ),
          ),
        ),
      ),
    );
  }
}

class GestionPersonnelPage extends StatefulWidget {
  const GestionPersonnelPage({super.key});

  @override
  State<GestionPersonnelPage> createState() => _GestionPersonnelPageState();
}

class _GestionPersonnelPageState extends State<GestionPersonnelPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await Supabase.instance.client.from('agents').select();

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Erreur : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Agents Inscrits"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text("Aucun agent trouvé."))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: Text(user['nom'] ?? 'Nom inconnu'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user['email'] ?? 'Non fourni'}'),
                        Text('Téléphone: ${user['telephone'] ?? 'Non fourni'}'),
                        Text(
                          'num Matricule: ${user['immatriculation'] ?? 'Non fourni'}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CommandesPage extends StatefulWidget {
  const CommandesPage({super.key});

  @override
  _CommandesPageState createState() => _CommandesPageState();
}

class _CommandesPageState extends State<CommandesPage> {
  List<Map<String, dynamic>> _collectes = [];
  List<Map<String, dynamic>> utilisateurs = [];
  String selectedStatus = 'En cours';
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchUtilisateurs().then((_) => fetchCollectes());
  }

  Future<void> fetchUtilisateurs() async {
    try {
      final response = await Supabase.instance.client
          .from('utilisateurs')
          .select();

      if (response is List) {
        utilisateurs = response
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        utilisateurs = [];
      }
    } catch (e) {
      logger.e("Erreur lors du fetch des utilisateurs: $e");
      utilisateurs = [];
    }
  }

  Future<void> fetchCollectes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('collecte')
          .select()
          .order('created_at', ascending: false);

      if (response is List) {
        _collectes = response.map<Map<String, dynamic>>((e) {
          final map = Map<String, dynamic>.from(e);
          if (!map.containsKey('status') || map['status'] == null) {
            map['status'] = 'En cours';
          }
          return map;
        }).toList();
      } else {
        _collectes = [];
      }
    } catch (e) {
      logger.e("Erreur lors du fetch des collectes: $e");
      _collectes = [];
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> updateStatus(int id, String newStatus) async {
    try {
      // Update et récupère directement la liste des éléments modifiés
      final updatedRows = await Supabase.instance.client
          .from('collecte')
          .update({'status': newStatus})
          .eq('id', id)
          .select() // récupère les lignes modifiées
          .maybeSingle();

      if (updatedRows != null) {
        // Mise à jour réussie, on met à jour la liste locale
        final index = _collectes.indexWhere((c) => c['id'] == id);
        if (index != -1) {
          setState(() {
            _collectes[index]['status'] = newStatus;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Statut mis à jour avec succès")),
        );
      } else {
        // Pas d'erreur mais pas de ligne modifiée
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Aucune donnée modifiée")));
      }
    } catch (e) {
      logger.e("Erreur lors de la mise à jour du statut: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la mise à jour du statut"),
        ),
      );
    }
  }

  Widget buildStatusButton(String status) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: selectedStatus == status
            ? Colors.teal
            : Colors.teal[100],
      ),
      onPressed: () {
        setState(() {
          selectedStatus = status;
        });
      },
      child: Text(
        status,
        style: TextStyle(
          color: selectedStatus == status ? Colors.white : Colors.teal,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /*
  Widget buildOrderCard(Map<String, dynamic> collecte, dynamic utilisateurs) {
    final id = collecte['id'] as int;
    final typeDechet = collecte['type_dechet'] ?? "Type inconnu";
    final dateCollecte = collecte['date_collecte'] ?? "Date inconnue";
    final adresse = collecte['adresse'] ?? "Adresse inconnue";
    final quantite = collecte['quantite'] ?? "Quantité non précisée";
    final status = collecte['status'] ?? "En cours";
    final nom = utilisateurs['nom'] ?? "pas de nom";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.delete, color: Colors.teal),
        title: Text("$typeDechet - $quantite\nNom: $nom"),
        subtitle: Text("Adresse: $adresse\nDate: $dateCollecte"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(status),
              backgroundColor:
                  status == "Terminé" ? Colors.green : Colors.orange,
            ),
            if (status == 'En cours')
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: "Terminer cette collecte",
                onPressed: () => updateStatus(id, 'Terminé'),
              ),
          ],
        ),
      ),
    );
  }
*/
  Widget buildOrderCard(Map<String, dynamic> collecte, dynamic utilisateur) {
    final id = collecte['id'] as int;
    final typeDechet = collecte['type_dechet'] ?? "Type inconnu";
    final dateCollecte = collecte['date_collecte'] ?? "Date inconnue";
    final adresse = collecte['adresse'] ?? "Adresse inconnue";
    final quantite = collecte['quantite'] ?? "Quantité non précisée";
    final status = collecte['status'] ?? "En cours";
    final confirmation = collecte['confirmation_utilisateur'] == true;
    final nom = utilisateur['nom'] ?? "pas de nom";

    logger.i(
      'Confirmation utilisateur pour collecte $id : ${collecte['confirmation_utilisateur']}',
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.delete, color: Colors.teal),
        title: Text("$typeDechet - $quantite\nNom: $nom"),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Adresse: $adresse\nDate: $dateCollecte"),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text("Confirmation: "),
                  Icon(
                    confirmation ? Icons.check_circle : Icons.cancel,
                    color: confirmation ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    confirmation ? "Confirmée" : "Non confirmée",
                    style: TextStyle(
                      color: confirmation ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(status),
              backgroundColor: status == "Terminé"
                  ? Colors.green
                  : Colors.orange,
            ),
            if (status == 'En cours')
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: "Terminer cette collecte",
                onPressed: () => updateStatus(id, 'Terminé'),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Commandes"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Boutons pour filtrer par statut
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildStatusButton("En cours"),
                const SizedBox(width: 16),
                buildStatusButton("Terminé"),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _collectes
                        .where((c) => c['status'] == selectedStatus)
                        .isEmpty
                  ? Center(
                      child: Text(
                        "Aucune collecte \"$selectedStatus\" trouvée.",
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView(
                      children: _collectes
                          .where((c) => c['status'] == selectedStatus)
                          .map((collecte) {
                            final utilisateur = utilisateurs.firstWhere(
                              (u) => u['id'] == collecte['user_id'],
                              orElse: () => {'nom': 'Nom inconnu'},
                            );
                            return buildOrderCard(collecte, utilisateur);
                          })
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartesPage extends StatelessWidget {
  const CartesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carte'), backgroundColor: Colors.teal),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(-11.6604, 27.4794),
          zoom: 13.0,
          interactiveFlags: InteractiveFlag.all,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
        ],
      ),
    );
  }
}

/*
class TraceurPage extends StatefulWidget {
  const TraceurPage({super.key});

  @override
  _TraceurPageState createState() => _TraceurPageState();
}

class _TraceurPageState extends State<TraceurPage> {
  final MapController _mapController = MapController();
  List<LatLng> positions = [];
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    demanderPermissionLocalisation().then((granted) {
      if (granted) {
        _permissionGranted = true;
        // Par exemple, récupérer la position initiale ici
        recupererPositionInitiale();
      } else {
        // Permission refusée, tu peux afficher un message ou gérer le cas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission localisation refusée')),
        );
      }
    });
  }

  Future<bool> demanderPermissionLocalisation() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> recupererPositionInitiale() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      positions.add(LatLng(position.latitude, position.longitude));
      _mapController.move(positions.last, 15);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Traceur en temps réel'),
        backgroundColor: Colors.green.shade700,
      ),
      body:
          _permissionGranted && positions.isNotEmpty
              ? FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: positions.last,
                  zoom: 15,
                  interactiveFlags: InteractiveFlag.all,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: positions,
                        strokeWidth: 4,
                        color: Colors.blue,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: positions.last,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              )
              : const Center(child: CircularProgressIndicator()),
    );
  }
}

*/

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('utilisateurs')
          .select();

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      logger.e('Erreur : $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Utilisateurs Inscrits"),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text("Aucun utilisateur trouvé."))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: Text(user['nom'] ?? 'Nom inconnu'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user['email'] ?? 'Non fourni'}'),
                        Text('Téléphone: ${user['telephone'] ?? 'Non fourni'}'),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
