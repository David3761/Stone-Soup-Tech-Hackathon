import 'note_type.dart';

enum SortField { updatedAt, createdAt, title }

enum SortDirection { ascending, descending }

class NoteFilter {
  final String searchQuery;
  final NoteType? typeFilter;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final SortField sortBy;
  final SortDirection sortDirection;

  const NoteFilter({
    this.searchQuery = '',
    this.typeFilter,
    this.createdAfter,
    this.createdBefore,
    this.sortBy = SortField.updatedAt,
    this.sortDirection = SortDirection.descending,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      typeFilter != null ||
      createdAfter != null ||
      createdBefore != null;

  NoteFilter copyWith({
    String? searchQuery,
    Object? typeFilter = _sentinel,
    Object? createdAfter = _sentinel,
    Object? createdBefore = _sentinel,
    SortField? sortBy,
    SortDirection? sortDirection,
  }) {
    return NoteFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: typeFilter == _sentinel
          ? this.typeFilter
          : typeFilter as NoteType?,
      createdAfter: createdAfter == _sentinel
          ? this.createdAfter
          : createdAfter as DateTime?,
      createdBefore: createdBefore == _sentinel
          ? this.createdBefore
          : createdBefore as DateTime?,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}

const _sentinel = Object();
