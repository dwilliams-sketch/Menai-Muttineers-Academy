class CelebrationMessage {
  final String id;
  final String title;
  final String body;
  final String emoji;
  const CelebrationMessage(this.id, this.title, this.body, this.emoji);
}

class CelebrationService {
  static List<CelebrationMessage> forDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final items = <CelebrationMessage>[];
    void add(String id, String title, String body, String emoji) => items.add(CelebrationMessage(id, title, body, emoji));

    if (d.month == 1 && d.day == 1) add('new_year', 'Happy New Year!', 'A fresh year, a fresh voyage and plenty of good training ahead.', '🎆');
    if (d.month == 3 && d.day == 1) add('st_davids', 'Dydd Gŵyl Dewi Hapus!', 'Happy St David’s Day from the Menai Muttineers crew.', '🐉');
    if (d.month == 4 && d.day == 11) add('pet_day', 'National Pet Day', 'Give your four-legged shipmate an extra bit of fuss today.', '🐾');
    if (d.month == 8 && d.day == 16) add('rum_day', 'National Rum Day', 'A suitably pirate-themed day. The dogs are on water, mind!', '🏴‍☠️');
    if (d.month == 8 && d.day == 26) add('dog_day', 'National Dog Day', 'Today is all about the dogs — as if every Academy day wasn’t already!', '🐕');
    if (d.month == 9 && d.day == 19) add('pirate_day', 'Talk Like a Pirate Day', 'Arrr! Today the Academy officially permits excessive pirate nonsense.', '🏴‍☠️');
    if (d.month == 10 && d.day == 4) add('animal_day', 'World Animal Day', 'A good day to celebrate every animal that makes life better.', '🐾');
    if (d.month == 12 && d.day == 25) add('christmas', 'Merry Christmas!', 'Merry Christmas from the whole Menai Muttineers crew.', '🎄');
    if (d.month == 12 && d.day == 26) add('boxing_day', 'Boxing Day', 'A day for leftovers, muddy walks and perhaps a very short training game.', '🎁');

    final easter = _easterSunday(d.year);
    final goodFriday = easter.subtract(const Duration(days: 2));
    final easterMonday = easter.add(const Duration(days: 1));
    if (_same(d, goodFriday)) add('good_friday_${d.year}', 'Good Friday', 'Wishing the crew a peaceful bank holiday weekend.', '⚓');
    if (_same(d, easterMonday)) add('easter_monday_${d.year}', 'Easter Monday', 'A bank holiday Monday — a handy day for a little dog training adventure.', '🌷');

    final earlyMay = _nthWeekday(d.year, 5, DateTime.monday, 1);
    final spring = _lastWeekday(d.year, 5, DateTime.monday);
    final summer = _lastWeekday(d.year, 8, DateTime.monday);
    if (_same(d, earlyMay)) add('early_may_${d.year}', 'Early May Bank Holiday', 'A bank holiday voyage — enjoy the extra day with your dog.', '🌿');
    if (_same(d, spring)) add('spring_bank_${d.year}', 'Spring Bank Holiday', 'Enjoy the bank holiday, crew. Keep any training short and fun.', '☀️');
    if (_same(d, summer)) add('summer_bank_${d.year}', 'Summer Bank Holiday', 'A summer bank holiday from the Academy crew.', '🏖️');

    final newYearObserved = _newYearObserved(d.year);
    final christmasObserved = _christmasObserved(d.year);
    final boxingObserved = _boxingObserved(d.year);
    if (_same(d, newYearObserved) && !(d.month == 1 && d.day == 1)) add('new_year_bank_${d.year}', 'New Year Bank Holiday', 'Enjoy the New Year bank holiday with your dog.', '🎆');
    if (_same(d, christmasObserved) && !(d.month == 12 && d.day == 25)) add('christmas_bank_${d.year}', 'Christmas Bank Holiday', 'An extra Christmas bank holiday day for the crew.', '🎄');
    if (_same(d, boxingObserved) && !(d.month == 12 && d.day == 26)) add('boxing_bank_${d.year}', 'Boxing Day Bank Holiday', 'Enjoy the Boxing Day bank holiday, crew.', '🎁');

    return items;
  }

  static DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static DateTime _nthWeekday(int year, int month, int weekday, int n) {
    var d = DateTime(year, month, 1);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    return d.add(Duration(days: 7 * (n - 1)));
  }

  static DateTime _lastWeekday(int year, int month, int weekday) {
    var d = DateTime(year, month + 1, 0);
    while (d.weekday != weekday) {
      d = d.subtract(const Duration(days: 1));
    }
    return d;
  }

  static DateTime _newYearObserved(int year) {
    final d = DateTime(year, 1, 1);
    if (d.weekday == DateTime.saturday) return DateTime(year, 1, 3);
    if (d.weekday == DateTime.sunday) return DateTime(year, 1, 2);
    return d;
  }

  static DateTime _christmasObserved(int year) {
    final d = DateTime(year, 12, 25);
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) return DateTime(year, 12, 27);
    return d;
  }

  static DateTime _boxingObserved(int year) {
    final d = DateTime(year, 12, 26);
    if (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday) return DateTime(year, 12, 28);
    return d;
  }

  static bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
