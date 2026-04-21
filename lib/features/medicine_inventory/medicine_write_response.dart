class MedicineWriteResponse {
  const MedicineWriteResponse({
    required this.success,
    this.errorMessage,
    this.isQueuedForSync = false,
  });

  final bool success;
  final String? errorMessage;
  final bool isQueuedForSync;
}
