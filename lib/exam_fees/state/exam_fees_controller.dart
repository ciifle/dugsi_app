import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext, InheritedWidget;

import 'package:kobac/exam_fees/models/exam_fee_models.dart';
import 'package:kobac/exam_fees/services/exam_fee_service.dart';
import 'package:kobac/services/academic_years_service.dart';
import 'package:kobac/services/classes_service.dart';
import 'package:kobac/services/exams_service.dart';
import 'package:kobac/services/pdf_file_result.dart';

enum ExamFeesTab { register, setup, payments }

typedef ExamsLoader = Future<ExamResult<List<ExamModel>>> Function(int yearId);
typedef ExamFeeClassesLoader =
    Future<ClassResult<List<ClassModel>>> Function(int yearId);

/// All Exam Fees state, shared by Android, phone-width PWA and desktop PWA.
/// Presentation never holds business state; it calls these methods.
///
/// Selector cascade: Academic Year -> Exam -> Class. Changing a parent clears
/// every dependent selection and the data loaded for it. Mutations never
/// edit rows locally: on success the affected data is reloaded from the
/// backend, on failure nothing changes.
class ExamFeesController extends ChangeNotifier {
  ExamFeesController({
    ExamFeeService? service,
    ExamsLoader? loadExams,
    ExamFeeClassesLoader? loadClasses,
    this.pageSize = 20,
  }) : _service = service ?? ExamFeeService(),
       _loadExams =
           loadExams ?? ((id) => ExamsService().listExams(academicYearId: id)),
       _loadClasses =
           loadClasses ??
           ((id) => ClassesService().listClasses(academicYearId: id));

  final ExamFeeService _service;
  final ExamsLoader _loadExams;
  final ExamFeeClassesLoader _loadClasses;
  final int pageSize;
  bool _disposed = false;

  /// Called once when the backend reports the module disabled
  /// (EXAM_FEE_CUSTOM_NOT_ENABLED) so navigation can hide it.
  VoidCallback? onFeatureDisabled;

  // Tokens discard responses that arrive after their selection changed.
  int _examsToken = 0, _classesToken = 0, _registerToken = 0;
  int _settingsToken = 0, _paymentsToken = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool featureDisabled = false;

  /// Inspects every failure; a feature denial locks the whole module.
  T _check<T extends ExamFeeResult<Object?>>(T result) {
    if (result is ExamFeeFailure && result.featureDisabled && !featureDisabled) {
      featureDisabled = true;
      onFeatureDisabled?.call();
      _notify();
    }
    return result;
  }

  ExamFeesTab tab = ExamFeesTab.register;

  void setTab(ExamFeesTab value) {
    if (tab == value) return;
    tab = value;
    _notify();
    ensureTabData();
  }

  // --- Selectors -------------------------------------------------------------

  List<AcademicYear> years = const [];
  int? yearId;

  List<ExamModel> exams = const [];
  bool examsLoading = false;
  String? examsError;
  int? examId;

  List<ClassModel> classes = const [];
  bool classesLoading = false;
  String? classesError;
  int? classId;

  ExamModel? get selectedExam {
    for (final e in exams) {
      if (e.id == examId) return e;
    }
    return null;
  }

  ClassModel? get selectedClass {
    for (final c in classes) {
      if (c.id == classId) return c;
    }
    return null;
  }

  AcademicYear? get selectedYear {
    for (final y in years) {
      if (y.id == yearId) return y;
    }
    return null;
  }

  void setYears(List<AcademicYear> value, AcademicYear? active) {
    years = value;
    if (yearId != null && years.any((y) => y.id == yearId)) {
      _notify();
      return;
    }
    final initial = active != null && years.any((y) => y.id == active.id)
        ? active.id
        : (years.isEmpty ? null : years.first.id);
    if (initial == null) {
      _notify();
      return;
    }
    selectYear(initial);
  }

  void selectYear(int id) {
    yearId = id;
    // Exams and classes belong to the year: clear everything below it.
    examId = null;
    exams = const [];
    classId = null;
    classes = const [];
    _resetData();
    _notify();
    loadExams();
    loadClasses();
    ensureTabData();
  }

  void selectExam(int? id) {
    if (id == examId) return;
    examId = id;
    _resetData();
    _notify();
    ensureTabData();
  }

  void selectClass(int? id) {
    if (id == classId) return;
    classId = id;
    _clearRegister();
    _paymentsStale = true;
    _notify();
    ensureTabData();
  }

