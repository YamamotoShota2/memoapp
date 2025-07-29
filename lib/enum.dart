enum Tags {
  work,
  private,
  money,
  other,
  none;

  String getString() {
    switch (this) {
      case Tags.work:
        return 'Work';
      case Tags.private:
        return 'Private';
      case Tags.money:
        return 'Money';
      case Tags.other:
        return 'Other';
      case Tags.none:
        return 'none';
    }
  }

  static Tags getEnum(String? value) {
    switch (value) {
      case 'Work':
        return Tags.work;
      case 'Private':
        return Tags.private;
      case 'Money':
        return Tags.money;
      case 'Other':
        return Tags.other;
      default:
        return Tags.none;
    }
  }
}

List<Tags> tags = [Tags.work, Tags.private, Tags.money, Tags.other];