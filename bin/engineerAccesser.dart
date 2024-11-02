import 'package:skill_search_model/dao/engineer_repository.dart';
import 'package:skill_search_model/db/postgres_database.dart';

Future<void> engineerAccesser(List<String> arguments) async {
  final enRepo = EngineerRepository();
  try {
    await PostgresDatabase().connection.open();
    final user = await enRepo.getById('1');
    print('name: ${user?.last_name}');
// logger.d("'検索ボタン押下　キーワードdb: ${user?.last_name}'");
    await PostgresDatabase().connection.close();
  } catch (e) {
    print(e);
  }
}
