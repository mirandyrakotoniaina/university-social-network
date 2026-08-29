
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/publication.dart';
import '../models/commentaire.dart';
import '../models/groupe.dart';
import '../models/utilisateurs.dart';

class DatabaseHelper {
final SupabaseClient supabase = Supabase.instance.client;

// ============================================================
// UTILISATEUR CONNECTÉ / UTILISATEUR DE TEST
// ============================================================

static String? utilisateurConnecteEmail;

// ID du profil actuellement utilisé
static String? utilisateurConnecteId;

// ------------------------------------------------------------
// CHANGER D'UTILISATEUR
// ------------------------------------------------------------

Future<void> changerUtilisateur(String email) async {
utilisateurConnecteEmail = email;

final profil = await supabase
    .from('profiles')
    .select('id, nom, email')
    .eq('email', email)
    .maybeSingle();

if (profil != null) {
utilisateurConnecteId = profil['id'] as String?;
} else {
utilisateurConnecteId = null;
}

print("======================================");
print("👤 UTILISATEUR CHANGÉ");
print("Nom : ${profil?['nom']}");
print("Email : $email");
print("ID : $utilisateurConnecteId");
print("======================================");
}

// ============================================================
// PROFIL UTILISATEUR
// ============================================================

Future<Map<String, dynamic>> getProfilUtilisateurActuel() async {
String? email = utilisateurConnecteEmail;

// Si aucun compte de test n'est sélectionné,
// utiliser le compte Supabase Auth.
if (email == null) {
final user = supabase.auth.currentUser;

if (user != null) {
email = user.email;
utilisateurConnecteId = user.id;
}
}

if (email == null) {
throw Exception("Aucun utilisateur connecté.");
}

final profil = await supabase
    .from('profiles')
    .select('id, nom, email, created_at')
    .eq('email', email)
    .single();

utilisateurConnecteId = profil['id'] as String?;

return profil;
}

// ------------------------------------------------------------
// UTILISATEUR ACTUEL
// ------------------------------------------------------------

Future<Utilisateur> getUtilisateurActuel() async {
final profil = await getProfilUtilisateurActuel();

return Utilisateur(
id: profil['id'] as String?,
nom: profil['nom'] as String? ?? 'Utilisateur',
email: profil['email'] as String,
);
}

// ------------------------------------------------------------
// NOM UTILISATEUR CONNECTÉ
// ------------------------------------------------------------

Future<String> getNomUtilisateurConnecte() async {
final profil = await getProfilUtilisateurActuel();

return profil['nom'] as String? ?? 'Utilisateur';
}

// ============================================================
// UTILISATEURS DE TEST
// ============================================================

Future<void> creerUtilisateursTest() async {
final utilisateurs = [
{
'nom': 'Mirandy',
'email': 'mirandy@gmail.com',
},
{
'nom': 'Alice',
'email': 'alice@gmail.com',
},
{
'nom': 'Bob',
'email': 'bob@gmail.com',
},
];

for (final utilisateur in utilisateurs) {
final existe = await supabase
    .from('profiles')
    .select('id')
    .eq('email', utilisateur['email']!)
    .maybeSingle();

if (existe == null) {
await supabase.from('profiles').insert(utilisateur);

print(
"✅ Utilisateur créé : ${utilisateur['email']}",
);
}
}
}

Future<List<Utilisateur>> getTousLesUtilisateurs() async {
final resultats = await supabase
    .from('profiles')
    .select('id, nom, email, created_at')
    .order('id', ascending: true);

return resultats.map<Utilisateur>((profil) {
return Utilisateur(
id: profil['id'] as String?,
nom: profil['nom'] as String? ?? 'Utilisateur',
email: profil['email'] as String,
);
}).toList();
}

// ============================================================
// GROUPES
//
// TABLE groupes :
// id              int8
// nom             text
// description     text
// type            text
// image            text
// created_at       timestamptz
// nombreMembres    int8
// ============================================================

Future<int> insertGroupe(Groupe groupe) async {
final profil = await getProfilUtilisateurActuel();

final profileId = profil['id'] as String;

// Création du groupe
final result = await supabase
    .from('groupes')
    .insert({
'nom': groupe.nom,
'description': groupe.description,
'type': groupe.type,
'image': groupe.image,
'nombreMembres': 1,
})
    .select('id')
    .single();

final groupeId = result['id'] as int;

// Le créateur devient automatiquement administrateur.
await supabase.from('membres_groupes').insert({
'groupe_id': groupeId,
'utilisateur_id': profileId,
'role': 'admin',
'statut': 'accepte',
});

print("======================================");
print("✅ GROUPE CRÉÉ");
print("Groupe ID : $groupeId");
print("Créateur : $profileId");
print("======================================");

return groupeId;
}

// ------------------------------------------------------------
// RÉCUPÉRER LES GROUPES
// ------------------------------------------------------------

Future<List<Groupe>> getGroupes() async {
print("======================================");
print("🔎 RÉCUPÉRATION DES GROUPES");

final resultats = await supabase
    .from('groupes')
    .select()
    .order('id', ascending: false);

print(
"📦 Nombre total de groupes : ${resultats.length}",
);

final List<Groupe> groupes = [];

for (final map in resultats) {
final groupeId = map['id'] as int;

final nombreMembres =
await getNombreMembresGroupe(groupeId);

print(
"📌 Groupe : ${map['nom']} | "
"ID : $groupeId | "
"Membres : $nombreMembres",
);

// Mettre à jour le compteur enregistré dans groupes.
if (map['nombreMembres'] != nombreMembres) {
await supabase
    .from('groupes')
    .update({
'nombreMembres': nombreMembres,
})
    .eq('id', groupeId);
}

final publications =
await getPublications(groupeId);

groupes.add(
Groupe(
id: groupeId,
nom: map['nom'] as String? ?? '',
description:
map['description'] as String? ?? '',
nombreMembres: nombreMembres,
image: map['image'] as String? ?? 'default.png',
type: map['type'] as String? ?? 'Classe',
publications: publications,
),
);
}

print(
"✅ ${groupes.length} groupe(s) récupéré(s)",
);
print("======================================");

return groupes;
}

