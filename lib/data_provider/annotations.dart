class Column {
  final String name;
  final bool primaryKey;

  const Column(this.name, {this.primaryKey = false});
}

class ForeignKey {
  final String table;
  final String column;

  const ForeignKey(this.table, this.column);
}