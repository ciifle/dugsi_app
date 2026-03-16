import 'package:flutter/material.dart';
import 'package:kobac/services/periods_service.dart';
import 'package:kobac/services/api_error_helpers.dart';
import 'package:kobac/school_admin/widgets/delete_confirm_dialog.dart';
import 'package:kobac/widgets/form_3d/form_3d.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kBgColor = Color(0xFFF0F3F7);
const double kCardRadius = 28.0;

class AdminPeriodsScreen extends StatefulWidget {
  const AdminPeriodsScreen({Key? key}) : super(key: key);

  @override
  State<AdminPeriodsScreen> createState() => _AdminPeriodsScreenState();
}

class _AdminPeriodsScreenState extends State<AdminPeriodsScreen> {
  late Future<PeriodResult<List<PeriodModel>>> _periodsFuture;

  @override
  void initState() {
    super.initState();
    _loadPeriods();
  }

  void _loadPeriods() {
    setState(() {
      _periodsFuture = PeriodsService().getPeriods();
    });
  }

  Future<void> _openCreatePeriod() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PeriodFormDialog(
        title: 'Create Period',
        submitLabel: 'Create',
        onSave: (payload) async {
          final result = await PeriodsService().createPeriod(payload);
          if (result is PeriodSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as PeriodError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (created == true && mounted) {
      _loadPeriods();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period created'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<void> _openEditPeriod(PeriodModel period) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PeriodFormDialog(
        title: 'Edit Period',
        initialPeriod: period,
        submitLabel: 'Save',
        onSave: (payload) async {
          final result = await PeriodsService().updatePeriod(period.id, payload);
          if (result is PeriodSuccess) return true;
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text((result as PeriodError).message), backgroundColor: Colors.red),
            );
          }
          return false;
        },
      ),
    );
    if (updated == true && mounted) {
      _loadPeriods();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period updated'), backgroundColor: kPrimaryGreen),
      );
    }
  }

  Future<void> _deletePeriod(PeriodModel period) async {
    final confirmed = await showDeleteConfirmDialog(
      context,
      title: 'Delete period?',
      message: 'Delete period "${period.name}"?',
    );
    if (confirmed != true) return;
    
    final result = await PeriodsService().deletePeriod(period.id);
    if (!mounted) return;
    
    if (result is PeriodSuccess) {
      _loadPeriods();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Period deleted'), backgroundColor: kPrimaryGreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as PeriodError).message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBgColor, kPrimaryBlue.withOpacity(0.02)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Periods',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                      ),
                    ),
                    _AddButton(onPressed: _openCreatePeriod),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadPeriods(),
                  color: kPrimaryGreen,
                  child: FutureBuilder<PeriodResult<List<PeriodModel>>>(
                    future: _periodsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: kPrimaryGreen));
                      }
                      if (snapshot.hasError) {
                        final msg = userFriendlyMessage(snapshot.error!, null, 'AdminPeriodsScreen');
                        return _ErrorState(message: msg, onRetry: _loadPeriods);
                      }
                      final result = snapshot.data;
                      if (result == null) return const Center(child: Text('No data'));
                      if (result is PeriodError) {
                        return _ErrorState(message: result.message, onRetry: _loadPeriods);
                      }
                      final periods = (result as PeriodSuccess<List<PeriodModel>>).data;
                      if (periods.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.schedule_rounded, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('No periods yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                                  const SizedBox(height: 16),
                                  TextButton.icon(
                                    onPressed: _openCreatePeriod,
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text('Create Period'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: periods.length,
                        itemBuilder: (context, index) {
                          final period = periods[index];
                          return _PeriodCard(
                            period: period,
                            onEdit: () => _openEditPeriod(period),
                            onDelete: () => _deletePeriod(period),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 16),
            TextButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final PeriodModel period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PeriodCard({
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(kCardRadius),
          boxShadow: [
            BoxShadow(color: kPrimaryBlue.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
            BoxShadow(color: kPrimaryBlue.withOpacity(0.03), blurRadius: 32, offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimaryBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Text(
                period.periodNumber.toString(),
                style: const TextStyle(color: kPrimaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    period.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryBlue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${period.startTime.substring(0, 5)} - ${period.endTime.substring(0, 5)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: period.shift == 'MORNING' ? Colors.orange.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      period.shift.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: period.shift == 'MORNING' ? Colors.orange[800] : Colors.indigo[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 22, color: kPrimaryGreen),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 22, color: Colors.red[400]),
              onPressed: onDelete,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodFormDialog extends StatefulWidget {
  final String title;
  final PeriodModel? initialPeriod;
  final String submitLabel;
  final Future<bool> Function(Map<String, dynamic> payload) onSave;

  const _PeriodFormDialog({
    required this.title,
    this.initialPeriod,
    required this.submitLabel,
    required this.onSave,
  });

  @override
  State<_PeriodFormDialog> createState() => _PeriodFormDialogState();
}

class _PeriodFormDialogState extends State<_PeriodFormDialog> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  
  String _shift = 'MORNING';
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPeriod != null) {
      _nameController.text = widget.initialPeriod!.name;
      _numberController.text = widget.initialPeriod!.periodNumber.toString();
      _shift = widget.initialPeriod!.shift;
      
      try {
        final startParts = widget.initialPeriod!.startTime.split(':');
        _startTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      } catch (_) {}
      
      try {
        final endParts = widget.initialPeriod!.endTime.split(':');
        _endTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      } catch (_) {}
    } else {
      _numberController.text = '1';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }
  
  Future<void> _selectTime(bool isStart) async {
    final initial = isStart ? (_startTime ?? const TimeOfDay(hour: 8, minute: 0)) : (_endTime ?? const TimeOfDay(hour: 9, minute: 0));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimaryBlue,
              onPrimary: Colors.white,
              onSurface: kPrimaryBlue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kPrimaryBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final number = int.tryParse(_numberController.text.trim()) ?? 0;
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required'), backgroundColor: Colors.red));
      return;
    }
    if (number <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid Period Number is required'), backgroundColor: Colors.red));
      return;
    }
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Start and End Times are required'), backgroundColor: Colors.red));
      return;
    }
    
    if (_submitting) return;
    setState(() => _submitting = true);
    
    final payload = {
      'name': name,
      'period_number': number,
      'shift': _shift,
      'start_time': '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}:00',
      'end_time': '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}:00',
    };
    
    final ok = await widget.onSave(payload);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: FormCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryBlue),
              ),
              const SizedBox(height: 20),
              Input3D(
                controller: _nameController,
                label: 'Period Name',
                hint: 'e.g. Period 1, Assembly',
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Input3D(
                controller: _numberController,
                label: 'Period Number',
                hint: 'Numeric order',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Select3D<String>(
                label: 'Shift',
                value: _shift,
                items: [
                  DropdownMenuItem(value: 'MORNING', child: Text('Morning')),
                  DropdownMenuItem(value: 'AFTERNOON', child: Text('Afternoon')),
                  DropdownMenuItem(value: 'EVENING', child: Text('Evening')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _shift = v);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TimePickerField(
                      label: 'Start Time',
                      time: _startTime,
                      onTap: () => _selectTime(true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimePickerField(
                      label: 'End Time',
                      time: _endTime,
                      onTap: () => _selectTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton3D(
                      label: widget.submitLabel,
                      onPressed: _submit,
                      loading: _submitting,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;

  const _TimePickerField({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kPrimaryBlue,
              letterSpacing: 0.3,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.transparent),
              boxShadow: [
                BoxShadow(
                  color: kPrimaryBlue.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 10,
                  offset: const Offset(-4, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time != null 
                    ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}' 
                    : 'Select',
                  style: TextStyle(
                    fontSize: 15,
                    color: time != null ? Colors.black87 : Colors.grey[500],
                    fontWeight: time != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                Icon(Icons.schedule_rounded, color: kPrimaryBlue.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kPrimaryGreen.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: kPrimaryGreen.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add_rounded, color: kPrimaryGreen, size: 24),
      ),
    );
  }
}
