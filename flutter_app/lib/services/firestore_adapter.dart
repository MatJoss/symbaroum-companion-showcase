import 'package:cloud_firestore/cloud_firestore.dart';

/// Small Firestore adapter helpers used when reading collections
/// Prefer reading by document id (fast), fallback to querying `id` field.
class FirestoreAdapter {
  final FirebaseFirestore _firestore;

  FirestoreAdapter({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Try to read a document by its document id (string). If missing, query by `id` field
  /// (numeric or string). Returns null if nothing found.
  Future<Map<String, dynamic>?> getByIdWithFallback(String collection, dynamic id) async {
    final idStr = id?.toString();
    if (idStr == null) return null;

    try {
      // Try doc ref by id first
      final docRef = _firestore.collection(collection).doc(idStr);
      final docSnap = await docRef.get();
      if (docSnap.exists) return _normalize(docSnap.data());

      // Fallback: query where 'id' == id (support numeric or string stored values)
      final querySnap = await _firestore.collection(collection).where('id', isEqualTo: id).limit(1).get();
      if (querySnap.docs.isNotEmpty) return _normalize(querySnap.docs.first.data());

      // Also try string value if stored as string
      final querySnap2 = await _firestore.collection(collection).where('id', isEqualTo: idStr).limit(1).get();
      if (querySnap2.docs.isNotEmpty) return _normalize(querySnap2.docs.first.data());

      return null;
    } catch (e) {
      // Let caller handle or log
      rethrow;
    }
  }

  /// Write a document optionally using an explicit docId (string). If docId is null
  /// Firestore auto-id will be used.
  Future<void> write(String collection, Map<String, dynamic> doc, {String? docId}) async {
    final ref = docId == null
        ? _firestore.collection(collection).doc()
        : _firestore.collection(collection).doc(docId);
    await ref.set(doc);
  }

  /// List all documents in a collection and return their data as maps.
  Future<List<Map<String, dynamic>>> listCollection(String collection) async {
    final snap = await _firestore.collection(collection).get();
    return snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
  }

  /// Query a collection by a single field equality and return matching documents.
  Future<List<Map<String, dynamic>>> queryCollection(String collection, String field, dynamic value) async {
    final snap = await _firestore.collection(collection).where(field, isEqualTo: value).get();
    return snap.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
  }

  /// Helper: normalize map (e.g. remove Firestore-specific types if needed)
  Map<String, dynamic>? _normalize(Map<String, dynamic>? data) {
    if (data == null) return null;
    // Noop for now; add conversion if you store Timestamps, etc.
    return Map<String, dynamic>.from(data);
  }
}
