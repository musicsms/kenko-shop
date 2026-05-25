String formatDropCountdown(DateTime? endsAt, DateTime now) {
  if (endsAt == null) {
    return '';
  }

  final remaining = endsAt.difference(now);
  if (remaining.inMinutes <= 0) {
    return 'Drop ended';
  }

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m left';
  }

  return '${remaining.inMinutes}m left';
}
