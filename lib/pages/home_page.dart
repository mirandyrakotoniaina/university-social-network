import 'package:flutter/material.dart';
import '../models/groupe.dart';
import 'groupe_page.dart';
import '../models/publication.dart';
import '../data/groupes_data.dart';
import '../database/database_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String recherche = "";
  String typeFiltre = "Tous";
  bool chargement = true;
  List<Groupe> groupes = [];
  Set<int> groupesAdmin = {};
  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }


  Future<void> chargerDonnees() async {
    final db = DatabaseHelper();

    final groupesSQLite = await db.getGroupes();

    Set<int> admins = {};

    for (final groupe in groupesSQLite) {
      final role = await db.getRoleUtilisateur(groupe.id!);

      if (role == "admin") {
        admins.add(groupe.id!);
      }
    }

    if (!mounted) return;

    setState(() {
      groupes = groupesSQLite;
      groupesAdmin = admins;
      chargement = false;
    });

    print("GROUPES ADMIN : $groupesAdmin");
  }


  File? imageGroupe;

  Future<void> creerGroupe() async {
    final nomController = TextEditingController();
    final descriptionController = TextEditingController();

    File? imageChoisie;
    String typeSelectionne = "Classe";


    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Créer un groupe"),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: "Nom du groupe",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: typeSelectionne,
                      decoration: const InputDecoration(
                        labelText: "Type d'espace",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: "Classe",
                          child: Text("Classe"),
                        ),
                        DropdownMenuItem(
                          value: "Club",
                          child: Text("Club"),
                        ),
                        DropdownMenuItem(
                          value: "Association",
                          child: Text("Association"),
                        ),
                        DropdownMenuItem(
                          value: "Projet",
                          child: Text("Projet"),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            typeSelectionne = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 15),

                    if (imageChoisie != null)
                      Image.file(
                        imageChoisie!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();

                        final image = await picker.pickImage(
                          source: ImageSource.gallery,
                        );

                        if (image != null) {
                          setDialogState(() {
                            imageChoisie = File(image.path);
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text("Choisir une photo"),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Annuler"),
                ),

                ElevatedButton(
                  onPressed: () async {
                    try {
                      final nom = nomController.text.trim();
                      final description = descriptionController.text.trim();

                      if (nom.isEmpty || description.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Veuillez remplir tous les champs obligatoires."),
                          ),
                        );
                        return;
                      }

                      final nouveauGroupe = Groupe(
                        nom: nom,
                        description: description,
                        nombreMembres: 1,
                        type: typeSelectionne,
                        image: imageChoisie?.path ?? "default.png",
                        publications: [],
                      );

                      final db = DatabaseHelper();

                      print("➡️ Création du groupe...");
                      print("Nom : ${nouveauGroupe.nom}");
                      print("Type : ${nouveauGroupe.type}");

                      final groupeId = await db.insertGroupe(nouveauGroupe);

                      print("✅ Groupe créé avec ID : $groupeId");

                      final groupeAvecId = Groupe(
                        id: groupeId,
                        nom: nouveauGroupe.nom,
                        description: nouveauGroupe.description,
                        nombreMembres: nouveauGroupe.nombreMembres,
                        image: nouveauGroupe.image,
                        type: nouveauGroupe.type,
                        publications: [],
                      );

                      setState(() {
                        groupes.add(groupeAvecId);
                        groupesAdmin.add(groupeId);
                      });

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Groupe créé avec succès !"),
                        ),
                      );
                    } catch (e) {
                      print("❌ ERREUR CRÉATION GROUPE : $e");

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Erreur : $e"),
                        ),
                      );
                    }
                  },
                  child: const Text("Créer"),
                ),
              ],
            );
          },
        );
      },
    );
  }



  Future<void> changerCompte() async {
    final db = DatabaseHelper();

    await db.creerUtilisateursTest();

    final utilisateurs = await db.getTousLesUtilisateurs();

    if (!mounted) return;

    final utilisateurChoisi = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Choisir un compte"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: utilisateurs.length,
              itemBuilder: (context, index) {
                final utilisateur = utilisateurs[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(utilisateur.nom),
                  subtitle: Text(utilisateur.email),
                  onTap: () {
                    Navigator.pop(context, utilisateur.id);
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (utilisateurChoisi == null) return;

    await db.changerUtilisateur(utilisateurChoisi);

    await chargerDonnees();
  }

  @override
  Widget build(BuildContext context) {



    final groupesFiltres = groupes.where((groupe) {
      final correspondRecherche =
          groupe.nom.toLowerCase().contains(recherche.toLowerCase()) ||
              groupe.description.toLowerCase().contains(recherche.toLowerCase());

      final correspondType =
          typeFiltre == "Tous" || groupe.type == typeFiltre;

      return correspondRecherche && correspondType;
    }).toList();
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Text(
          "Réseau Social Universitaire",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: changerCompte,
            icon: const Icon(Icons.person),
            tooltip: "Changer de compte",
          ),
          IconButton(
            onPressed: creerGroupe,
            icon: const Icon(
              Icons.add_circle,
              size: 30,
            ),
            tooltip: "Créer un groupe",
          ),
        ],
      ),

      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  recherche = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Rechercher un groupe...",
                prefixIcon: const Icon(
                  Icons.search,
                  color: Colors.green,
                ),
                filled: true,
                fillColor: Colors.green.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<String>(
              initialValue: typeFiltre,
              decoration: InputDecoration(
                labelText: "Filtrer par type",
                prefixIcon: const Icon(
                  Icons.filter_list,
                  color: Colors.green,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.green.shade200,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.green,
                    width: 2,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: "Tous",
                  child: Text("Tous"),
                ),
                DropdownMenuItem(
                  value: "Classe",
                  child: Text("Classe"),
                ),
                DropdownMenuItem(
                  value: "Club",
                  child: Text("Club"),
                ),
                DropdownMenuItem(
                  value: "Association",
                  child: Text("Association"),
                ),
                DropdownMenuItem(
                  value: "Projet",
                  child: Text("Projet"),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    typeFiltre = value;
                  });
                }
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: groupesFiltres.length,
              itemBuilder: (context, index) {
                print("Nom : ${groupesFiltres[index].nom}");
                print("IMAGE = ${groupesFiltres[index].image}");
                return Card(
                  color: Colors.white,
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(
                      color: Colors.green.shade100,
                    ),
                  ),


                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: groupesFiltres[index].image == "default.png"
                          ? Container(
                        width: 55,
                        height: 55,
                        color: Colors.green.shade50,
                        child: const Icon(
                          Icons.groups,
                          size: 32,
                          color: Colors.green,
                        ),
                      )
                          : Image.file(
                        File(groupesFiltres[index].image),
                        width: 55,
                        height: 55,
                        fit: BoxFit.cover,
                      ),
                    ),

                    title: Text(groupesFiltres[index].nom),

                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          groupesFiltres[index].type,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(groupesFiltres[index].description),

                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.green,),
                            const SizedBox(width: 5),
                            Text(
                              "${groupesFiltres[index].nombreMembres} membres",
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ✏️ Modifier
                    trailing:   groupesAdmin.contains(groupesFiltres[index].id)
                     ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                               Row(
                               mainAxisSize: MainAxisSize.min,
                       children: [

                        // ✏️ Modifier
                        IconButton(
                          icon: Icon(Icons.edit,color: Colors.blue.shade700,),
                          onPressed: () async {
                            final groupe = groupesFiltres[index];

                            final nomController = TextEditingController(
                              text: groupe.nom,
                            );

                            final descriptionController = TextEditingController(
                              text: groupe.description,
                            );

                            final membresController = TextEditingController(
                              text: groupe.nombreMembres.toString(),
                            );
                            String typeSelectionne = groupe.type;

                            final resultat = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Modifier le groupe"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nomController,
                                        decoration: const InputDecoration(
                                          labelText: "Nom du groupe",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      TextField(
                                        controller: descriptionController,
                                        maxLines: 3,
                                        decoration: const InputDecoration(
                                          labelText: "Description",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),


                                      const SizedBox(height: 10),

                                      DropdownButtonFormField<String>(
                                        initialValue: typeSelectionne,
                                        decoration: const InputDecoration(
                                          labelText: "Type d'espace",
                                          border: OutlineInputBorder(),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: "Classe",
                                            child: Text("Classe"),
                                          ),
                                          DropdownMenuItem(
                                            value: "Club",
                                            child: Text("Club"),
                                          ),
                                          DropdownMenuItem(
                                            value: "Association",
                                            child: Text("Association"),
                                          ),
                                          DropdownMenuItem(
                                            value: "Projet",
                                            child: Text("Projet"),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            typeSelectionne = value;
                                          }
                                        },
                                      ),

                                      const SizedBox(height: 10),

                                      TextField(
                                        controller: membresController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: "Nombre de membres",
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text("Annuler"),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text("Enregistrer"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (resultat == true) {
                              final nouveauNom = nomController.text.trim();
                              final nouvelleDescription =
                              descriptionController.text.trim();

                              final nouveauNombre =
                              int.tryParse(membresController.text.trim());

                              if (nouveauNom.isEmpty ||
                                  nouvelleDescription.isEmpty ||
                                  nouveauNombre == null) {
                                return;
                              }

                              final db = DatabaseHelper();

                              await db.modifierGroupe(
                                groupe.id!,
                                nouveauNom,
                                nouvelleDescription,
                                nouveauNombre,
                                typeSelectionne,
                              );

                              setState(() {
                                groupe.nom = nouveauNom;
                                groupe.description = nouvelleDescription;
                                groupe.nombreMembres = nouveauNombre;
                                groupe.type = typeSelectionne;
                              });
                            }
                          },
                        ),

                        // 🗑️ Supprimer
                        IconButton(
                          icon: Icon(Icons.delete,color: Colors.red.shade700, ),
                          onPressed: () async {
                            final groupe = groupesFiltres[index];

                            final confirmation = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Supprimer le groupe"),
                                  content: const Text(
                                    "Voulez-vous vraiment supprimer ce groupe ? "
                                        "Ses publications et commentaires seront également supprimés.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Text("Annuler"),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, true);
                                      },
                                      child: const Text("Supprimer"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmation == true) {
                              final db = DatabaseHelper();

                              await db.supprimerGroupe(groupe.id!);

                              setState(() {
                                groupesFiltres.removeAt(index);
                                groupes.removeWhere(
                                      (g) => g.id == groupe.id,
                                );
                              });
                            }
                          },
                        ),
                      ],
                    ),
                      ],
                    )
                    : null,

                      onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GroupePage(
                            groupe: groupesFiltres[index],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}