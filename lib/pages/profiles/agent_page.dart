import 'package:flutter/material.dart';
import 'package:projet_annuel/pages/auth/views/logger_page.dart';
import 'package:projet_annuel/pages/views/error_page.dart';
import 'package:projet_annuel/services/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initSupabase();
    runApp(const MyApp());
  } catch (e) {
    runApp(ErrorApp(e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usafico',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const Inscription(), // Page de connexion par défaut
      debugShowCheckedModeBanner: false,
    );
  }
}

class Inscription extends StatefulWidget {
  const Inscription({Key? key}) : super(key: key);

  @override
  State<Inscription> createState() => _InscriptionState();
}

class _InscriptionState extends State<Inscription> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Contrôleurs
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _postNom = TextEditingController();
  final TextEditingController _prenom = TextEditingController();
  final TextEditingController _immatriculation = TextEditingController();
  final TextEditingController _lieuRdv = TextEditingController();
  final TextEditingController _dateRdv = TextEditingController();
  final TextEditingController _heureRdv = TextEditingController();
  final TextEditingController _telephone = TextEditingController();

  bool isLoading = false;

  bool _validatePhoneNumber(String phone) {
    final RegExp phoneRegex = RegExp(r'^\+243\d{9}$');
    return phoneRegex.hasMatch(phone);
  }

  bool _validateEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> inscrireUtilisateur() async {
    final email = _email.text.trim();
    final password = _password.text;
    final nom = _nom.text.trim();
    final postNom = _postNom.text.trim();
    final prenom = _prenom.text.trim();
    final immatriculation = _immatriculation.text.trim();
    final lieuRdv = _lieuRdv.text.trim();
    final dateRdv = _dateRdv.text.trim();
    final heureRdv = _heureRdv.text.trim();
    final telephone = _telephone.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        nom.isEmpty ||
        postNom.isEmpty ||
        prenom.isEmpty ||
        immatriculation.isEmpty ||
        lieuRdv.isEmpty ||
        dateRdv.isEmpty ||
        heureRdv.isEmpty ||
        telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    if (!_validateEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Adresse email invalide.")));
      return;
    }

    if (!_validatePhoneNumber(telephone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Numéro de téléphone invalide. Format attendu : +243XXXXXXXXX",
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;

      if (user != null) {
        final insertResponse = await Supabase.instance.client
            .from('agents')
            .insert({
              'id': user.id,
              'email': email,
              'nom': nom,
              'post_nom': postNom,
              'prenom': prenom,
              'immatriculation': immatriculation,
              'lieu_rdv': lieuRdv,
              'date_rdv': dateRdv,
              'heure_rdv': heureRdv,
              'telephone': telephone,
            });

        if (response != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AgentDashboard()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Erreur lors de l'enregistrement.")),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription Agent'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildField('Email', _email),
                    _buildField('Mot de passe', _password, obscure: true),
                    _buildField('Nom', _nom),
                    _buildField('Post-nom', _postNom),
                    _buildField('Prénom', _prenom),
                    _buildField('Téléphone (+243XXXXXXXXX)', _telephone),
                    _buildField('N° d\'immatriculation', _immatriculation),
                    _buildField('Lieu du RDV', _lieuRdv),
                    _buildField('Date du RDV (ex: 2025-06-10)', _dateRdv),
                    _buildField('Heure du RDV (ex: 14:00)', _heureRdv),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: inscrireUtilisateur,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('Créer mon compte'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
/*
class _ProfilAgentPageState extends State<ProfilAgentPage> {
  bool isLoading = true;
  String nom = '';
  String postNom = '';
  String prenom = '';
  String immatriculation = '';
  String lieuRdv = '';
  String dateRdv = '';
  String heureRdv = '';

  @override
  void initState() {
    super.initState();
    _loadAgentProfile();
  }

  Future<void> _loadAgentProfile() async {
    setState(() => isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucun utilisateur connecté")),
        );
        return;
      }

      logger.i("Chargement du profil de : ${user.email}");

      final response =
          await Supabase.instance.client
              .from('agents')
              .select(
                'nom, post_nom, prenom, immatriculation, lieu_rdv, date_rdv, heure_rdv',
              )
              .eq('id', user.id)
              .single();

      if (response == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Profil introuvable")));
        return;
      }

      setState(() {
        nom = response['nom'] ?? '';
        postNom = response['post_nom'] ?? '';
        prenom = response['prenom'] ?? '';
        immatriculation = response['immatriculation'] ?? '';
        lieuRdv = response['lieu_rdv'] ?? '';
        dateRdv = response['date_rdv'] ?? '';
        heureRdv = response['heure_rdv'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      logger.e("Erreur chargement profil : $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur chargement : $e")));
      setState(() => isLoading = false);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil de l\'agent'),
        backgroundColor: Colors.green,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildInfoRow('Nom', nom),
                    _buildInfoRow('Post-nom', postNom),
                    _buildInfoRow('Prénom', prenom),
                    _buildInfoRow('N° d\'immatriculation', immatriculation),
                    _buildInfoRow('Lieu du rendez-vous', lieuRdv),
                    _buildInfoRow('Date du rendez-vous', dateRdv),
                    _buildInfoRow('Heure du rendez-vous', heureRdv),
                  ],
                ),
              ),
    );
  }
}
*/

class CartePage extends StatelessWidget {
  const CartePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Points de collecte"),
        backgroundColor: Colors.green,
      ),
      body: const Center(
        child: Text(
          "Carte avec les points de collecte ici",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  List<Map<String, dynamic>> _collectes = [];
  List<Map<String, dynamic>> utilisateurs = [];
  String selectedStatus = 'En cours';
  String nomComplet = "";
  String email = "";
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _chargerInfosAgent();
    fetchUtilisateurs().then((_) => fetchCollectes());
  }

  Future<void> _chargerInfosAgent() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      final response = await Supabase.instance.client
          .from('agents')
          .select(
            'nom, post_nom, prenom, email, immatriculation, lieu_rdv, date_rdv, heure_rdv',
          )
          .eq('id', user.id)
          .single();
      setState(() {
        nomComplet =
            "${response['prenom']} ${response['nom']} ${response['post_nom']}";
        email = response['email'] ?? '';
      });
    }
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
      final updatedRows = await Supabase.instance.client
          .from('collecte')
          .update({'status': newStatus})
          .eq('id', id)
          .select()
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("Tableau de bord agent"),
          backgroundColor: const Color.fromARGB(255, 167, 215, 169),
          elevation: 4,

          actions: [
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'Voir la carte des points de collecte',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartePage()),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: Container(
            color: const Color.fromARGB(255, 196, 214, 197),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    nomComplet,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  accountEmail: Text(
                    email,
                    style: const TextStyle(fontSize: 14),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green[900],
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[900]!, Colors.green[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }
}
