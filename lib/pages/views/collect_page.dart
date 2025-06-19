import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projet_annuel/pages/auth/views/logger_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollectePage extends StatefulWidget {
  const CollectePage({Key? key}) : super(key: key);

  @override
  _CollectePageState createState() => _CollectePageState();
}

class _CollectePageState extends State<CollectePage> {
  String? selectedType;
  DateTime? selectedDate;

  bool abonnementActif = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController adresseController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();

  final List<String> typesDechets = [
    'Déchet Non Organique',
    'Déchet Organique',
    'Déchet Organique et Non Organique',
  ];

  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDate() async {
    DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  Future<void> saveDataToSupabase() async {
    try {
      String? imageUrl;

      if (_image != null) {
        final fileBytes = await _image!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

        try {
          await Supabase.instance.client.storage
              .from('collecteimages')
              .uploadBinary(
                'user_${Supabase.instance.client.auth.currentUser!.id}/$fileName',
                fileBytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

          final publicUrl = Supabase.instance.client.storage
              .from('collecteimages')
              .getPublicUrl(
                'user_${Supabase.instance.client.auth.currentUser!.id}/$fileName',
              );

          imageUrl = publicUrl;
        } catch (e) {
          logger.e('Erreur lors de l\'upload de l\'image : $e');
        }
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur : Aucun utilisateur connecté.")),
        );
        return;
      }

      // Insertion dans collecte avec récupération de l'id généré
      final response = await Supabase.instance.client
          .from('collecte')
          .insert({
            'user_id': user.id,
            'type_dechet': selectedType,
            'date_collecte': selectedDate?.toIso8601String(),
            'abonnement_actif': abonnementActif,
            'adresse': adresseController.text,
            'quantite': quantiteController.text,
            'image_url': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single(); // important pour récupérer l'entrée insérée

      if (response == null || response['id'] == null) {
        throw Exception("Erreur lors de l'insertion dans collecte");
      }

      final collecteId = response['id'];

      //nsertion dans planification avec copie des mêmes données
      await Supabase.instance.client.from('planification').insert({
        'user_id': user.id,
        'type_dechet': selectedType,
        'date_collecte': selectedDate?.toIso8601String(),
        'abonnement_actif': abonnementActif,
        'adresse': adresseController.text,
        'quantite': quantiteController.text,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'collecte_id': collecteId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Collecte planifiée avec succès!")),
      );

      Navigator.pop(context);
    } catch (e) {
      logger.e('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la planification")),
      );
    }
  }

  /*
  Future<void> saveDataToSupabase() async {
    if (!abonnementActif) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Votre abonnement n'est pas actif. Impossible de planifier la collecte.",
          ),
        ),
      );
      return;
    }

    try {
      String? imageUrl;

      if (_image != null) {
        final fileBytes = await _image!.readAsBytes();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

        try {
          await Supabase.instance.client.storage
              .from('collecteimages')
              .uploadBinary(
                'user_${Supabase.instance.client.auth.currentUser!.id}/$fileName',
                fileBytes,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                ),
              );

          final publicUrl = Supabase.instance.client.storage
              .from('collecteimages')
              .getPublicUrl(
                'user_${Supabase.instance.client.auth.currentUser!.id}/$fileName',
              );

          imageUrl = publicUrl;
        } catch (e) {
          logger.e('Erreur lors de l\'upload de l\'image : $e');
        }
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur : Aucun utilisateur connecté.")),
        );
        return;
      }

      // Insertion dans collecte
      final response =
          await Supabase.instance.client
              .from('collecte')
              .insert({
                'user_id': user.id,
                'type_dechet': selectedType,
                'date_collecte': selectedDate?.toIso8601String(),
                'abonnement_actif': abonnementActif,
                'adresse': adresseController.text,
                'quantite': quantiteController.text,
                'image_url': imageUrl,
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      if (response == null || response['id'] == null) {
        throw Exception("Erreur lors de l'insertion dans collecte");
      }

      final collecteId = response['id'];

      // Insertion dans planification
      await Supabase.instance.client.from('planification').insert({
        'user_id': user.id,
        'type_dechet': selectedType,
        'date_collecte': selectedDate?.toIso8601String(),
        'abonnement_actif': abonnementActif,
        'adresse': adresseController.text,
        'quantite': quantiteController.text,
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'collecte_id': collecteId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Collecte planifiée avec succès!")),
      );

      Navigator.pop(context);
    } catch (e) {
      logger.e('Erreur lors de la sauvegarde: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors de la planification")),
      );
    }
  }
*/
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE1F3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF66BB6A),
        title: const Text('Planifier Collecte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type de déchet
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedType,
                  hint: const Text("Sélectionner le type de déchet"),
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Veuillez sélectionner un type' : null,
                  items: typesDechets.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
              const SizedBox(height: 16),

              // Image (obligatoire) avec FormField
              FormField<File>(
                builder: (state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          await _pickImage();
                          // Important : notifier la validation du FormField
                          state.didChange(
                            _image == null ? null : File(_image!.path),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.hasError
                                  ? Colors.red
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: _image == null
                                ? const Text(
                                    'Prendre une photo',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                : Image.file(File(_image!.path), height: 100),
                          ),
                        ),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 8),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                validator: (value) {
                  if (_image == null) {
                    return 'Veuillez prendre une photo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date de collecte (obligatoire)
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedDate == null
                          ? Colors.red
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? 'Sélectionner une date'
                            : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                        style: TextStyle(
                          color: selectedDate == null
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              if (selectedDate == null)
                const Padding(
                  padding: EdgeInsets.only(top: 5, left: 8),
                  child: Text(
                    'Veuillez sélectionner une date',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),

              // Abonnement actif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Abonnement actif : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(abonnementActif ? 'Oui' : 'Non'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Adresse
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: adresseController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse de collecte',
                    border: InputBorder.none,
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Champ requis' : null,
                ),
              ),
              const SizedBox(height: 16),

              // Quantité estimée
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité estimée (kg)',
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Champ requis';
                    }
                    final num? parsed = num.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Quantité invalide';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Bouton Planifier
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (selectedDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Veuillez sélectionner une date"),
                          ),
                        );
                        return;
                      }
                      saveDataToSupabase();
                    }
                  },
                  child: const Text(
                    'Planifier',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