  Future<List<String>> getTypesEspaces() async {
    try {
      final resultats = await supabase
          .from('types_espace')
          .select('*');

      print("📦 TYPES BRUTS SUPABASE : $resultats");
      print("📊 NOMBRE DE TYPES : ${resultats.length}");

      return resultats
          .map<String>((element) => element['nom'] as String)
          .toList();
    } catch (e) {
      print("❌ ERREUR GET TYPES : $e");
      rethrow;
    }
  }

  Future<void> ajouterTypeEspace(String nom) async {
    await supabase
        .from('types_espace')
        .insert({
      'nom': nom,
    });

    print("✅ TYPE D'ESPACE AJOUTÉ : $nom");
  }


// ============================================================
// MEMBRES DU GROUPE
//
// TABLE membres_groupes :
// id              int8
// groupe_id       int8
// utilisateur_id  uuid
// role            text
// statut          text
// ============================================================

Future<int> getNombreMembresGroupe(
int groupeId,
) async {
final result = await supabase
    .from('membres_groupes')
    .select('id')
    .eq('groupe_id', groupeId)
    .eq('statut', 'accepte');

return result.length;
}

// ------------------------------------------------------------
// RÉCUPÉRER LES MEMBRES ACCEPTÉS
// ------------------------------------------------------------

Future<List<Utilisateur>> getMembresGroupe(
int groupeId,
) async {
print("======================================");
print("👥 CHARGEMENT DES MEMBRES");
print("Groupe ID : $groupeId");

final membresSupabase = await supabase
    .from('membres_groupes')
    .select('id, utilisateur_id, role, statut')
    .eq('groupe_id', groupeId)
    .eq('statut', 'accepte');

print(
"📦 Membres Supabase : $membresSupabase",
);

final List<Utilisateur> membres = [];

for (final membre in membresSupabase) {
final profileId =
membre['utilisateur_id'] as String;

final profil = await supabase
    .from('profiles')
    .select('id, nom, email')
    .eq('id', profileId)
    .single();

membres.add(
Utilisateur(
id: profil['id'] as String?,
nom:
profil['nom'] as String? ?? 'Utilisateur',
email: profil['email'] as String,
role:
membre['role'] as String? ?? 'membre',
),
);
}

print(
"✅ ${membres.length} membre(s) chargé(s)",
);

return membres;
}

// ------------------------------------------------------------
// AUTRES MEMBRES
// ------------------------------------------------------------

Future<List<Utilisateur>> getAutresMembres(
int groupeId,
) async {
final profilActuel =
await getProfilUtilisateurActuel();

final profileIdActuel =
profilActuel['id'] as String;

final resultats = await supabase
    .from('membres_groupes')
    .select(
'id, utilisateur_id, role, statut',
)
    .eq('groupe_id', groupeId)
    .eq('statut', 'accepte')
    .neq(
'utilisateur_id',
profileIdActuel,
);

final List<Utilisateur> membres = [];

for (final membre in resultats) {
final profileId =
membre['utilisateur_id'] as String;

final profil = await supabase
    .from('profiles')
    .select('id, nom, email')
    .eq('id', profileId)
    .single();

membres.add(
Utilisateur(
id: profil['id'] as String?,
nom:
profil['nom'] as String? ?? 'Utilisateur',
email: profil['email'] as String,
role:
membre['role'] as String? ?? 'membre',
),
);
}

return membres;
}

// ============================================================
// REJOINDRE UN GROUPE
// ============================================================

Future<void> rejoindreGroupe(
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

print("======================================");
print("📩 DEMANDE POUR REJOINDRE LE GROUPE");
print("Utilisateur : $profileId");
print("Groupe : $groupeId");

// Chercher UNE éventuelle association existante.
final existantes = await supabase
    .from('membres_groupes')
    .select(
'id, groupe_id, utilisateur_id, role, statut',
)
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId);

// S'il y a déjà une demande ou une adhésion,
// ne pas créer une deuxième ligne.
if (existantes.isNotEmpty) {
print(
"⚠️ Association déjà existante : $existantes",
);
return;
}

await supabase.from('membres_groupes').insert({
'groupe_id': groupeId,
'utilisateur_id': profileId,
'role': 'membre',
'statut': 'en_attente',
});

print("✅ DEMANDE ENVOYÉE");
print("======================================");
}