  Future<void> loadExams() async {
    final year = yearId;
    if (year == null) return;
    final token = ++_examsToken;
    examsLoading = true;
    examsError = null;
    _notify();
    final r = await _loadExams(year);
    if (_disposed || token != _examsToken) return;
    examsLoading = false;
    if (r is ExamSuccess<List<ExamModel>>) {
      // The backend rejects exams of another year (EXAM_ACADEMIC_YEAR_MISMATCH).
      exams = r.data
          .where((e) => e.academicYearId == null || e.academicYearId == year)
          .toList();
    } else {
      exams = const [];
      examsError = (r as ExamError).message;
    }
    _notify();
  }

  Future<void> loadClasses() async {
    final year = yearId;
    if (year == null) return;
    final token = ++_classesToken;
    classesLoading = true;
    classesError = null;
    _notify();
    final r = await _loadClasses(year);
    if (_disposed || token != _classesToken) return;
    classesLoading = false;
    if (r is ClassSuccess<List<ClassModel>>) {
      classes = r.data;
    } else {
      classes = const [];
      classesError = (r as ClassError).message;
    }
    _notify();
  }

  void _resetData() {
    _clearRegister();
    _settingsToken++;
    settings = null;
    settingsError = null;
    settingsLoading = false;
    _settingsStale = true;
    _paymentsToken++;
    paymentsPage = null;
    paymentsError = null;
    paymentsLoading = false;
    page = 1;
    _paymentsStale = true;
  }

  void _clearRegister() {
    _registerToken++;
    register = null;
    registerError = null;
    registerLoading = false;
    selection.clear();
    _registerStale = true;
  }

  bool _registerStale = true, _settingsStale = true, _paymentsStale = true;

  /// Loads whatever the visible tab needs and is stale.
  void ensureTabData() {
    if (featureDisabled) return;
    switch (tab) {
      case ExamFeesTab.register:
        if (_registerStale) loadRegister();
      case ExamFeesTab.setup:
        if (_settingsStale) loadSettings();
      case ExamFeesTab.payments:
        if (_paymentsStale) loadPayments();
    }
  }

  // --- Register ---------------------------------------------------------------

  ExamFeeRegister? register;
  bool registerLoading = false;
  ExamFeeFailure? registerError;

  /// Selected student_exam_fee ids for bulk collection (payable rows only).
  final Set<int> selection = {};

  Future<void> loadRegister() async {
    final year = yearId, exam = examId, cls = classId;
    if (year == null || exam == null || cls == null) return;
    final token = ++_registerToken;
    _registerStale = false;
    registerLoading = true;
    registerError = null;
    _notify();
    final r = _check(
      await _service.getRegister(academicYearId: year, examId: exam, classId: cls),
    );
    if (_disposed || token != _registerToken) return;
    registerLoading = false;
    if (r is ExamFeeSuccess<ExamFeeRegister>) {
      register = r.data;
      // Keep only selections that are still payable after a reload.
      final payable = {
        for (final s in r.data.students)
          if (s.selectable) s.id,
      };
      selection.removeWhere((id) => !payable.contains(id));
    } else {
      register = null;
      selection.clear();
      registerError = r as ExamFeeFailure;
    }
    _notify();
  }

  StudentExamFee? feeById(int id) {
    for (final s in register?.students ?? const <StudentExamFee>[]) {
      if (s.id == id) return s;
    }
    return null;
  }

  void toggleSelection(int feeId) {
    final fee = feeById(feeId);
    if (fee == null || !fee.selectable) return;
    if (!selection.remove(feeId)) selection.add(feeId);
    _notify();
  }

  List<StudentExamFee> get selectableRows =>
      (register?.students ?? const <StudentExamFee>[])
          .where((s) => s.selectable)
          .toList();

  bool get allSelectableSelected =>
      selectableRows.isNotEmpty &&
      selectableRows.every((s) => selection.contains(s.id));

  void toggleSelectAll() {
    if (allSelectableSelected) {
      selection.clear();
    } else {
      selection
        ..clear()
        ..addAll(selectableRows.map((s) => s.id));
    }
    _notify();
  }

  void clearSelection() {
    if (selection.isEmpty) return;
    selection.clear();
    _notify();
  }

  List<StudentExamFee> get selectedFees => [
    for (final s in register?.students ?? const <StudentExamFee>[])
      if (selection.contains(s.id)) s,
  ];

