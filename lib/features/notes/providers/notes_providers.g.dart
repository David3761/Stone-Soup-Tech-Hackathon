// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notesListHash() => r'bb291363fb75dda2d43a356bbe4bad12259f44a5';

/// See also [notesList].
@ProviderFor(notesList)
final notesListProvider =
    AutoDisposeStreamProvider<List<NoteWithItems>>.internal(
      notesList,
      name: r'notesListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notesListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotesListRef = AutoDisposeStreamProviderRef<List<NoteWithItems>>;
String _$noteFilterNotifierHash() =>
    r'c5584efc40373646fcd9e709ae18595ccf13817c';

/// See also [NoteFilterNotifier].
@ProviderFor(NoteFilterNotifier)
final noteFilterNotifierProvider =
    AutoDisposeNotifierProvider<NoteFilterNotifier, NoteFilter>.internal(
      NoteFilterNotifier.new,
      name: r'noteFilterNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$noteFilterNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NoteFilterNotifier = AutoDisposeNotifier<NoteFilter>;
String _$noteEditorNotifierHash() =>
    r'fc171ee0aa394b59bf5ef1a82093e5fe72e0a538';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$NoteEditorNotifier
    extends BuildlessAutoDisposeAsyncNotifier<NoteEditorState> {
  late final int? noteId;

  FutureOr<NoteEditorState> build(int? noteId);
}

/// See also [NoteEditorNotifier].
@ProviderFor(NoteEditorNotifier)
const noteEditorNotifierProvider = NoteEditorNotifierFamily();

/// See also [NoteEditorNotifier].
class NoteEditorNotifierFamily extends Family<AsyncValue<NoteEditorState>> {
  /// See also [NoteEditorNotifier].
  const NoteEditorNotifierFamily();

  /// See also [NoteEditorNotifier].
  NoteEditorNotifierProvider call(int? noteId) {
    return NoteEditorNotifierProvider(noteId);
  }

  @override
  NoteEditorNotifierProvider getProviderOverride(
    covariant NoteEditorNotifierProvider provider,
  ) {
    return call(provider.noteId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'noteEditorNotifierProvider';
}

/// See also [NoteEditorNotifier].
class NoteEditorNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          NoteEditorNotifier,
          NoteEditorState
        > {
  /// See also [NoteEditorNotifier].
  NoteEditorNotifierProvider(int? noteId)
    : this._internal(
        () => NoteEditorNotifier()..noteId = noteId,
        from: noteEditorNotifierProvider,
        name: r'noteEditorNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$noteEditorNotifierHash,
        dependencies: NoteEditorNotifierFamily._dependencies,
        allTransitiveDependencies:
            NoteEditorNotifierFamily._allTransitiveDependencies,
        noteId: noteId,
      );

  NoteEditorNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.noteId,
  }) : super.internal();

  final int? noteId;

  @override
  FutureOr<NoteEditorState> runNotifierBuild(
    covariant NoteEditorNotifier notifier,
  ) {
    return notifier.build(noteId);
  }

  @override
  Override overrideWith(NoteEditorNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: NoteEditorNotifierProvider._internal(
        () => create()..noteId = noteId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        noteId: noteId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<NoteEditorNotifier, NoteEditorState>
  createElement() {
    return _NoteEditorNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NoteEditorNotifierProvider && other.noteId == noteId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, noteId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin NoteEditorNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<NoteEditorState> {
  /// The parameter `noteId` of this provider.
  int? get noteId;
}

class _NoteEditorNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          NoteEditorNotifier,
          NoteEditorState
        >
    with NoteEditorNotifierRef {
  _NoteEditorNotifierProviderElement(super.provider);

  @override
  int? get noteId => (origin as NoteEditorNotifierProvider).noteId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
