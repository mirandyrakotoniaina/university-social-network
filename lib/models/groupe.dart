import 'publication.dart';
class Groupe {
  final int? id;
  String nom;
  String description;
  int nombreMembres;
  String type;
  final String image;
  final List<Publication> publications;

  Groupe({
    this.id,
    required this.nom,
    required this.description,
    required this.nombreMembres,
    required this.type,
    required this.image,
    required this.publications,
  });
}