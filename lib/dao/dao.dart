abstract class Dao<T> {
  Future<void> add(T dto);
  Future<T?> getById(String id);
  Future<void> update(T dto);
  Future<void> delete(T dto);
}