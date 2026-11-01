import 'package:flutter/foundation.dart';

import '../models/mchd_record.dart';

/// Контракт локального реестра МЧД. В текущем прототипе реализация хранит
/// сведения только в памяти процесса и не отправляет ничего в СФР.
abstract class MchdRepository extends ChangeNotifier {
  List<MchdRecord> get records;
  List<MchdAuditEntry> get auditEntries;

  Future<void> save(MchdRecord record);
  Future<void> addExistingForReview(MchdRecord record);
  Future<void> deleteDraft(String id);
}