// ============================================================
// EST MEMBRE ?
// ============================================================

Future<bool> estMembre(
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final resultat = await supabase
    .from('membres_groupes')
    .select('id')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .eq('statut', 'accepte')
    .limit(1);

return resultat.isNotEmpty;
}

// ============================================================
// STATUT DE LA DEMANDE
// ============================================================

Future<String> getStatutGroupe(
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final resultat = await supabase
    .from('membres_groupes')
    .select('statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .maybeSingle();

if (resultat == null) {
return 'aucun';
}

return resultat['statut'] as String? ?? 'aucun';
}

// ============================================================
// ROLE UTILISATEUR
// ============================================================

Future<String> getRoleUtilisateur(
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final resultat = await supabase
    .from('membres_groupes')
    .select('role, statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .eq('statut', 'accepte')
    .maybeSingle();

if (resultat == null) {
return 'aucun';
}

return resultat['role'] as String? ?? 'membre';
}

// ============================================================
// DEMANDES DE MEMBRES
// ============================================================

  Future<List<Utilisateur>> getDemandesMembres(
      int groupeId,
      ) async {
    print("======================================");
    print("📩 RECHERCHE DES DEMANDES");
    print("GROUPE ID : $groupeId");

    final toutesLesLignes = await supabase
        .from('membres_groupes')
        .select('id, groupe_id, utilisateur_id, role, statut')
        .eq('groupe_id', groupeId);

    print("📦 TOUTES LES LIGNES DU GROUPE : $toutesLesLignes");

    final demandesSupabase = await supabase
        .from('membres_groupes')
        .select('id, groupe_id, utilisateur_id, role, statut')
        .eq('groupe_id', groupeId)
        .eq('statut', 'en_attente');

    print("📩 LIGNES EN ATTENTE : $demandesSupabase");

    final List<Utilisateur> demandes = [];

    for (final demande in demandesSupabase) {
      final profileId = demande['utilisateur_id'] as String;

      final profil = await supabase
          .from('profiles')
          .select('id, nom, email')
          .eq('id', profileId)
          .single();

      demandes.add(
        Utilisateur(
          id: profil['id'] as String?,
          nom: profil['nom'] as String? ?? 'Utilisateur',
          email: profil['email'] as String,
          role: demande['role'] as String? ?? 'membre',
        ),
      );
    }

    print("📩 DEMANDES FINALES : $demandes");
    print("======================================");

    return demandes;
  }

// ============================================================
// ACCEPTER UNE DEMANDE
// ============================================================


  Future<void> accepterDemandeMembre(
      int groupeId,
      String email,
      ) async {
    print("======================================");
    print("📩 ACCEPTATION DEMANDE");
    print("Groupe : $groupeId");
    print("Email : $email");

    // 1️⃣ Récupérer le profil avec son email
    final profil = await supabase
        .from('profiles')
        .select('id, nom, email')
        .eq('email', email)
        .maybeSingle();

    if (profil == null) {
      throw Exception("Utilisateur introuvable.");
    }

    final utilisateurId = profil['id'] as String;

    print("👤 ID UTILISATEUR : $utilisateurId");

    // 2️⃣ Récupérer la demande correspondant
    // au groupe ET à l'utilisateur
    final demande = await supabase
        .from('membres_groupes')
        .select('id, groupe_id, utilisateur_id, role, statut')
        .eq('groupe_id', groupeId)
        .eq('utilisateur_id', utilisateurId)
        .eq('statut', 'en_attente')
        .maybeSingle();

    if (demande == null) {
      throw Exception(
        "Aucune demande en attente pour cet utilisateur dans ce groupe.",
      );
    }

    final demandeId = demande['id'] as int;

    print("🆔 ID DE LA DEMANDE : $demandeId");
    print("📋 DEMANDE AVANT : $demande");

    // 3️⃣ Accepter la demande
    final resultatUpdate = await supabase
        .from('membres_groupes')
        .update({
      'statut': 'accepte',
    })
        .eq('id', demandeId)
        .select();

    print("📦 RÉSULTAT DE L'UPDATE : $resultatUpdate");

    // 4️⃣ Vérifier que la modification a bien été effectuée
    final verification = await supabase
        .from('membres_groupes')
        .select('id, groupe_id, utilisateur_id, role, statut')
        .eq('id', demandeId)
        .maybeSingle();

    print("📋 DEMANDE APRÈS : $verification");

    if (verification == null) {
      throw Exception(
        "Impossible de retrouver la demande après modification.",
      );
    }

    if (verification['statut'] != 'accepte') {
      throw Exception(
        "La demande n'a pas été acceptée. "
            "Statut actuel : ${verification['statut']}",
      );
    }

    print("🎉 DEMANDE ACCEPTÉE AVEC SUCCÈS");
    print("======================================");
  }



// ============================================================
// REFUSER UNE DEMANDE
// ============================================================

Future<void> refuserDemandeMembre(
int groupeId,
String email,
) async {
final profil = await supabase
    .from('profiles')
    .select('id')
    .eq('email', email)
    .single();

final profileId =
profil['id'] as String;

await supabase
    .from('membres_groupes')
    .delete()
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .eq('statut', 'en_attente');

print(
"❌ Demande de $email refusée",
);
}

// ============================================================
// AJOUTER DIRECTEMENT UN UTILISATEUR
// ============================================================

Future<void> ajouterUtilisateurAuGroupe(
String email,
int groupeId,
) async {
final profil = await supabase
    .from('profiles')
    .select('id, nom, email')
    .eq('email', email)
    .single();

final profileId =
profil['id'] as String;

final existantes = await supabase
    .from('membres_groupes')
    .select(
'id, statut',
)
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId);

if (existantes.isNotEmpty) {
throw Exception(
"Cet utilisateur est déjà membre ou possède déjà une demande.",
);
}

await supabase.from('membres_groupes').insert({
'groupe_id': groupeId,
'utilisateur_id': profileId,
'role': 'membre',
'statut': 'accepte',
});

final nombreMembres =
await getNombreMembresGroupe(groupeId);

await supabase
    .from('groupes')
    .update({
'nombreMembres': nombreMembres,
})
    .eq('id', groupeId);

print(
"✅ Utilisateur $email ajouté au groupe $groupeId",
);
}

// ============================================================
// RETIRER UN UTILISATEUR DU GROUPE
// ============================================================

Future<void> retirerUtilisateurDuGroupe(
String email,
int groupeId,
) async {
final profil = await supabase
    .from('profiles')
    .select('id')
    .eq('email', email)
    .single();

final profileId =
profil['id'] as String;

await supabase
    .from('membres_groupes')
    .delete()
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId);

final nombreMembres =
await getNombreMembresGroupe(groupeId);

await supabase
    .from('groupes')
    .update({
'nombreMembres': nombreMembres,
})
    .eq('id', groupeId);

print(
"✅ $email retiré du groupe $groupeId",
);
}

