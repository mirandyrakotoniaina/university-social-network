class Commentaire {
  final int? id;
  String texte;
  final String auteur;
  final DateTime dateCommentaire;
  final int publicationId;
  final int? parentId;

  Commentaire({
    this.id,
    required this.texte,
    required this.auteur,
    required this.dateCommentaire,
    required this.publicationId,
    this.parentId,
  });
}