class EngineerDto {
  final int engineer_id;
  final String first_name;
  final String last_name;
  final int age;
  final int years_of_experience;
  final String nearest_station_line_name;
  final String nearest_station_name;
  final String coding_languages;

  const EngineerDto({
    required this.engineer_id,
    required this.first_name,
    required this.last_name,
    required this.age,
    required this.years_of_experience,
    required this.nearest_station_line_name,
    required this.nearest_station_name,
    required this.coding_languages
  });
}