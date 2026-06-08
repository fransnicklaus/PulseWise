String medicationStatusUiLabel(String? status) {
  switch ((status ?? 'open').toLowerCase()) {
    case 'taken':
      return 'Selesai';
    case 'missed':
      return 'Terlewat';
    case 'skipped':
      return 'Dilewati';
    case 'open':
      return 'Belum Ditandai';
    default:
      return (status == null || status.trim().isEmpty) ? '-' : status;
  }
}
