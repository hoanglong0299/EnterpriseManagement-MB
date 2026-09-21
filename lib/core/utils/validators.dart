String? requiredField(String? value, String message) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}