// ============================================================
// QUITTER UN GROUPE
// ============================================================

Future<void> quitterGroupe(
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final membre = await supabase
    .from('membres_groupes')
    .select('id, role, statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .eq('statut', 'accepte')
    .maybeSingle();

if (membre == null) {
throw Exception(
"Vous n'êtes pas membre de ce groupe.",
);
}

final role =
membre['role'] as String? ?? 'membre';

// L'administrateur ne peut pas quitter
// tant qu'il n'a pas transféré son rôle.
if (role == 'admin') {
final autresMembres =
await getAutresMembres(groupeId);

if (autresMembres.isEmpty) {
throw Exception(
"Vous êtes le seul membre du groupe. "
"Vous devez supprimer le groupe.",
);
}

throw Exception(
"Vous êtes administrateur. "
"Vous devez nommer un nouveau responsable avant de quitter.",
);
}

await supabase
    .from('membres_groupes')
    .delete()
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId);

final nombreMembres =
await getNombreMembresGroupe(groupeId);

await supabase
    .from('groupes')
    .update({
'nombreMembres': nombreMembres,
})
    .eq('id', groupeId);

print(
"✅ ${profil['email']} a quitté le groupe $groupeId",
);
}

// ============================================================
// TRANSFÉRER ADMIN
// ============================================================

