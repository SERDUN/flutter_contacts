package co.quis.flutter_contacts.crud.utils

import android.content.ContentResolver

/// AST node for the composable filter expression sent from Dart.
///
/// Mirrors `AndroidContactFilter` in `lib/models/android/android_contact_filter.dart`.
/// Each subtype evaluates to a set of contact IDs that pass the predicate.
sealed class AndroidContactFilter {
    data class HasDataMimetype(val mimetypes: Set<String>) : AndroidContactFilter()

    data class HasAccountType(val accountTypes: Set<String>) : AndroidContactFilter()

    data class And(val children: List<AndroidContactFilter>) : AndroidContactFilter()

    data class Or(val children: List<AndroidContactFilter>) : AndroidContactFilter()

    companion object {
        /// Parses the JSON map produced by `AndroidContactFilter.toJson()` in Dart.
        /// Returns `null` if [json] is `null`. Throws `IllegalArgumentException` on
        /// an unknown `type` discriminator.
        @Suppress("UNCHECKED_CAST")
        fun fromJson(json: Map<String, Any?>?): AndroidContactFilter? {
            if (json == null) return null
            return when (val type = json["type"] as? String) {
                "hasDataMimetype" -> {
                    val mimetypes = (json["mimetypes"] as? List<*>).orEmpty()
                        .filterIsInstance<String>()
                        .toSet()
                    HasDataMimetype(mimetypes)
                }
                "hasAccountType" -> {
                    val accountTypes = (json["accountTypes"] as? List<*>).orEmpty()
                        .filterIsInstance<String>()
                        .toSet()
                    HasAccountType(accountTypes)
                }
                "and" -> {
                    val children = (json["children"] as? List<*>).orEmpty()
                        .filterIsInstance<Map<String, Any?>>()
                        .mapNotNull { fromJson(it) }
                    And(children)
                }
                "or" -> {
                    val children = (json["children"] as? List<*>).orEmpty()
                        .filterIsInstance<Map<String, Any?>>()
                        .mapNotNull { fromJson(it) }
                    Or(children)
                }
                else -> throw IllegalArgumentException("Unknown AndroidContactFilter type: $type")
            }
        }
    }
}

object AndroidContactFilterEvaluator {
    /// Evaluates [filter] against [contentResolver] and returns the set of
    /// contact IDs that pass. Within [universe] only — useful when the caller
    /// has already constrained to a candidate set (e.g. via an account filter).
    ///
    /// Semantics:
    /// - [AndroidContactFilter.HasDataMimetype] / [HasAccountType] resolve to
    ///   the set returned by the corresponding native SQL query, intersected
    ///   with [universe].
    /// - [AndroidContactFilter.And] with empty children returns [universe]
    ///   (vacuous truth).
    /// - [AndroidContactFilter.Or] with empty children returns the empty set
    ///   (vacuous falsehood).
    fun evaluate(
        contentResolver: ContentResolver,
        filter: AndroidContactFilter,
        universe: Set<String>,
    ): Set<String> =
        when (filter) {
            is AndroidContactFilter.HasDataMimetype -> {
                if (filter.mimetypes.isEmpty()) {
                    emptySet()
                } else {
                    ContactFilterUtils
                        .getContactIdsByDataMimetypes(contentResolver, filter.mimetypes)
                        .toSet()
                        .intersect(universe)
                }
            }
            is AndroidContactFilter.HasAccountType -> {
                if (filter.accountTypes.isEmpty()) {
                    emptySet()
                } else {
                    ContactFilterUtils
                        .getContactIdsByAccountTypes(contentResolver, filter.accountTypes)
                        .toSet()
                        .intersect(universe)
                }
            }
            is AndroidContactFilter.And -> {
                if (filter.children.isEmpty()) {
                    universe
                } else {
                    filter.children.fold(universe) { acc, child ->
                        if (acc.isEmpty()) acc else acc.intersect(evaluate(contentResolver, child, acc))
                    }
                }
            }
            is AndroidContactFilter.Or -> {
                if (filter.children.isEmpty()) {
                    emptySet()
                } else {
                    val result = mutableSetOf<String>()
                    for (child in filter.children) {
                        result.addAll(evaluate(contentResolver, child, universe))
                        if (result.size == universe.size) break
                    }
                    result
                }
            }
        }
}
