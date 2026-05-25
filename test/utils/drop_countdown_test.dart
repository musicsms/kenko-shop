import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/utils/drop_countdown.dart';

void main() {
  test('returns empty label when drop end is null', () {
    expect(formatDropCountdown(null, DateTime(2026, 5, 25, 8)), '');
  });

  test('formats minutes remaining', () {
    final now = DateTime(2026, 5, 25, 8);
    final endsAt = DateTime(2026, 5, 25, 8, 45);

    expect(formatDropCountdown(endsAt, now), '45m left');
  });

  test('rounds positive sub-minute drops up to one minute', () {
    final now = DateTime(2026, 5, 25, 8, 0, 0);
    final endsAt = DateTime(2026, 5, 25, 8, 0, 30);

    expect(formatDropCountdown(endsAt, now), '1m left');
  });

  test('formats hours and minutes remaining', () {
    final now = DateTime(2026, 5, 25, 8);
    final endsAt = DateTime(2026, 5, 25, 10, 30);

    expect(formatDropCountdown(endsAt, now), '2h 30m left');
  });

  test('formats expired drop', () {
    final now = DateTime(2026, 5, 25, 8);
    final endsAt = DateTime(2026, 5, 25, 7, 59);

    expect(formatDropCountdown(endsAt, now), 'Drop ended');
  });
}
