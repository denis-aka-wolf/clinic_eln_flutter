import 'package:flutter/foundation.dart';

import '../models/eln_record.dart';

class AuditEntry {
  const AuditEntry({
    required this.at,
    required this.action,
    required this.result,
    required this.details,
  });

  final DateTime at;
  final String action;
  final String result;
  final String details;
}

abstract class ElnRepository extends ChangeNotifier {
  List<ElnRecord> get records;
  List<AuditEntry> get auditEntries;
  Future<void> saveDraft(ElnRecord record);
  Future<void> deleteDraft(String id);
}
