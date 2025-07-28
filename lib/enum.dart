enum Tags {
  work,
  private,
  money,
  other;

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
    }
  }
}

List<Tags> tags = [Tags.work, Tags.private, Tags.money, Tags.other];