  // --- Mutations on one student's fee ------------------------------------------

  bool mutating = false;

  Future<ExamFeeResult<T>> _mutate<T>(
    Future<ExamFeeResult<T>> Function() call, {
    bool refreshRegister = true,
    bool refreshPayments = false,
  }) async {
    if (mutating) {
      return ExamFeeFailure('Please wait for the current action to finish.');
    }
    mutating = true;
    _notify();
    final r = _check(await call());
    mutating = false;
    if (r is ExamFeeSuccess) {
      if (refreshRegister) _registerStale = true;
      if (refreshPayments) _paymentsStale = true;
      _settingsStale = true;
      _notify();
      if (refreshRegister) await loadRegister();
      if (refreshPayments && tab == ExamFeesTab.payments) await loadPayments();
    } else {
      _notify();
    }
    return r;
  }

  Future<ExamFeeResult<StudentFeeDetail>> updateAmount(
    StudentExamFee fee, {
    required double amount,
    required String reason,
  }) => _mutate(
    () => _service.updateStudentFeeAmount(fee.id, amount: amount, reason: reason),
  );

  Future<ExamFeeResult<StudentFeeDetail>> waive(
    StudentExamFee fee, {
    required String reason,
  }) => _mutate(() => _service.waiveStudentFee(fee.id, reason: reason));

  Future<ExamFeeResult<StudentFeeDetail>> unwaive(StudentExamFee fee) =>
      _mutate(() => _service.unwaiveStudentFee(fee.id));

  Future<ExamFeeResult<PaymentRecordResult>> recordPayment(
    StudentExamFee fee, {
    required double amount,
    required String method,
    String? referenceNumber,
    String? notes,
  }) => _mutate(
    () => _service.recordPayment(
      studentExamFeeId: fee.id,
      amount: amount,
      method: method,
      referenceNumber: referenceNumber,
      notes: notes,
    ),
    refreshPayments: true,
  );

  /// Atomic bulk collection. On failure no row is touched locally; the
  /// failure carries per-student [ExamFeeFailure.entryErrors].
  Future<ExamFeeResult<BulkCollectionResult>> collectBulk({
    required List<BulkCollectEntry> entries,
    required String method,
    String? referenceNumber,
    String? notes,
  }) async {
    final year = yearId, exam = examId, cls = classId;
    if (year == null || exam == null || cls == null) {
      return ExamFeeFailure('Select an academic year, exam and class first.');
    }
    final r = await _mutate(
      () => _service.collectBulk(
        academicYearId: year,
        examId: exam,
        classId: cls,
        method: method,
        entries: entries,
        referenceNumber: referenceNumber,
        notes: notes,
      ),
      refreshPayments: true,
    );
    if (r is ExamFeeSuccess) clearSelection();
    return r;
  }

  Future<ExamFeeResult<StudentFeeDetail>> loadStudentFee(int feeId) async =>
      _check(await _service.getStudentFee(feeId));

  // --- Setup & generation --------------------------------------------------------

  ExamFeeSettingsResult? settings;
  bool settingsLoading = false;
  ExamFeeFailure? settingsError;

  Future<void> loadSettings() async {
    final year = yearId, exam = examId;
    if (year == null || exam == null) return;
    final token = ++_settingsToken;
    _settingsStale = false;
    settingsLoading = true;
    settingsError = null;
    _notify();
    final r = _check(await _service.getSettings(academicYearId: year, examId: exam));
    if (_disposed || token != _settingsToken) return;
    settingsLoading = false;
    if (r is ExamFeeSuccess<ExamFeeSettingsResult>) {
      settings = r.data;
    } else {
      settings = null;
      settingsError = r as ExamFeeFailure;
    }
    _notify();
  }

  Future<ExamFeeResult<ExamFeeSetting?>> saveSetting(int classId, double amount) async {
    final year = yearId, exam = examId;
    if (year == null || exam == null) {
      return ExamFeeFailure('Select an academic year and exam first.');
    }
    final r = await _mutate(
      () => _service.saveSetting(
        academicYearId: year,
        examId: exam,
        classId: classId,
        amount: amount,
      ),
      refreshRegister: classId == this.classId,
    );
    if (r is ExamFeeSuccess) await loadSettings();
    return r;
  }

