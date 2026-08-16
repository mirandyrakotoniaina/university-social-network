class Utilisateur {
  final int? id;
  String nom;
  String email;
  String role;

  Utilisateur({
    this.id,
    required this.nom,
    required this.email,
    this.role = "membre",
  });
}