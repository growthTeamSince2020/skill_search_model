import 'dart:async';
import 'package:skill_search_model/dao/access_db_dao.dart';
import 'package:skill_search_model/dao/repository.dart';
import 'package:skill_search_model/dto/engineer_dto.dart';

class EngineerRepository implements Repository<EngineerDto> {

  @override
  Future<EngineerDto?> getById(String id) => accessDbDao().getById(id);

  @override
  Future<void> delete(EngineerDto dto) => accessDbDao().delete(dto);

  @override
  Future<void> add(EngineerDto dto) => accessDbDao().add(dto);

  @override
  Future<void> update(EngineerDto dto) => accessDbDao().update(dto);

}