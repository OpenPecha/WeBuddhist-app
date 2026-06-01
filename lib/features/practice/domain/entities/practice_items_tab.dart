/// Domain-level tab filter for `GET /practice/items`.
///
/// Kept in the domain layer so use-cases/repositories don't depend on data
/// implementation files.
enum PracticeItemsTab {
  all,
  series,
  plans;

  String toQueryValue() => switch (this) {
    PracticeItemsTab.all => 'all',
    PracticeItemsTab.series => 'series',
    PracticeItemsTab.plans => 'plans',
  };
}
