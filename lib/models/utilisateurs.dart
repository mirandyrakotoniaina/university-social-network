class Utilisateur {
  final String? id;
  final String nom;
  final String email;
  final String role;

  Utilisateur({
    this.id,
    required this.nom,
    required this.email,
    this.role = 'membre',
  });
}