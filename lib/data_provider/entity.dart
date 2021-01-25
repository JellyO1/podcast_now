
enum EntityState { detached, unchanged, added, deleted, modified }
// TODO: Create a EntityChangeTracker and implement it
class Entity {
  final String name;
  EntityState state;

  Entity(this.name, {EntityState state}) : state = state ?? EntityState.added;

//  EntityChangeTracker _entityChangeTracker;
//  _DetachedEntityChangeTracker _detachedEntityChangeTracker;

//  @override
//  EntityChangeTracker get entityChangeTracker => _entityChangeTracker ?? _detachedEntityChangeTracker;
}

abstract class EntityChangeTracker {
  /// Notifies the change tracker of a pending change to a property of an entity type.
  /// [entityMemberName] is the name of the property that is changing.
  void entityMemberChanging(String entityMemberName);

  /// Notifies the change tracker that a property of an entity type has changed.
  /// [entityMemberName] is the name of the property that has changed.
  void entityMemberChanged(String entityMemberName);

  /// Gets the current state of a tracked object.
  EntityState get entityState;
}

abstract class EntityWithChangeTracker {
  final EntityChangeTracker entityChangeTracker;

  EntityWithChangeTracker(this.entityChangeTracker);
}

class _DetachedEntityChangeTracker implements EntityChangeTracker {
  @override
  void entityMemberChanged(String entityMemberName) {
  }

  @override
  void entityMemberChanging(String entityMemberName) {
  }

  @override
  EntityState get entityState => EntityState.detached;

}