  Future<ExamFeeResult<bool>> deleteSetting(ExamFeeClassSetting row) async {
    final setting = row.setting;
    if (setting == null) return ExamFeeFailure('This class has no exam fee.');
    final r = await _mutate(
      () => _service.deleteSetting(setting.id),
      refreshRegister: row.classId == classId,
    );
    if (r is ExamFeeSuccess) await loadSettings();
    return r;
  }

  Future<ExamFeeResult<GenerationPreview>> previewGeneration(int classId) async {
    final year = yearId, exam = examId;
    if (year == null || exam == null) {
      return ExamFeeFailure('Select an academic year and exam first.');
    }
    return _check(
      await _service.previewGeneration(academicYearId: year, examId: exam, classId: classId),
    );
  }

  /// Class ids currently generating — repeated taps are ignored.
  final Set<int> generating = {};

  Future<ExamFeeResult<GenerationResult>?> generate(int classId) async {
    final year = yearId, exam = examId;
    if (year == null || exam == null || generating.contains(classId)) return null;
    generating.add(classId);
    _notify();
    try {
      final r = _check(
        await _service.generateFees(academicYearId: year, examId: exam, classId: classId),
      );
      if (r is ExamFeeSuccess) {
        _settingsStale = true;
        if (classId == this.classId) _registerStale = true;
        await loadSettings();
        if (classId == this.classId) await loadRegister();
      }
      return r;
    } finally {
      generating.remove(classId);
      _notify();
    }
  }

  // --- Payment history ---------------------------------------------------------

  ExamFeePaymentPage? paymentsPage;
  bool paymentsLoading = false;
  ExamFeeFailure? paymentsError;
  int page = 1;
  String? methodFilter;
  DateTime? startDate;
  DateTime? endDate;
  String search = '';

  static String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String? get dateRangeError =>
      startDate != null && endDate != null && startDate!.isAfter(endDate!)
      ? 'The start date must be on or before the end date.'
      : null;

  Future<void> loadPayments({int? toPage}) async {
    if (yearId == null || dateRangeError != null) return;
    if (toPage != null) page = toPage;
    final token = ++_paymentsToken;
    _paymentsStale = false;
    paymentsLoading = true;
    paymentsError = null;
    _notify();
    final r = _check(
      await _service.getPayments(
        academicYearId: yearId,
        examId: examId,
        classId: classId,
        method: methodFilter,
        startDate: startDate == null ? null : _ymd(startDate!),
        endDate: endDate == null ? null : _ymd(endDate!),
        search: search,
        page: page,
        limit: pageSize,
      ),
    );
    if (_disposed || token != _paymentsToken) return;
    paymentsLoading = false;
    if (r is ExamFeeSuccess<ExamFeePaymentPage>) {
      paymentsPage = r.data;
    } else {
      paymentsPage = null;
      paymentsError = r as ExamFeeFailure;
    }
    _notify();
  }

  /// Any filter change returns to page 1.
  void setPaymentFilters({
    Object? method = _keep,
    Object? start = _keep,
    Object? end = _keep,
    String? searchText,
  }) {
    if (method != _keep) methodFilter = method as String?;
    if (start != _keep) startDate = start as DateTime?;
    if (end != _keep) endDate = end as DateTime?;
    if (searchText != null) search = searchText;
    page = 1;
    _notify();
    loadPayments();
  }

  static const Object _keep = Object();

  Future<ExamFeeResult<ExamFeePayment>> loadPayment(int id) async =>
      _check(await _service.getPayment(id));

  // --- Receipts ------------------------------------------------------------------

  /// Payment ids whose receipt is downloading — repeated taps are ignored.
  final Set<int> receiptBusy = {};

  Future<ExamFeeResult<PdfFileResult>?> downloadReceipt(int paymentId) async {
    if (receiptBusy.contains(paymentId)) return null;
    receiptBusy.add(paymentId);
    _notify();
    try {
      return _check(await _service.downloadReceipt(paymentId));
    } finally {
      receiptBusy.remove(paymentId);
      _notify();
    }
  }
}

/// Session scope provided by SchoolAdminScreen above its mobile/desktop
/// switch, so every platform (and a breakpoint change) uses one controller.
class ExamFeesSessionScope extends InheritedWidget {
  final ExamFeesController controller;
  const ExamFeesSessionScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static ExamFeesController? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<ExamFeesSessionScope>()
      ?.controller;

  @override
  bool updateShouldNotify(ExamFeesSessionScope oldWidget) =>
      controller != oldWidget.controller;
}
