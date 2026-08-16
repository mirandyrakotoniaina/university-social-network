import 'package:flutter/material.dart';
import '../models/groupe.dart';
import '../models/publication.dart';
import '../database/database_helper.dart';
import '../models/commentaire.dart';
import 'membres_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class GroupePage extends StatefulWidget {
  final Groupe groupe;

  const GroupePage({
    super.key,
    required this.groupe,
  });

  @override
  State<GroupePage> createState() => _GroupePageState();
}

class _GroupePageState extends State<GroupePage> {
  bool estMembre = false;
  String roleUtilisateur = "membre";
  bool chargementRole = true;
  String nomUtilisateurConnecte = "";
  bool estAdmin = false;


  @override
  void initState() {
    super.initState();
    chargerRole();
    verifierMembre();
    chargerUtilisateurConnecte();
  }

  Future<void> chargerUtilisateurConnecte() async {
    final db = DatabaseHelper();

    final nom = await db.getNomUtilisateurConnecte();

    if (!mounted) return;

    setState(() {
      nomUtilisateurConnecte = nom;
    });
  }


  Future<void> verifierMembre() async {
    final db = DatabaseHelper();

    final resultat = await db.estMembre(widget.groupe.id!);

    if (!mounted) return;

    setState(() {
      estMembre = resultat;
    });
  }

