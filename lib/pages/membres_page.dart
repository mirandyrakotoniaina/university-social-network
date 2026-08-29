import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/utilisateurs.dart';

class MembresPage extends StatefulWidget {
  final int groupeId;
  final String nomGroupe;

  const MembresPage({
    super.key,
    required this.groupeId,
    required this.nomGroupe,
  });

  @override
  State<MembresPage> createState() => _MembresPageState();
}

class _MembresPageState extends State<MembresPage> {
  List<Utilisateur> membres = [];
  List<Utilisateur> utilisateurs = [];
  List<Utilisateur> demandes = [];

  bool chargement = true;
  String roleUtilisateur = "membre";


  @override
  void initState() {
    super.initState();
    chargerMembres();
    chargerRole();
    testerDemandes();
  }


  Future<void> testerDemandes() async {
    final db = DatabaseHelper();

    final resultat = await db.getDemandesMembres(widget.groupeId);

    print("DEMANDES EN ATTENTE : $resultat");

    if (!mounted) return;

    setState(() {
      demandes = resultat;
    });
  }

  Future<void> chargerRole() async {
    final db = DatabaseHelper();

    final role = await db.getRoleUtilisateur(widget.groupeId);

    if (!mounted) return;

    setState(() {
      roleUtilisateur = role;
    });
  }

  Future<void> chargerMembres() async {
    final db = DatabaseHelper();

    final resultat =
    await db.getMembresGroupe(widget.groupeId);

    setState(() {
      membres = resultat;
      chargement = false;
    });
  }

  // Ajouter un membre
  Future<void> ajouterMembre() async {
    print("======================================");
    print("👤 BOUTON AJOUTER MEMBRE CLIQUÉ");
    final db = DatabaseHelper();

    print("📥 Chargement des utilisateurs...");

    final tousLesUtilisateurs =
    await db.getTousLesUtilisateurs();

    print("👥 UTILISATEURS TROUVÉS : ${tousLesUtilisateurs.length}");
    print("👥 UTILISATEURS : $tousLesUtilisateurs");
    print("TOUS LES UTILISATEURS : $tousLesUtilisateurs");

    // Ne garder que les utilisateurs qui ne sont pas encore membres
    final disponibles = tousLesUtilisateurs.where((utilisateur) {
      return !membres.any(
            (membre) => membre.id == utilisateur.id,
      );
    }).toList();
    print("UTILISATEURS DISPONIBLES : $disponibles");

    if (!mounted) return;

    if (disponibles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tous les utilisateurs sont déjà membres."),
        ),
      );
      return;
    }

    final utilisateurChoisi =
    await showDialog<Utilisateur>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Ajouter un membre"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: disponibles.length,
              itemBuilder: (context, index) {
                final utilisateur = disponibles[index];

                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(utilisateur.nom),
                  subtitle: Text(utilisateur.email),
                  onTap: () {
                    Navigator.pop(
                      context,
                      utilisateur,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    if (utilisateurChoisi == null) return;

    await db.ajouterUtilisateurAuGroupe(
      utilisateurChoisi.email,
      widget.groupeId,
    );

    await chargerMembres();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${utilisateurChoisi.nom} a été ajouté au groupe.",
        ),
      ),
    );
  }

  // Retirer un membre
  Future<void> retirerMembre(Utilisateur membre) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Retirer le membre"),
          content: Text(
            "Voulez-vous retirer ${membre.nom} du groupe ?",
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
              child: const Text("Retirer"),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    final db = DatabaseHelper();

    await db.retirerUtilisateurDuGroupe(
      membre.email,
      widget.groupeId,
    );

    await chargerMembres();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${membre.nom} a été retiré du groupe.",
        ),
      ),
    );
  }

  Future<void> transfererResponsabilite(Utilisateur membre) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Changer de responsable"),
          content: Text(
            "Voulez-vous vraiment faire de ${membre.nom} "
                "le nouveau responsable du groupe ?",
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
              child: const Text("Confirmer"),
            ),
          ],
        );
      },
    );

    if (confirmation != true) return;

    final db = DatabaseHelper();

    await db.transfererAdmin(
      widget.groupeId,
      membre.email,
    );

    await chargerMembres();
    await chargerRole();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${membre.nom} est maintenant le responsable du groupe.",
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        title: Text(
          "Membres - ${widget.nomGroupe}",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (roleUtilisateur == "admin")
            IconButton(
              onPressed: ajouterMembre,
              icon: const Icon(Icons.person_add),
              tooltip: "Ajouter un membre",
            ),
        ],
      ),

        body: chargement
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                8,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${membres.length} membre${membres.length > 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (roleUtilisateur == "admin" && demandes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.pending_actions,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Demandes en attente (${demandes.length})",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            if (roleUtilisateur == "admin" && demandes.isNotEmpty)
              ...demandes.map(
                    (demande) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Icon(
                          Icons.person,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      title: Text(
                        demande.nom,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(demande.email),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.check,
                              color: Colors.green,
                            ),
                            tooltip: "Accepter",
                            onPressed: () async {
                              final db = DatabaseHelper();

                              await db.accepterDemandeMembre(
                                widget.groupeId,
                                demande.email,
                              );

                              await testerDemandes();
                              await chargerMembres();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${demande.nom} a été accepté dans le groupe.",
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                            ),
                            tooltip: "Refuser",
                            onPressed: () async {
                              final db = DatabaseHelper();

                              await db.refuserDemandeMembre(
                                widget.groupeId,
                                demande.email,
                              );

                              await testerDemandes();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "La demande de ${demande.nom} a été refusée.",
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

    Expanded(
    child: membres.isEmpty
    ? const Center(
    child: Text("Aucun membre"),
    )
        : ListView.builder(
    itemCount: membres.length,
    itemBuilder: (context, index) {
    final membre = membres[index];

    return Card(
    color: Colors.white,
    elevation: 2,
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
    contentPadding: const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
    ),

    leading: CircleAvatar(
    backgroundColor: Colors.green.shade100,
    child: Icon(
    membre.role == "admin"
    ? Icons.admin_panel_settings
        : Icons.person,
    color: Colors.green.shade700,
    ),
    ),

    title: Text(
    membre.nom,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
    ),
    ),

    subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const SizedBox(height: 4),
    Text(membre.email),
    const SizedBox(height: 6),

    Text(
    membre.role == "admin"
    ? "Administrateur / Responsable"
        : "Membre",
    style: TextStyle(
    fontWeight: FontWeight.bold,
    color: membre.role == "admin"
    ? Colors.green.shade700
        : Colors.grey.shade600,
    ),
    ),
    ],
    ),

    trailing: membre.role == "admin"
    ? Icon(
    Icons.verified,
    color: Colors.green.shade700,
    )
        : roleUtilisateur == "admin"
    ? Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    IconButton(
    icon: Icon(
    Icons.admin_panel_settings,
    color: Colors.green.shade700,
    ),
    tooltip: "Nommer admin",
    onPressed: () {
    transfererResponsabilite(membre);
    },
    ),

    IconButton(
    icon: const Icon(
    Icons.delete_outline,
    color: Colors.red,
    ),
    tooltip: "Retirer",
    onPressed: () {
    retirerMembre(membre);
    },
    ),
    ],
    )
        : null,
    ),
    );
    },
    ),
    )
    ],
    ),
        );
  }
}