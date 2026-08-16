class Publication {
  final int? id;
  String contenuMessage;
  final String auteur;
  final DateTime datePublication;
  int nombreLikes;
  int nombreCommentaires;
  bool aime;
  String? image;

  Publication({
    this.id,
    required this.contenuMessage,
    required this.auteur,
    required this.datePublication,
    required this.nombreLikes,
    required this.nombreCommentaires,
    this.aime = false,
    this.image,
  });
}