Future<void> transfererAdmin(
int groupeId,
String nouvelAdminEmail,
) async {
final profilActuel =
await getProfilUtilisateurActuel();

final ancienAdminId =
profilActuel['id'] as String;

// Vérifier que l'utilisateur actuel est admin.
final ancienAdmin = await supabase
    .from('membres_groupes')
    .select('id, role, statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', ancienAdminId)
    .eq('statut', 'accepte')
    .maybeSingle();

if (ancienAdmin == null ||
ancienAdmin['role'] != 'admin') {
throw Exception(
"Seul l'administrateur peut transférer le rôle.",
);
}

final nouveauProfil = await supabase
    .from('profiles')
    .select('id')
    .eq('email', nouvelAdminEmail)
    .single();

final nouvelAdminId =
nouveauProfil['id'] as String;

// Vérifier que le nouveau admin est membre.
final membre = await supabase
    .from('membres_groupes')
    .select('id, role, statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', nouvelAdminId)
    .eq('statut', 'accepte')
    .maybeSingle();

if (membre == null) {
throw Exception(
"Cette personne n'est pas membre du groupe.",
);
}

// Ancien admin devient membre.
await supabase
    .from('membres_groupes')
    .update({
'role': 'membre',
})
    .eq('id', ancienAdmin['id']);

// Nouveau admin.
await supabase
    .from('membres_groupes')
    .update({
'role': 'admin',
})
    .eq('id', membre['id']);

print(
"✅ Administration transférée à $nouvelAdminEmail",
);
}

// ============================================================
// MODIFIER GROUPE
// ============================================================

