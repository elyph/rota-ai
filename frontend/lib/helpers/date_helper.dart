class DateHelper {
  static const _months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];

  static String formatDate(DateTime? date) {
    if (date == null) return 'Seçiniz';
    return '${date.day} ${_months[date.month - 1]} ${date.year}';
  }
}
