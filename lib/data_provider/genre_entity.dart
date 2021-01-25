import 'annotations.dart';
import 'entity.dart';

class Genre extends Entity {
  @Column("id", primaryKey: true)
  int _id;
  int get id => _id;
  set id(int value) {
    _setState();
    _id = value;
  }

  @Column("page", primaryKey: true)
  int _page;
  int get page => _page;
  set page(int value) {
    _setState();
    _page = value;
  }

  Genre(int id, int page) : _id = id, _page = page, super("Genres");

  _setState() {
    if (state == EntityState.deleted) throw new Exception("A deleted entity cannot have it's members changed");

    state = EntityState.modified;
  }

  Map<String, dynamic> toJson() {
    var val = {"id": id, "page": page};

    if(state == EntityState.modified)
      val.remove("id");

    return val;
  }
}
