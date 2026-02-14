/// Helpers pour le parsing JSON
/// Gère les conversions entre String et int qui peuvent arriver du backend
library;

/// Parse un int qui peut être une String
int parseInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Nettoie une chaîne de caractères des backslashes d'échappement
String cleanString(String? text) {
  if (text == null) return '';
  // Remplace les backslashes d'échappement devant les apostrophes
  return text.replaceAll(r"\'", "'").replaceAll(r'\"', '"');
}

/// Parse un int nullable qui peut être une String
int? parseIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

/// Parse un double qui peut être une String
double parseDouble(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Parse un double nullable qui peut être une String
double? parseDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
