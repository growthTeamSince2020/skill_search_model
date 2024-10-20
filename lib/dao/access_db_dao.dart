import 'package:skill_search_model/dao/access_db_dao.dart';
import 'package:postgres/postgres.dart';
import 'package:skill_search_model/db/postgres_database.dart';
import 'package:skill_search_model/dto/engineer_dto.dart';
import 'dao.dart';

class accessDbDao implements Dao<EngineerDto> {
  final PostgreSQLConnection db;

  accessDbDao() : db = PostgresDatabase().connection;

  @override
  Future<void> add(EngineerDto dto) async {
    try {
      await db.query(
        '''INSERT INTO public.engineer(engineer_id,first_name,last_name,age,years_of_experience,nearest_station_line_name,nearest_station_name,coding_languages)VALUES (nextval('engineer_id_seq'),@first_name,@last_name,@age,@years_of_experience,@nearest_station_line_name,@nearest_station_name,@coding_languages);''',
        substitutionValues: {'engineer_id': dto.engineer_id, 'first_name': dto.first_name,'last_name': dto.last_name,'age': dto.age,'years_of_experience': dto.years_of_experience,'nearest_station_line_name': dto.nearest_station_line_name,'nearest_station_name': dto.nearest_station_name,'coding_languages': dto.coding_languages},
      );
    } catch (e) {
      throw UserCouldNotBeAddedException('id: ${dto.engineer_id}');
    }
  }

  @override
  Future<void> delete(EngineerDto dto) async {
    try {
      await db.query(
        'DELETE FROM engineer WHERE engineer_id=@engineer_id',
        substitutionValues: {'id': dto.engineer_id},
      );
    } catch (e) {
      throw UserNotFoundException('id: ${dto.engineer_id}');
    }
  }

  @override
  Future<EngineerDto?> getById(String engineer_id) async {
    EngineerDto? user;

    try {
      final result = await db.mappedResultsQuery(
        'SELECT * FROM engineer WHERE engineer_id=@engineer_id',
        substitutionValues: {
          'engineer_id': engineer_id,
        },
      );

      user = EngineerDto(
        engineer_id: result[0]['engineer']?['engineer_id'],
        first_name: result[0]['engineer']?['first_name'],
        last_name: result[0]['engineer']?['last_name'],
        age: result[0]['engineer']?['age'],
      years_of_experience: result[0]['engineer']?['years_of_experience'],
      nearest_station_line_name: result[0]['engineer']?['nearest_station_line_name'],
      nearest_station_name: result[0]['engineer']?['nearest_station_name'],
      coding_languages: result[0]['engineer']?['coding_languages'],
      );
    } catch (e) {
      throw UserNotFoundException('engineer_id: $engineer_id');
    }

    return user;
  }

  @override
  Future<void> update(EngineerDto dto) async {
    try {
      await db.query(
        'UPDATE engineer SET first_name=@first_name ,last_name=@last_name WHERE engineer_id=@engineer_id',
        substitutionValues: {'first_name': dto.first_name, 'last_name': dto.last_name},
      );
    } catch (e) {
      throw UserCouldNotBeUpdatedException('engineer_id: ${dto.engineer_id}');
    }
  }
  }


class UserNotFoundException implements Exception {
  String message;

  UserNotFoundException(this.message);

  @override
  String toString() => 'DBNotFoundException | $message';
}

class UserCouldNotBeAddedException implements Exception {
  String message;

  UserCouldNotBeAddedException(this.message);

  @override
  String toString() => 'DBCouldNotBeAddedException | $message';
}

 class UserCouldNotBeUpdatedException implements Exception {
  String message;

  UserCouldNotBeUpdatedException(this.message);

  @override
  String toString() => 'DBCouldNotBeUpdateException | $message';
}