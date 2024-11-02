import 'package:postgres/postgres.dart';

class PostgresDatabase {
  final PostgreSQLConnection connection = PostgreSQLConnection(
    'localhost',
    5432,
    'postgres',
    username: 'iwasuji',
    password: '',
  );
  static final PostgresDatabase _instance = PostgresDatabase._singelton();

  PostgresDatabase._singelton();

  factory PostgresDatabase() {
    print('has connection!');
    return _instance;
  }
}