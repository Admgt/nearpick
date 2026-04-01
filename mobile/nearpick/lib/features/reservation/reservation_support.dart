class CancellationReasonOption {
  final String code;
  final String label;

  const CancellationReasonOption({required this.code, required this.label});
}

class RefundStatusOption {
  final String code;
  final String label;

  const RefundStatusOption({required this.code, required this.label});
}

const cancellationReasonOptions = <CancellationReasonOption>[
  CancellationReasonOption(code: 'changed_mind', label: 'Meggondoltam magam'),
  CancellationReasonOption(
    code: 'pickup_time_issue',
    label: 'Nem jo az atveteli ido',
  ),
  CancellationReasonOption(
    code: 'found_other_offer',
    label: 'Masik ajanlatot valasztottam',
  ),
  CancellationReasonOption(
    code: 'ordered_by_mistake',
    label: 'Veletlen foglalas volt',
  ),
  CancellationReasonOption(code: 'other', label: 'Egyeb ok'),
];

const merchantRefundStatusOptions = <RefundStatusOption>[
  RefundStatusOption(code: 'pending', label: 'Fuggoben'),
  RefundStatusOption(code: 'approved', label: 'Jovahagyva'),
  RefundStatusOption(code: 'rejected', label: 'Elutasitva'),
  RefundStatusOption(code: 'completed', label: 'Lezarva'),
  RefundStatusOption(code: 'not_required', label: 'Nem szukseges'),
];

String cancellationReasonLabel(String? code) {
  for (final option in cancellationReasonOptions) {
    if (option.code == code) {
      return option.label;
    }
  }
  return 'Nincs megadva';
}

String refundStatusLabel(String? status) {
  switch (status) {
    case 'pending':
      return 'Fuggoben';
    case 'approved':
      return 'Jovahagyva';
    case 'rejected':
      return 'Elutasitva';
    case 'completed':
      return 'Lezarva';
    case 'not_required':
      return 'Nem szukseges';
    default:
      return 'Nincs igeny';
  }
}
