/// Modèle MessageChat pour le chat de campagne
library;

/// Type de message
enum MessageType {
  player('player'),
  mj('mj'),
  system('system'),
  dice('dice');

  const MessageType(this.value);
  final String value;

  static MessageType fromValue(String? value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.player,
    );
  }
}

/// Modèle MessageChat
class MessageChat {
  final int id;
  final int campagneId;
  final int? personnageId;
  final String? personnageNom;
  final String? avatarUrl;
  final String contenu;
  final MessageType type;
  final DateTime timestamp;
  final bool estMj;

  const MessageChat({
    required this.id,
    required this.campagneId,
    this.personnageId,
    this.personnageNom,
    this.avatarUrl,
    required this.contenu,
    this.type = MessageType.player,
    required this.timestamp,
    this.estMj = false,
  });

  factory MessageChat.fromJson(Map<String, dynamic> json) {
    return MessageChat(
      id: json['id'] as int,
      campagneId: json['campagne_id'] as int,
      personnageId: json['personnage_id'] as int?,
      personnageNom: json['personnage_nom'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      contenu: json['contenu'] as String,
      type: MessageType.fromValue(json['type'] as String?),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      estMj: json['est_mj'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'campagne_id': campagneId,
      'personnage_id': personnageId,
      'personnage_nom': personnageNom,
      'avatar_url': avatarUrl,
      'contenu': contenu,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'est_mj': estMj,
    };
  }

  /// Alias pour compatibilité avec les écrans
  int? get expediteurId => personnageId;
  String? get expediteurNom => personnageNom;

  /// Nom affiché dans le chat
  String get displayName {
    if (estMj) return 'MJ';
    if (type == MessageType.system) return 'Système';
    return personnageNom ?? 'Inconnu';
  }

  /// Vérifie si c'est un message système
  bool get isSystem => type == MessageType.system;

  /// Vérifie si c'est un résultat de dé
  bool get isDice => type == MessageType.dice;

  @override
  String toString() => 'MessageChat(id: $id, from: $displayName)';
}

/// Message en attente d'envoi (optimistic UI)
class PendingMessage {
  final String tempId;
  final int campagneId;
  final int? personnageId;
  final String contenu;
  final DateTime timestamp;
  final bool isSending;
  final String? error;

  const PendingMessage({
    required this.tempId,
    required this.campagneId,
    this.personnageId,
    required this.contenu,
    required this.timestamp,
    this.isSending = true,
    this.error,
  });

  PendingMessage copyWith({
    bool? isSending,
    String? error,
  }) {
    return PendingMessage(
      tempId: tempId,
      campagneId: campagneId,
      personnageId: personnageId,
      contenu: contenu,
      timestamp: timestamp,
      isSending: isSending ?? this.isSending,
      error: error ?? this.error,
    );
  }
}
