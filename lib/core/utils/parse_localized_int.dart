int? parseLocalizedInt(String? value) {
  if (value == null) return null;
  final normalized = value.trim().replaceAllMapped(RegExp(r'[٠-٩۰-۹０-９]'), (
    match,
  ) {
    final digit = match.group(0)!.codeUnitAt(0);
    final zero = digit >= 0xFF10
        ? 0xFF10
        : digit >= 0x06F0
        ? 0x06F0
        : 0x0660;
    return '${digit - zero}';
  });
  return int.tryParse(normalized);
}
