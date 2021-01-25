import 'entity.dart';

class Podcast extends Entity {

  String _id;
  String get id => _id;
  set id(String value) {
    _setState();
    _id = value;
  }

  int _genreId;
  int get genreId => _genreId;
  set genreId(int value) {
    _setState();
    genreId = value;
  }

  String _json;
  String get json => _json;
  set json(String value) {
    _setState();
    _json = value;
  }

  bool _isNew;
  bool get isNew => _isNew;
  set isNew(bool value) {
    _setState();
    _isNew = value;
  }

  Podcast(String id, int genreId, String json, bool isNew)
      : _id = id,
        _genreId = genreId,
        _json = json,
        _isNew = isNew,
        super("Podcasts");

  _setState() {
    if(state == EntityState.deleted)
      throw new Exception("A deleted entity cannot have it's members changed");

    state = EntityState.modified;
  }

  Map<String, dynamic> toJson() {
    var val = {
      "id" : id,
      "genre_id" : genreId,
      "json" : json,
      "is_new" : isNew ? 1 : 0,
    };

    if(state == EntityState.modified)
      val.remove("id");

    return val;
  }
}