  Future<void> chargerRole() async {
    final db = DatabaseHelper();

    final role = await db.getRoleUtilisateur(widget.groupe.id!);

    setState(() {
      roleUtilisateur = role;
      chargementRole = false;
    });

    print("RÔLE DE L'UTILISATEUR : $roleUtilisateur");
  }
  Widget construireCommentaire({
    required Commentaire commentaire,
    required List<Commentaire> commentaires,
    required Publication publication,
    required DatabaseHelper db,
    required int niveau,
  }) {
    final reponses = getReponses(
      commentaires,
      commentaire.id!,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
    Padding(
    padding: EdgeInsets.only(
    left: niveau == 0
    ? 0
        : niveau == 1
      ? 20
      : 40,
    ),
    child: Container(
    margin: const EdgeInsets.only(
    bottom: 8,
    ),
    padding: const EdgeInsets.all(10),

            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.green.shade100,
                            child: Icon(
                              Icons.person,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 10),

                          Text(
                            commentaire.auteur,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          commentaire.texte,
                          softWrap: true,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              final controller = TextEditingController();

                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      "Répondre à ${commentaire.auteur}",
                                    ),
                                    content: TextField(
                                      controller: controller,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        hintText: "Écrivez votre réponse...",
                                        border: OutlineInputBorder(),
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
                                          final texte = controller.text.trim();

                                          if (texte.isEmpty) {
                                            return;
                                          }

                                          final nomUtilisateur =
                                          await db.getNomUtilisateurConnecte();

                                          final reponse = Commentaire(
                                            texte: texte,
                                            auteur: nomUtilisateur,
                                            dateCommentaire: DateTime.now(),
                                            publicationId: publication.id!,
                                            parentId: commentaire.id,
                                          );

                                          await db.insertCommentaire(reponse);

                                          publication.nombreCommentaires++;

                                          await db.updateCommentaires(
                                            publication.id!,
                                            publication.nombreCommentaires,
                                          );

                                          Navigator.pop(context);
                                          Navigator.pop(context);

                                          setState(() {});
                                        },
                                        child: const Text("Répondre"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text("Répondre"),
                          ),

                          if (commentaire.auteur == nomUtilisateurConnecte ||
                              roleUtilisateur == "admin") ...[
                            if (commentaire.auteur == nomUtilisateurConnecte)
                              IconButton(
                                icon: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue.shade600,
                                  size: 19,
                                ),
                                onPressed: () async {
                                  final controller = TextEditingController(
                                    text: commentaire.texte,
                                  );

                                  final nouveauTexte =
                                  await showDialog<String>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text(
                                          "Modifier le commentaire",
                                        ),
                                        content: TextField(
                                          controller: controller,
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            hintText:
                                            "Modifier votre commentaire...",
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
                                            onPressed: () {
                                              final texte =
                                              controller.text.trim();

                                              if (texte.isNotEmpty) {
                                                Navigator.pop(
                                                  context,
                                                  texte,
                                                );
                                              }
                                            },
                                            child: const Text("Enregistrer"),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (nouveauTexte != null) {
                                    final db = DatabaseHelper();

                                    await db.modifierCommentaire(
                                      commentaire.id!,
                                      nouveauTexte,
                                    );

                                    setState(() {
                                      commentaire.texte = nouveauTexte;
                                    });
                                  }
                                },
                              ),

                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                                size: 19,
                              ),
                              onPressed: () async {
                                final confirmation =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        "Supprimer le commentaire",
                                      ),
                                      content: const Text(
                                        "Voulez-vous vraiment supprimer le commentaire ?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              false,
                                            );
                                          },
                                          child: const Text("Annuler"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                              true,
                                            );
                                          },
                                          child: const Text("Supprimer"),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (confirmation == true) {
                                  final db = DatabaseHelper();

                                  await db.supprimerCommentaire(
                                    commentaire.id!,
                                  );

                                  publication.nombreCommentaires--;

                                  await db.updateCommentaires(
                                    publication.id!,
                                    publication.nombreCommentaires,
                                  );

                                  setState(() {
                                    commentaires.removeWhere(
                                          (c) => c.id == commentaire.id,
                                    );
                                  });
                                }
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    ),

          // Afficher les réponses


          ...reponses.map(
                (reponse) {
              return construireCommentaire(
                commentaire: reponse,
                commentaires: commentaires,
                publication: publication,
                db: db,
                niveau: niveau < 2 ? niveau + 1 : 2,
              );
            },
          ),
        ],
    );
  }
  List<Commentaire> getReponses(
      List<Commentaire> commentaires,
      int parentId,
      ) {
    return commentaires
        .where((commentaire) => commentaire.parentId == parentId)
        .toList();
  }




  Future<void> afficherCommentaires(Publication publication) async {
    final db = DatabaseHelper();
    final controller = TextEditingController();

    Future<void> ajouterCommentaire(
        BuildContext dialogContext,
        ) async {
      final texte = controller.text.trim();

      if (texte.isEmpty) {
        return;
      }


      final nomUtilisateur = await db.getNomUtilisateurConnecte();
      final commentaire = Commentaire(
        texte: texte,
        auteur: nomUtilisateur,
        dateCommentaire: DateTime.now(),
        publicationId: publication.id!,
        parentId: null,
      );

      await db.insertCommentaire(commentaire);

      publication.nombreCommentaires++;

      await db.updateCommentaires(
        publication.id!,
        publication.nombreCommentaires,
      );

      controller.clear();

      Navigator.pop(dialogContext);

      setState(() {});

      await afficherCommentaires(publication);
    }

    final commentaires = await db.getCommentaires(
      publication.id!,
    );

    final commentairesPrincipaux = commentaires
        .where((commentaire) => commentaire.parentId == null)
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Commentaires"),

          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Commentaires existants
                Flexible(
                  child: commentairesPrincipaux.isEmpty
                      ? const Text("Aucun commentaire")
                      : ListView.builder(
                    shrinkWrap: true,
                    itemCount: commentairesPrincipaux.length,
                    itemBuilder: (context, index) {
                      final commentaire =
                      commentairesPrincipaux[index];

                      return construireCommentaire(
                        commentaire: commentaire,
                        commentaires: commentaires,
                        publication: publication,
                        db: db,
                        niveau: 0,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 15),

                // Champ pour écrire un commentaire
                TextField(
                  controller: controller,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: "Écrire un commentaire...",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                // Bouton pour publier
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      ajouterCommentaire(context);
                    },
                    child: const Text("Publier"),
                  ),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }

  Future<void> afficherMembres() async {
    final db = DatabaseHelper();

    final membres = await db.getMembresGroupe(
      widget.groupe.id!,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Membres du groupe"),
          content: SizedBox(
            width: double.maxFinite,
            child: membres.isEmpty
                ? const Text("Aucun membre")
                : ListView.builder(
              shrinkWrap: true,
              itemCount: membres.length,
              itemBuilder: (context, index) {
                final membre = membres[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(membre.nom),
                  subtitle: Text(membre.email),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(widget.groupe.nom, style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Text(
                widget.groupe.description,
                textAlign: TextAlign.center,
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  "${widget.groupe.nombreMembres} membres",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),


            if (estMembre)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MembresPage(
                        groupeId: widget.groupe.id!,
                        nomGroupe: widget.groupe.nom,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  roleUtilisateur == "admin"
                      ? Icons.manage_accounts
                      : Icons.people,
                ),
                label: Text(
                  roleUtilisateur == "admin"
                      ? "Gérer les membres"
                      : "Voir les membres",
                ),
                style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),


               ),
               ),
              ),

            const SizedBox(height: 15),

            ElevatedButton.icon(
              onPressed: () async {
                final db = DatabaseHelper();

                if (estMembre) {
                  try {
                    await db.quitterGroupe(widget.groupe.id!);

                    if (!mounted) return;

                    setState(() {
                      estMembre = false;
                      widget.groupe.nombreMembres--;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Vous avez quitté le groupe."),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst("Exception: ", ""),
                        ),
                      ),
                    );
                  }
                } else {
                  await db.rejoindreGroupe(widget.groupe.id!);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Votre demande a été envoyée à l'administrateur.",
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),


              icon: Icon(
                estMembre ? Icons.exit_to_app : Icons.group_add,
              ),
              label: Text(
                estMembre
                    ? "Quitter le groupe"
                    : "Rejoindre le groupe",
              ),
            ),


            const SizedBox(height: 8),

            Text(
              estMembre
                  ? "Vous êtes membre de ce groupe"
                  : "Vous n'êtes pas membre de ce groupe",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            const SizedBox(height: 10),

            const SizedBox(height: 20),

            Row(
              children: [
                Icon(
                  Icons.article,
                  color: Colors.green.shade700,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  "Publications",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            if (estMembre)
              ElevatedButton.icon(
                onPressed: () {
                  final controller = TextEditingController();
                  File? imageChoisie;

                  showDialog(
                    context: context,
                    builder: (context) {
                      File? imageChoisie;
                      final controller = TextEditingController();

                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            title: const Text("Nouvelle publication"),

                            content: SizedBox(
                              width: 300,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: controller,
                                      maxLines: 4,
                                      decoration: const InputDecoration(
                                        hintText: "Écrivez votre publication...",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),

                                    const SizedBox(height: 15),

                                    if (imageChoisie != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          imageChoisie!,
                                          width: 250,
                                          height: 180,
                                          fit: BoxFit.cover,
                                        ),
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
                                      label: const Text("Choisir une image"),
                                    ),
                                  ],
                                ),
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
                                  final texte = controller.text.trim();

                                  if (texte.isEmpty && imageChoisie == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Ajoutez une description ou une image.",
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final db = DatabaseHelper();

                                  final nomUtilisateur =
                                  await db.getNomUtilisateurConnecte();

                                  final publication = Publication(
                                    contenuMessage: texte,
                                    auteur: nomUtilisateur,
                                    datePublication: DateTime.now(),
                                    nombreLikes: 0,
                                    nombreCommentaires: 0,
                                    aime: false,
                                    image: imageChoisie?.path,
                                  );

                                  final publicationId =
                                  await db.insertPublication(
                                    publication,
                                    widget.groupe.id!,
                                  );

                                  final nouvellePublication = Publication(
                                    id: publicationId,
                                    contenuMessage: publication.contenuMessage,
                                    auteur: publication.auteur,
                                    datePublication: publication.datePublication,
                                    nombreLikes: publication.nombreLikes,
                                    nombreCommentaires:
                                    publication.nombreCommentaires,
                                    aime: publication.aime,
                                    image: publication.image,
                                  );

                                  setState(() {
                                    widget.groupe.publications.add(
                                      nouvellePublication,
                                    );
                                  });

                                  Navigator.pop(context);
                                },
                                child: const Text("Publier"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },

                icon: const Icon(Icons.add),
                label: const Text("Ajouter une publication"),

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            const SizedBox(height: 10),


        Expanded(
          child: estMembre
          ? ListView.builder(
            itemCount: widget.groupe.publications.length,
            itemBuilder: (context, index) {
              final publication = widget.groupe.publications[index];

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
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        publication.auteur,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(publication.contenuMessage),

                      const SizedBox(height: 12),
                      if (publication.image != null &&
                          publication.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(publication.image!),
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          // ❤️ Like
                          IconButton(
                            onPressed: () async {
                              setState(() {
                                if (publication.aime) {
                                  publication.nombreLikes--;
                                  publication.aime = false;
                                } else {
                                  publication.nombreLikes++;
                                  publication.aime = true;
                                }
                              });

                              final db = DatabaseHelper();

                              await db.updateLikes(
                                publication.id!,
                                publication.nombreLikes,
                                publication.aime,
                              );
                            },
                            icon: Icon(
                              publication.aime
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: publication.aime
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),

                          Text("${publication.nombreLikes}"),

                          const SizedBox(width: 20),

                          // 💬 Commentaires
                          IconButton(
                            onPressed: () {
                              afficherCommentaires(publication);
                            },
                              icon: Icon(
                                Icons.comment,
                                color: Colors.green.shade700,
                              ),
                          ),

                          Text("${publication.nombreCommentaires}"),

                          const Spacer(),

                          if (publication.auteur == nomUtilisateurConnecte ||
                              roleUtilisateur == "admin") ...[

                          // ✏️ Modifier
                            if (publication.auteur == nomUtilisateurConnecte)
                          IconButton(
                            onPressed: () async {
                              final controller = TextEditingController(
                                text: publication.contenuMessage,
                              );

                              final nouveauTexte = await showDialog<String>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Modifier la publication",
                                    ),
                                    content: TextField(
                                      controller: controller,
                                      maxLines: 4,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText:
                                        "Modifier votre publication...",
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
                                        onPressed: () {
                                          final texte =
                                          controller.text.trim();

                                          if (texte.isNotEmpty) {
                                            Navigator.pop(
                                              context,
                                              texte,
                                            );
                                          }
                                        },
                                        child: const Text("Enregistrer"),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (nouveauTexte != null) {
                                final db = DatabaseHelper();

                                await db.modifierPublication(
                                  publication.id!,
                                  nouveauTexte,
                                );

                                setState(() {
                                  publication.contenuMessage =
                                      nouveauTexte;
                                });
                              }
                            },
                            icon: Icon(Icons.edit, color: Colors.blue.shade700,),
                          ),

                          // 🗑️ Supprimer
                          IconButton(
                            onPressed: () async {
                              final confirmation =
                              await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text(
                                      "Supprimer la publication",
                                    ),
                                    content: const Text(
                                      "Voulez-vous vraiment supprimer cette publication ?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                            false,
                                          );
                                        },
                                        child: const Text("Annuler"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(
                                            context,
                                            true,
                                          );
                                        },
                                        child: const Text("Supprimer"),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmation == true) {
                                final db = DatabaseHelper();

                                await db.supprimerPublication(
                                  publication.id!,
                                );

                                setState(() {
                                  widget.groupe.publications
                                      .removeAt(index);
                                });
                              }
                            },
                            icon: Icon(Icons.delete,color: Colors.red.shade700,),
                          ),
              ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
        )
            : const Center(
          child: Text(
            "🔒 Vous devez rejoindre ce groupe\n"
                "pour voir les publications.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ),



          ],
        ),
      ),
    );
  }
}