Future<void> modifierGroupe(
int groupeId,
String nouveauNom,
String nouvelleDescription,
int nouveauNombreMembres,
String nouveauType,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final membre = await supabase
    .from('membres_groupes')
    .select('role, statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .eq('statut', 'accepte')
    .maybeSingle();

if (membre == null ||
membre['role'] != 'admin') {
throw Exception(
"Seul l'administrateur peut modifier ce groupe.",
);
}

await supabase
    .from('groupes')
    .update({
'nom': nouveauNom,
'description': nouvelleDescription,
'nombreMembres': nouveauNombreMembres,
'type': nouveauType,
})
    .eq('id', groupeId);

print(
"✅ Groupe $groupeId modifié",
);
}

// ============================================================
// SUPPRIMER GROUPE
// ============================================================

Future<void> supprimerGroupe(
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final membre = await supabase
    .from('membres_groupes')
    .select('role, statut')
    .eq('groupe_id', groupeId)
    .eq('utilisateur_id', profileId)
    .eq('statut', 'accepte')
    .maybeSingle();

if (membre == null ||
membre['role'] != 'admin') {
throw Exception(
"Seul l'administrateur peut supprimer ce groupe.",
);
}

// ----------------------------------------------------------
// Publications du groupe
// ----------------------------------------------------------

final publications = await supabase
    .from('publications')
    .select('id')
    .eq('groupe_id', groupeId);

for (final publication in publications) {
final publicationId =
publication['id'] as int;

// Images publication
await supabase
    .from('publication_images')
    .delete()
    .eq(
'publication_id',
publicationId,
);

// Likes publication
await supabase
    .from('likes_publications')
    .delete()
    .eq(
'publication_id',
publicationId,
);

// Commentaires
final commentaires = await supabase
    .from('commentaires')
    .select('id')
    .eq(
'publication_id',
publicationId,
);

for (final commentaire in commentaires) {
final commentaireId =
commentaire['id'] as int;

await supabase
    .from('likes_commentaires')
    .delete()
    .eq(
'commentaire_id',
commentaireId,
);
}

await supabase
    .from('commentaires')
    .delete()
    .eq(
'publication_id',
publicationId,
);
}

// Supprimer publications
await supabase
    .from('publications')
    .delete()
    .eq(
'groupe_id',
groupeId,
);

// Membres
await supabase
    .from('membres_groupes')
    .delete()
    .eq(
'groupe_id',
groupeId,
);

// Groupe
await supabase
    .from('groupes')
    .delete()
    .eq(
'id',
groupeId,
);

print(
"✅ Groupe $groupeId supprimé",
);
}

// ============================================================
// PUBLICATIONS
// ============================================================

Future<int> insertPublication(
Publication publication,
int groupeId,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final result = await supabase
    .from('publications')
    .insert({
'contenuMessage':
publication.contenuMessage,
'auteur': publication.auteur,
'auteur_id': profileId,
'datePublication':
publication.datePublication
    .toIso8601String(),
'nombreLikes':
publication.nombreLikes,
'nombreCommentaires':
publication.nombreCommentaires,
'aime': publication.aime,
'groupe_id': groupeId,
'image': publication.images.isNotEmpty
? publication.images.first
    : null,
})
    .select('id')
    .single();

final publicationId =
result['id'] as int;

// Ajouter toutes les images.
for (final image in publication.images) {
await supabase
    .from('publication_images')
    .insert({
'publication_id': publicationId,
'image': image,
});
}

print(
"✅ Publication créée : $publicationId",
);

return publicationId;
}

// ------------------------------------------------------------
// RÉCUPÉRER PUBLICATIONS
// ------------------------------------------------------------

Future<List<Publication>> getPublications(
int groupeId,
) async {
final resultats = await supabase
    .from('publications')
    .select()
    .eq('groupe_id', groupeId)
    .order('id', ascending: false);

final profil =
await getProfilUtilisateurActuel();

final utilisateurId =
profil['id'] as String;

final List<Publication> publications = [];

for (final map in resultats) {
final publicationId =
map['id'] as int;

// Images
final resultatsImages = await supabase
    .from('publication_images')
    .select('image')
    .eq(
'publication_id',
publicationId,
)
    .order('id', ascending: true);

List<String> images = resultatsImages
    .map<String>(
(image) => image['image'] as String,
)
    .toList();

// Compatibilité avec l'ancienne colonne image.
if (images.isEmpty &&
map['image'] != null) {
images = [
map['image'] as String,
];
}

// Likes
final likes = await supabase
    .from('likes_publications')
    .select('id, utilisateur_id')
    .eq(
'publication_id',
publicationId,
);

final nombreLikes = likes.length;

final aime = likes.any(
(like) =>
like['utilisateur_id'] ==
utilisateurId,
);

publications.add(
Publication(
id: publicationId,
contenuMessage:
map['contenuMessage'] as String? ?? '',
auteur:
map['auteur'] as String? ?? 'Utilisateur',
datePublication: DateTime.parse(
map['datePublication'] as String,
),
nombreLikes: nombreLikes,
nombreCommentaires:
map['nombreCommentaires'] as int? ?? 0,
aime: aime,
images: images,
),
);
}

return publications;
}

// ============================================================
// UPLOAD IMAGES PUBLICATION
// ============================================================

Future<String> uploadImagePublication(
File image,
) async {
try {
final nomFichier =
'${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';

final chemin =
'publications/$nomFichier';

print(
"📤 UPLOAD IMAGE : ${image.path}",
);

await supabase.storage
    .from('publication-images')
    .upload(
chemin,
image,
fileOptions: const FileOptions(
upsert: true,
),
);

final url = supabase.storage
    .from('publication-images')
    .getPublicUrl(chemin);

print(
"✅ IMAGE UPLOADÉE : $url",
);

return url;
} catch (e) {
print(
"❌ ERREUR UPLOAD IMAGE : $e",
);
rethrow;
}
}

// ============================================================
// LIKES PUBLICATIONS
// ============================================================

Future<void> ajouterLikePublication(
int publicationId,
String utilisateurId,
) async {
await supabase
    .from('likes_publications')
    .insert({
'publication_id': publicationId,
'utilisateur_id': utilisateurId,
});

print(
"✅ LIKE PUBLICATION AJOUTÉ : "
"publication=$publicationId "
"utilisateur=$utilisateurId",
);
}

Future<void> retirerLikePublication(
int publicationId,
String utilisateurId,
) async {
await supabase
    .from('likes_publications')
    .delete()
    .eq(
'publication_id',
publicationId,
)
    .eq(
'utilisateur_id',
utilisateurId,
);

print(
"✅ LIKE PUBLICATION RETIRÉ : "
"publication=$publicationId "
"utilisateur=$utilisateurId",
);
}

Future<int> getNombreLikesPublication(
int publicationId,
) async {
final resultat = await supabase
    .from('likes_publications')
    .select('id')
    .eq(
'publication_id',
publicationId,
);

return resultat.length;
}

Future<bool> aDejaAimePublication(
int publicationId,
String utilisateurId,
) async {
final resultat = await supabase
    .from('likes_publications')
    .select('id')
    .eq(
'publication_id',
publicationId,
)
    .eq(
'utilisateur_id',
utilisateurId,
)
    .limit(1);

return resultat.isNotEmpty;
}

// ============================================================
// COMMENTAIRES
// ============================================================

Future<int> insertCommentaire(
Commentaire commentaire,
) async {
final profil =
await getProfilUtilisateurActuel();

final profileId =
profil['id'] as String;

final result = await supabase
    .from('commentaires')
    .insert({
'texte': commentaire.texte,
'auteur': commentaire.auteur,
'auteur_id': profileId,
'dateCommentaire':
commentaire.dateCommentaire
    .toIso8601String(),
'publication_id':
commentaire.publicationId,
'parent_id': commentaire.parentId,
})
    .select('id')
    .single();

return result['id'] as int;
}

Future<List<Commentaire>> getCommentaires(
int publicationId,
) async {
final resultats = await supabase
    .from('commentaires')
    .select()
    .eq(
'publication_id',
publicationId,
)
    .order('id', ascending: true);

final List<Commentaire> commentaires = [];

for (final map in resultats) {
final commentaireId =
map['id'] as int;

final likes = await supabase
    .from('likes_commentaires')
    .select('id')
    .eq(
'commentaire_id',
commentaireId,
);

final nombreLikes = likes.length;

commentaires.add(
Commentaire(
id: commentaireId,
texte:
map['texte'] as String? ?? '',
auteur:
map['auteur'] as String? ?? 'Utilisateur',
dateCommentaire: DateTime.parse(
map['dateCommentaire'] as String,
),
publicationId:
map['publication_id'] as int,
parentId:
map['parent_id'] as int?,
nombreLikes: nombreLikes,
),
);
}

return commentaires;
}

Future<int> getNombreCommentaires(
int publicationId,
) async {
final result = await supabase
    .from('commentaires')
    .select('id')
    .eq(
'publication_id',
publicationId,
);

return result.length;
}

Future<void> updateCommentaires(
int publicationId,
) async {
final nombre =
await getNombreCommentaires(
publicationId,
);

await supabase
    .from('publications')
    .update({
'nombreCommentaires': nombre,
})
    .eq(
'id',
publicationId,
);

print(
"✅ Nombre de commentaires mis à jour : $nombre",
);
}

// ============================================================
// LIKES COMMENTAIRES
// ============================================================

Future<void> ajouterLikeCommentaire(
int commentaireId,
String utilisateurId,
) async {
await supabase
    .from('likes_commentaires')
    .insert({
'commentaire_id': commentaireId,
'utilisateur_id': utilisateurId,
});

print(
"✅ LIKE COMMENTAIRE AJOUTÉ : "
"commentaire=$commentaireId "
"utilisateur=$utilisateurId",
);
}

Future<void> retirerLikeCommentaire(
int commentaireId,
String utilisateurId,
) async {
await supabase
    .from('likes_commentaires')
    .delete()
    .eq(
'commentaire_id',
commentaireId,
)
    .eq(
'utilisateur_id',
utilisateurId,
);

print(
"✅ LIKE COMMENTAIRE RETIRÉ : "
"commentaire=$commentaireId "
"utilisateur=$utilisateurId",
);
}

Future<bool> aDejaAimeCommentaire(
int commentaireId,
String utilisateurId,
) async {
final resultat = await supabase
    .from('likes_commentaires')
    .select('id')
    .eq(
'commentaire_id',
commentaireId,
)
    .eq(
'utilisateur_id',
utilisateurId,
)
    .limit(1);

return resultat.isNotEmpty;
}

Future<int> getNombreLikesCommentaire(
int commentaireId,
) async {
final resultat = await supabase
    .from('likes_commentaires')
    .select('id')
    .eq(
'commentaire_id',
commentaireId,
);

return resultat.length;
}

// ============================================================
// MODIFIER COMMENTAIRE
// ============================================================

Future<void> modifierCommentaire(
int commentaireId,
String nouveauTexte,
) async {
await supabase
    .from('commentaires')
    .update({
'texte': nouveauTexte,
})
    .eq(
'id',
commentaireId,
);

print(
"✅ Commentaire $commentaireId modifié",
);
}

// ============================================================
// SUPPRIMER COMMENTAIRE
// ============================================================

Future<void> supprimerCommentaire(
int commentaireId,
) async {
// Supprimer les likes associés.
await supabase
    .from('likes_commentaires')
    .delete()
    .eq(
'commentaire_id',
commentaireId,
);

// Supprimer les réponses associées.
await supabase
    .from('commentaires')
    .delete()
    .eq(
'parent_id',
commentaireId,
);

// Supprimer le commentaire.
await supabase
    .from('commentaires')
    .delete()
    .eq(
'id',
commentaireId,
);

print(
"✅ Commentaire $commentaireId supprimé",
);
}

// ============================================================
// MODIFIER PUBLICATION
// ============================================================

Future<void> modifierPublication(
int publicationId,
String nouveauTexte,
) async {
await supabase
    .from('publications')
    .update({
'contenuMessage': nouveauTexte,
})
    .eq(
'id',
publicationId,
);

print(
"✅ Publication $publicationId modifiée",
);
}

// ============================================================
// SUPPRIMER PUBLICATION
// ============================================================

Future<void> supprimerPublication(
int publicationId,
) async {
// Likes publication
await supabase
    .from('likes_publications')
    .delete()
    .eq(
'publication_id',
publicationId,
);

// Images publication
await supabase
    .from('publication_images')
    .delete()
    .eq(
'publication_id',
publicationId,
);

// Commentaires
final commentaires = await supabase
    .from('commentaires')
    .select('id')
    .eq(
'publication_id',
publicationId,
);

for (final commentaire in commentaires) {
final commentaireId =
commentaire['id'] as int;

await supabase
    .from('likes_commentaires')
    .delete()
    .eq(
'commentaire_id',
commentaireId,
);
}

await supabase
    .from('commentaires')
    .delete()
    .eq(
'publication_id',
publicationId,
);

// Publication
await supabase
    .from('publications')
    .delete()
    .eq(
'id',
publicationId,
);

print(
"✅ Publication $publicationId supprimée",
);
}
}

