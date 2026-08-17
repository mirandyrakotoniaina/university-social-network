
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/publication.dart';
import '../models/commentaire.dart';
import '../models/groupe.dart';
import '../models/utilisateurs.dart';
  class DatabaseHelper {
    static Database? _database;
    static int? utilisateurConnecteId;

    Future<Database> get database async {
      if (_database != null) {
        return _database!;
      }

      _database = await _initDatabase();
      return _database!;
    }

    Future<Database> _initDatabase() async {
      final chemin = await getDatabasesPath();

      final cheminComplet = join(
        chemin,
        'reseau_social.db',
      );

      return await openDatabase(
        cheminComplet,
        version: 16,
        onCreate: (db, version) async {
// Nos tables seront créées ici
          await db.execute('''
            CREATE TABLE groupes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom TEXT NOT NULL,
            description TEXT NOT NULL,
            nombreMembres INTEGER NOT NULL,
            image TEXT NOT NULL,
            type TEXT NOT NULL
         )
          ''');
          await db.execute('''
            CREATE TABLE publications (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              contenuMessage TEXT NOT NULL,
              auteur TEXT NOT NULL,
              datePublication TEXT NOT NULL,
              nombreLikes INTEGER NOT NULL,
              nombreCommentaires INTEGER NOT NULL,
              aime INTEGER NOT NULL DEFAULT 0,
              image TEXT,
              groupe_id INTEGER NOT NULL
            )
           ''');

          // Table des commentaires
          await db.execute('''
        CREATE TABLE commentaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        texte TEXT NOT NULL,
        auteur TEXT NOT NULL,
        dateCommentaire TEXT NOT NULL,
        publication_id INTEGER NOT NULL,
        parent_id INTEGER,
        nombreLikes INTEGER NOT NULL DEFAULT 0
      )
    ''');

          await db.execute('''
  CREATE TABLE likes_commentaires (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    commentaire_id INTEGER NOT NULL,
    utilisateur_id INTEGER NOT NULL
  )
''');
// Table des membres
          await db.execute('''
      CREATE TABLE membres_groupes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupe_id INTEGER NOT NULL,
        utilisateur_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'membre',
        statut TEXT NOT NULL DEFAULT 'en_attente'
      )
    ''');


          await db.execute('''
  CREATE TABLE utilisateurs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    email TEXT NOT NULL
  )
''');



        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
      CREATE TABLE commentaires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        texte TEXT NOT NULL,
        auteur TEXT NOT NULL,
        dateCommentaire TEXT NOT NULL,
        publication_id INTEGER NOT NULL,
        parent_id INTEGER
      )
    ''');
          }

          if (oldVersion < 4) {
            await db.execute('''
      ALTER TABLE publications
      ADD COLUMN aime INTEGER NOT NULL DEFAULT 0
    ''');
          }

          if (oldVersion < 6) {
            await db.execute('''
      CREATE TABLE membres_groupes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        groupe_id INTEGER NOT NULL,
        utilisateur_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'membre'
      )
    ''');
          }

          if (oldVersion < 7) {
            await db.execute('''
      CREATE TABLE utilisateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');

            await db.execute('''
      ALTER TABLE membres_groupes
      ADD COLUMN utilisateur_id INTEGER
    ''');
          }

          if (oldVersion < 11) {
            await db.execute('''
    ALTER TABLE membres_groupes
    ADD COLUMN role TEXT NOT NULL DEFAULT 'membre'
  ''');
          }


          if (oldVersion < 12) {
            await db.execute('''
    ALTER TABLE publications
    ADD COLUMN image TEXT
  ''');
          }

          if (oldVersion < 13) {
            await db.execute('''
    ALTER TABLE membres_groupes
    ADD COLUMN statut TEXT NOT NULL DEFAULT 'en_attente'
  ''');

            await db.execute('''
    UPDATE membres_groupes
    SET statut = 'accepte'
  ''');
          }

          if (oldVersion < 14) {
            await db.execute('''
    ALTER TABLE commentaires
    ADD COLUMN nombreLikes INTEGER NOT NULL DEFAULT 0
  ''');
          }

          if (oldVersion < 15) {
            await db.execute('''
    CREATE TABLE likes_commentaires (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      commentaire_id INTEGER NOT NULL,
      utilisateur_id INTEGER NOT NULL
    )
  ''');
          }

          if (oldVersion < 16) {
            await db.execute('''
    CREATE TABLE publication_images (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      publication_id INTEGER NOT NULL,
      image TEXT NOT NULL
    )
  ''');
          }
        },
      );
    }




    Future<int> insertGroupe(Groupe groupe) async {
      final db = await database;

      // 1. Créer le groupe
      final groupeId = await db.insert(
        'groupes',
        {
          'nom': groupe.nom,
          'description': groupe.description,
          'nombreMembres': groupe.nombreMembres,
          'image': groupe.image,
          'type': groupe.type,
        },
      );

      // 2. Récupérer l'utilisateur actuel
      final utilisateur = await getUtilisateurActuel();

      // 3. Ajouter le créateur comme admin du groupe
      await db.insert(
        'membres_groupes',
        {
          'groupe_id': groupeId,
          'utilisateur_id': utilisateur.id,
          'role': 'admin',
          'statut': 'accepte',
        },
      );

      return groupeId;
    }


    Future<int> insertPublication(
        Publication publication,
        int groupeId,
        ) async {
      final db = await database;

      // 1. Création de la publication
      final publicationId = await db.insert(
        'publications',
        {
          'contenuMessage': publication.contenuMessage,
          'auteur': publication.auteur,
          'datePublication': publication.datePublication.toIso8601String(),
          'nombreLikes': publication.nombreLikes,
          'nombreCommentaires': publication.nombreCommentaires,
          'aime': publication.aime ? 1 : 0,

          // Ancienne colonne conservée pour compatibilité
          'image': publication.images.isNotEmpty
              ? publication.images.first
              : null,

          'groupe_id': groupeId,
        },
      );

      // 2. Enregistrement de toutes les photos
      for (final image in publication.images) {
        await db.insert(
          'publication_images',
          {
            'publication_id': publicationId,
            'image': image,
          },
        );
      }

      return publicationId;
    }
  Future<List<Groupe>> getGroupes() async {
    final db = await database;

    final resultats = await db.query('groupes');

    List<Groupe> groupes = [];

    for (final map in resultats) {
      final groupeId = map['id'] as int;

      final publications = await getPublications(groupeId);

      final groupe = Groupe(
        id: map['id'] as int,
        nom: map['nom'] as String,
        description: map['description'] as String,
        nombreMembres: map['nombreMembres'] as int,
        image: map['image'] as String,
        type: map['type'] as String? ?? 'Classe',
        publications: publications,
      );

      groupes.add(groupe);
    }

    return groupes;
  }

    Future<void> ajouterMembre(
        int groupeId,
        int utilisateurId,
        String role,
        ) async {
      final db = await database;

      await db.insert(
        'membres_groupes',
        {
          'groupe_id': groupeId,
          'utilisateur_id': utilisateurId,
          'role': role,
        },
      );
    }



    Future<List<Publication>> getPublications(int groupeId) async {
      final db = await database;

      final resultats = await db.query(
        'publications',
        where: 'groupe_id = ?',
        whereArgs: [groupeId],
      );

      List<Publication> publications = [];

      for (final map in resultats) {
        final publicationId = map['id'] as int;

        // Récupérer toutes les photos de la publication
        final resultatsImages = await db.query(
          'publication_images',
          where: 'publication_id = ?',
          whereArgs: [publicationId],
          orderBy: 'id ASC',
        );

        List<String> images = resultatsImages
            .map((image) => image['image'] as String)
            .toList();

        // Compatibilité avec les anciennes publications
        // qui utilisent encore la colonne "image"
        if (images.isEmpty && map['image'] != null) {
          images = [map['image'] as String];
        }

        publications.add(
          Publication(
            id: publicationId,
            contenuMessage: map['contenuMessage'] as String,
            auteur: map['auteur'] as String,
            datePublication: DateTime.parse(
              map['datePublication'] as String,
            ),
            nombreLikes: map['nombreLikes'] as int,
            nombreCommentaires: map['nombreCommentaires'] as int,
            aime: (map['aime'] as int) == 1,
            images: images,
          ),
        );
      }

      return publications;
    }

  Future<List<Map<String, dynamic>>> testPublications() async {
    final db = await database;

    return await db.query('publications');
  }

  Future<void> supprimerBase() async {
    final chemin = await getDatabasesPath();

    final cheminComplet = join(
      chemin,
      'reseau_social.db',
    );

    await deleteDatabase(cheminComplet);

    _database = null;
  }


    Future updateLikes(
        int publicationId,
        int nombreLikes,
        bool aime,
        ) async {
      final db = await database;

      await db.update(
        'publications',
        {
          'nombreLikes': nombreLikes,
          'aime': aime ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [publicationId],
      );
    }

  Future<void> updateCommentaires(
      int publicationId,
      int nombreCommentaires,
      ) async {
    final db = await database;

    await db.update(
      'publications',
      {
        'nombreCommentaires': nombreCommentaires,
      },
      where: 'id = ?',
      whereArgs: [publicationId],
    );
  }

    Future insertCommentaire(
        Commentaire commentaire,
        ) async {
      final db = await database;

      return await db.insert(
        'commentaires',
        {
          'texte': commentaire.texte,
          'auteur': commentaire.auteur,
          'dateCommentaire':
          commentaire.dateCommentaire.toIso8601String(),
          'publication_id': commentaire.publicationId,
          'parent_id': commentaire.parentId,
          'nombreLikes': commentaire.nombreLikes,
        },
      );
    }

    Future<List<Commentaire>> getCommentaires(int publicationId) async {
      final db = await database;

      final resultats = await db.query(
        'commentaires',
        where: 'publication_id = ?',
        whereArgs: [publicationId],
        orderBy: 'id ASC',
      );

      return resultats.map((map) {
        return Commentaire(
          id: map['id'] as int,
          texte: map['texte'] as String,
          auteur: map['auteur'] as String,
          dateCommentaire: DateTime.parse(
            map['dateCommentaire'] as String,
          ),
          publicationId: map['publication_id'] as int,
          parentId: map['parent_id'] as int?,
          nombreLikes: map['nombreLikes'] as int? ?? 0,
        );
      }).toList();
    }


    Future<void> modifierLikeCommentaire(
        int commentaireId,
        bool aime,
        ) async {
      final db = await database;

      await db.rawUpdate(
        '''
    UPDATE commentaires
    SET nombreLikes = nombreLikes ${aime ? '+' : '-'} 1
    WHERE id = ?
    ''',
        [commentaireId],
      );
    }


    Future<bool> aDejaAimeCommentaire(
        int commentaireId,
        int utilisateurId,
        ) async {
      final db = await database;

      final resultat = await db.query(
        'likes_commentaires',
        where: 'commentaire_id = ? AND utilisateur_id = ?',
        whereArgs: [
          commentaireId,
          utilisateurId,
        ],
        limit: 1,
      );

      return resultat.isNotEmpty;
    }

    Future<void> ajouterLikeCommentaire(
        int commentaireId,
        int utilisateurId,
        ) async {
      final db = await database;

      await db.insert(
        'likes_commentaires',
        {
          'commentaire_id': commentaireId,
          'utilisateur_id': utilisateurId,
        },
      );
      print(
        "LIKE AJOUTÉ : commentaire=$commentaireId utilisateur=$utilisateurId",
      );

      await db.rawUpdate(
        '''
    UPDATE commentaires
    SET nombreLikes = nombreLikes + 1
    WHERE id = ?
    ''',
        [commentaireId],
      );
    }

    Future<void> retirerLikeCommentaire(
        int commentaireId,
        int utilisateurId,
        ) async {
      final db = await database;

      await db.delete(
        'likes_commentaires',
        where: 'commentaire_id = ? AND utilisateur_id = ?',
        whereArgs: [commentaireId, utilisateurId],
      );

      await db.rawUpdate(
        '''
    UPDATE commentaires
    SET nombreLikes = CASE
      WHEN nombreLikes > 0 THEN nombreLikes - 1
      ELSE 0
    END
    WHERE id = ?
    ''',
        [commentaireId],
      );
    }

    Future<int> getNombreLikesCommentaire(int commentaireId) async {
      final db = await database;

      final resultat = await db.rawQuery(
        '''
    SELECT COUNT(*) AS total
    FROM likes_commentaires
    WHERE commentaire_id = ?
    ''',
        [commentaireId],
      );
      print(
        "TOTAL LIKES COMMENTAIRE $commentaireId = ${resultat.first['total']}",
      );

      return (resultat.first['total'] as int?) ?? 0;
    }







    Future<void> supprimerPublication(int publicationId) async {
      final db = await database;

      await db.delete(
        'publications',
        where: 'id = ?',
        whereArgs: [publicationId],
      );
    }

    Future<void> modifierPublication(
        int publicationId,
        String nouveauTexte,
        ) async {
      final db = await database;

      await db.update(
        'publications',
        {
          'contenuMessage': nouveauTexte,
        },
        where: 'id = ?',
        whereArgs: [publicationId],
      );
    }



    Future<void> modifierCommentaire(
        int commentaireId,
        String nouveauTexte,
        ) async {
      final db = await database;

      await db.update(
        'commentaires',
        {
          'texte': nouveauTexte,
        },
        where: 'id = ?',
        whereArgs: [commentaireId],
      );
    }


    Future<void> supprimerCommentaire(int commentaireId) async {
      final db = await database;

      await db.delete(
        'commentaires',
        where: 'id = ?',
        whereArgs: [commentaireId],
      );
    }


    Future<void> modifierGroupe(
        int groupeId,
        String nouveauNom,
        String nouvelleDescription,
        int nouveauNombreMembres,
        String nouveauType,
        ) async {
      final db = await database;

      await db.update(
        'groupes',
        {
          'nom': nouveauNom,
          'description': nouvelleDescription,
          'nombreMembres': nouveauNombreMembres,
          'type': nouveauType,
        },
        where: 'id = ?',
        whereArgs: [groupeId],
      );
    }


    Future<void> supprimerGroupe(int groupeId) async {
      final db = await database;

      // Récupérer les publications du groupe
      final publications = await db.query(
        'publications',
        columns: ['id'],
        where: 'groupe_id = ?',
        whereArgs: [groupeId],
      );

      // Supprimer les commentaires liés aux publications
      for (final publication in publications) {
        final publicationId = publication['id'] as int;

        await db.delete(
          'commentaires',
          where: 'publication_id = ?',
          whereArgs: [publicationId],
        );
      }

      // Supprimer les publications
      await db.delete(
        'publications',
        where: 'groupe_id = ?',
        whereArgs: [groupeId],
      );

      // Supprimer le groupe
      await db.delete(
        'groupes',
        where: 'id = ?',
        whereArgs: [groupeId],
      );
    }


    Future<void> modifierNombreMembres(
        int groupeId,
        int nouveauNombre,
        ) async {
      final db = await database;

      await db.update(
        'groupes',
        {
          'nombreMembres': nouveauNombre,
        },
        where: 'id = ?',
        whereArgs: [groupeId],
      );
    }
    Future<bool> estMembre(int groupeId) async {
      final db = await database;

      final utilisateur = await getUtilisateurActuel();

      print(
        "VERIFICATION : groupe=$groupeId, utilisateur=${utilisateur.id}",
      );

      final resultat = await db.query(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateur.id,
        ],
      );

      print("NOMBRE DE LIGNES TROUVÉES : ${resultat.length}");

      return resultat.isNotEmpty;
    }

    Future<void> rejoindreGroupe(int groupeId) async {
      final db = await database;

      final utilisateur = await getUtilisateurActuel();

      final existe = await db.query(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateur.id,
        ],
      );

      if (existe.isNotEmpty) {
        print("L'utilisateur a déjà une demande ou est déjà membre.");
        return;
      }

      await db.insert(
        'membres_groupes',
        {
          'groupe_id': groupeId,
          'utilisateur_id': utilisateur.id,
          'role': 'membre',
          'statut': 'en_attente',
        },
      );

      print(
        "DEMANDE ENVOYÉE : utilisateur=${utilisateur.id}, groupe=$groupeId",
      );
    }


    Future<List<Utilisateur>> getDemandesMembres(int groupeId) async {
      final db = await database;

      final resultats = await db.rawQuery('''
    SELECT utilisateurs.id,
           utilisateurs.nom,
           utilisateurs.email,
           membres_groupes.role
    FROM utilisateurs
    INNER JOIN membres_groupes
      ON utilisateurs.id = membres_groupes.utilisateur_id
    WHERE membres_groupes.groupe_id = ?
      AND membres_groupes.statut = 'en_attente'
  ''', [groupeId]);

      return resultats.map((map) {
        return Utilisateur(
          id: map['id'] as int,
          nom: map['nom'] as String,
          email: map['email'] as String,
          role: map['role'] as String? ?? 'membre',
        );
      }).toList();
    }

    Future<void> accepterDemandeMembre(
        int groupeId,
        int utilisateurId,
        ) async {
      final db = await database;

      await db.update(
        'membres_groupes',
        {
          'statut': 'accepte',
        },
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateurId,
        ],
      );

      await db.rawUpdate(
        '''
    UPDATE groupes
    SET nombreMembres = nombreMembres + 1
    WHERE id = ?
    ''',
        [groupeId],
      );
    }

    Future<void> refuserDemandeMembre(
        int groupeId,
        int utilisateurId,
        ) async {
      final db = await database;

      await db.delete(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ? AND statut = ?',
        whereArgs: [
          groupeId,
          utilisateurId,
          'en_attente',
        ],
      );
    }
    Future<void> accepterMembre(
        int groupeId,
        int utilisateurId,
        ) async {
      final db = await database;

      // Vérifier que la demande existe
      final demande = await db.query(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ? AND statut = ?',
        whereArgs: [
          groupeId,
          utilisateurId,
          'en_attente',
        ],
      );

      if (demande.isEmpty) {
        return;
      }

      // Accepter la demande
      await db.update(
        'membres_groupes',
        {
          'statut': 'accepte',
          'role': 'membre',
        },
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateurId,
        ],
      );

      // Augmenter le nombre de membres
      await db.rawUpdate(
        '''
    UPDATE groupes
    SET nombreMembres = nombreMembres + 1
    WHERE id = ?
    ''',
        [groupeId],
      );
    }


    Future<void> refuserMembre(
        int groupeId,
        int utilisateurId,
        ) async {
      final db = await database;

      // Vérifier que la demande existe
      final demande = await db.query(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ? AND statut = ?',
        whereArgs: [
          groupeId,
          utilisateurId,
          'en_attente',
        ],
      );

      if (demande.isEmpty) {
        return;
      }

      // Supprimer la demande
      await db.delete(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateurId,
        ],
      );
    }

    Future<void> quitterGroupe(int groupeId) async {
      final db = await database;

      final utilisateur = await getUtilisateurActuel();

      // Vérifier si l'utilisateur est membre
      final existe = await db.query(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateur.id,
        ],
      );

      // S'il n'est pas membre
      if (existe.isEmpty) {
        return;
      }

      // Récupérer le rôle
      final role = existe.first['role'] as String;

      // Si l'utilisateur est administrateur
      if (role == 'admin') {
        final autresMembres = await getAutresMembres(groupeId);

        // Il est le seul membre
        if (autresMembres.isEmpty) {
          throw Exception(
            "L'administrateur est le seul membre du groupe.",
          );
        }

        // Il doit transférer l'administration
        throw Exception(
          "L'administrateur doit choisir un nouveau responsable avant de quitter.",
        );
      }

      // Si c'est un membre normal, il peut quitter
      await db.delete(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateur.id,
        ],
      );

      // Diminuer le nombre de membres
      await db.rawUpdate(
        '''
    UPDATE groupes
    SET nombreMembres = CASE
      WHEN nombreMembres > 0 THEN nombreMembres - 1
      ELSE 0
    END
    WHERE id = ?
    ''',
        [groupeId],
      );
    }


    Future<void> transfererAdmin(
        int groupeId,
        int nouvelAdminId,
        ) async {
      final db = await database;

      final utilisateurActuel = await getUtilisateurActuel();

      // Vérifier que le nouvel admin est bien membre
      final membre = await db.query(
        'membres_groupes',
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          nouvelAdminId,
        ],
      );

      if (membre.isEmpty) {
        throw Exception(
          "Cette personne n'est pas membre du groupe.",
        );
      }

      // Retirer le rôle admin à l'ancien admin
      await db.update(
        'membres_groupes',
        {
          'role': 'membre',
        },
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateurActuel.id,
        ],
      );

      // Donner le rôle admin au nouveau responsable
      await db.update(
        'membres_groupes',
        {
          'role': 'admin',
        },
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          nouvelAdminId,
        ],
      );
    }


    Future<int> insertUtilisateur(Utilisateur utilisateur) async {
      final db = await database;

      return await db.insert(
        'utilisateurs',
        {
          'nom': utilisateur.nom,
          'email': utilisateur.email,
        },
      );
    }

    Future<List<Utilisateur>> getUtilisateurs() async {
      final db = await database;

      final resultats = await db.query('utilisateurs');

      return resultats.map((map) {
        return Utilisateur(
          id: map['id'] as int,
          nom: map['nom'] as String,
          email: map['email'] as String,
        );
      }).toList();
    }

    Future<Utilisateur> getUtilisateurActuel() async {
      final db = await database;

      if (utilisateurConnecteId != null) {
        final resultats = await db.query(
          'utilisateurs',
          where: 'id = ?',
          whereArgs: [utilisateurConnecteId],
        );

        if (resultats.isNotEmpty) {
          final map = resultats.first;

          return Utilisateur(
            id: map['id'] as int,
            nom: map['nom'] as String,
            email: map['email'] as String,
          );
        }
      }

      final resultats = await db.query(
        'utilisateurs',
        limit: 1,
      );

      if (resultats.isNotEmpty) {
        final map = resultats.first;

        final utilisateur = Utilisateur(
          id: map['id'] as int,
          nom: map['nom'] as String,
          email: map['email'] as String,
        );
        utilisateurConnecteId = utilisateur.id;

        print("UTILISATEUR ACTUEL : id=${utilisateur.id}, nom=${utilisateur.nom}");

        return utilisateur;
      }

      final id = await db.insert(
        'utilisateurs',
        {
          'nom': 'Mirandy',
          'email': 'mirandy@gmail.com',
        },
      );
      utilisateurConnecteId = id;

      print("NOUVEL UTILISATEUR CRÉÉ : id=$id");

      return Utilisateur(
        id: id,
        nom: 'Mirandy',
        email: 'mirandy@gmail.com',
      );
    }


    Future<List<Utilisateur>> getMembresGroupe(int groupeId) async {
      final db = await database;

      final resultats = await db.rawQuery('''
    SELECT utilisateurs.id, utilisateurs.nom, utilisateurs.email,
           membres_groupes.role
    FROM utilisateurs
    INNER JOIN membres_groupes
      ON utilisateurs.id = membres_groupes.utilisateur_id
   WHERE membres_groupes.groupe_id = ?
  AND membres_groupes.statut = 'accepte'
''', [groupeId]);

      print("RESULTAT MEMBRES : $resultats");

      return resultats.map((map) {
        return Utilisateur(
          id: map['id'] as int,
          nom: map['nom'] as String,
          email: map['email'] as String,
          role: map['role'] as String,
        );
      }).toList();
    }

    Future<void> afficherDonneesMembres(int groupeId) async {
      final db = await database;

      final resultats = await db.query(
        'membres_groupes',
        where: 'groupe_id = ?',
        whereArgs: [groupeId],
      );

      print("MEMBRES DU GROUPE $groupeId : $resultats");
    }
    Future<void> reparerMembres() async {
      final db = await database;

      final utilisateur = await getUtilisateurActuel();

      // Supprimer les anciennes associations invalides
      await db.delete(
        'membres_groupes',
        where: 'utilisateur_id IS NULL',
      );

      // Vérifier dans quels groupes l'utilisateur est déjà membre
      final groupes = await db.query('groupes');

      for (final groupe in groupes) {
        final groupeId = groupe['id'] as int;

        final existe = await db.query(
          'membres_groupes',
          where: 'groupe_id = ? AND utilisateur_id = ?',
          whereArgs: [groupeId, utilisateur.id],
        );

        if (existe.isEmpty) {
          // Pour l'instant, on ne crée pas automatiquement
          // un membre dans tous les groupes.
          continue;
        }

        await db.update(
          'groupes',
          {
            'nombreMembres': 1,
          },
          where: 'id = ?',
          whereArgs: [groupeId],
        );
      }
    }


    Future<void> creerUtilisateursTest() async {
      final db = await database;

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
          'nom': 'Thomas',
          'email': 'thomas@gmail.com',
        },
      ];

      for (final utilisateur in utilisateurs) {
        final existe = await db.query(
          'utilisateurs',
          where: 'email = ?',
          whereArgs: [utilisateur['email']],
        );

        if (existe.isEmpty) {
          await db.insert(
            'utilisateurs',
            utilisateur,
          );
        }
      }
    }


    Future<void> changerUtilisateur(int utilisateurId) async {
      utilisateurConnecteId = utilisateurId;

      print("UTILISATEUR CONNECTÉ : $utilisateurConnecteId");
    }



    Future<String> getNomUtilisateurConnecte() async {
      final db = await database;

      final resultat = await db.query(
        'utilisateurs',
        where: 'id = ?',
        whereArgs: [utilisateurConnecteId],
        limit: 1,
      );

      if (resultat.isEmpty) {
        return "Utilisateur";
      }

      return resultat.first['nom'].toString();
    }



    Future<List<Utilisateur>> getTousLesUtilisateurs() async {
      final db = await database;

      final resultats = await db.query('utilisateurs');

      return resultats.map((map) {
        return Utilisateur(
          id: map['id'] as int,
          nom: map['nom'] as String,
          email: map['email'] as String,
        );
      }).toList();
    }

    Future<void> ajouterUtilisateurAuGroupe(
        int utilisateurId,
        int groupeId,
        ) async {
      final db = await database;

      final existe = await db.query(
        'membres_groupes',
        where: 'utilisateur_id = ? AND groupe_id = ?',
        whereArgs: [utilisateurId, groupeId],
      );

      if (existe.isEmpty) {
        await db.insert(
          'membres_groupes',
          {
            'utilisateur_id': utilisateurId,
            'groupe_id': groupeId,
            'role': 'membre',
            'statut': 'accepte',
          },
        );

        await db.rawUpdate(
          '''
      UPDATE groupes
      SET nombreMembres = nombreMembres + 1
      WHERE id = ?
      ''',
          [groupeId],
        );
      }
    }


    Future<void> retirerUtilisateurDuGroupe(
        int utilisateurId,
        int groupeId,
        ) async {
      final db = await database;

      await db.delete(
        'membres_groupes',
        where: 'utilisateur_id = ? AND groupe_id = ?',
        whereArgs: [
          utilisateurId,
          groupeId,
        ],
      );

      // Mettre à jour le nombre de membres
      final groupe = await db.query(
        'groupes',
        columns: ['nombreMembres'],
        where: 'id = ?',
        whereArgs: [groupeId],
      );

      if (groupe.isNotEmpty) {
        final nombreActuel = groupe.first['nombreMembres'] as int;

        if (nombreActuel > 0) {
          await db.update(
            'groupes',
            {
              'nombreMembres': nombreActuel - 1,
            },
            where: 'id = ?',
            whereArgs: [groupeId],
          );
        }
      }
    }


    Future<String> getRoleUtilisateur(int groupeId) async {
      final db = await database;

      final utilisateur = await getUtilisateurActuel();

      final resultat = await db.query(
        'membres_groupes',
        columns: ['role'],
        where: 'groupe_id = ? AND utilisateur_id = ?',
        whereArgs: [
          groupeId,
          utilisateur.id,
        ],
      );

      if (resultat.isNotEmpty) {
        return resultat.first['role'] as String;
      }

      return 'membre';
    }


    Future<List<Utilisateur>> getAutresMembres(int groupeId) async {
      final db = await database;

      final utilisateur = await getUtilisateurActuel();

      final resultat = await db.rawQuery('''
    SELECT utilisateurs.*
    FROM utilisateurs
    INNER JOIN membres_groupes
      ON utilisateurs.id = membres_groupes.utilisateur_id
    WHERE membres_groupes.groupe_id = ?
      AND membres_groupes.utilisateur_id != ?
  ''', [
        groupeId,
        utilisateur.id,
      ]);

      return resultat.map((map) {
        return Utilisateur(
          id: map['id'] as int,
          nom: map['nom'] as String,
          email: map['email'] as String,
        );
      }).toList();
    }


    Future<String> getNomUtilisateurActuel() async {
      final db = await database;

      final result = await db.query(
        'utilisateur_actuel',
        limit: 1,
      );

      if (result.isEmpty) {
        return "Moi";
      }

      return result.first['nom'].toString();
    }




}

