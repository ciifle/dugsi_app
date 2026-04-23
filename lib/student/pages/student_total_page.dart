import 'package:flutter/material.dart';
import 'package:kobac/services/student_service.dart';

const Color kPrimaryBlue = Color(0xFF023471);
const Color kPrimaryGreen = Color(0xFF5AB04B);
const Color kSoftBlue = Color(0xFFE0E9F5);
const Color kSoftGreen = Color(0xFFE4F1E2);
const Color kErrorColor = Color(0xFFEF4444);
const Color kTextPrimary = Color(0xFF1A1E1F);
const Color kTextSecondary = Color(0xFF4F5A5E);

class StudentTotalPage extends StatelessWidget {
  final List<StudentMarkModel> marks;

  const StudentTotalPage({Key? key, required this.marks}) : super(key: key);

  // Calculate per-subject totals (normalized to out of 100)
  Map<String, Map<String, num>> _calculateSubjectTotals() {
    Map<String, Map<String, num>> subjectTotals = {};
    
    for (final mark in marks) {
      final subjectName = mark.subject['name']?.toString() ?? 'Unknown Subject';
      
      if (!subjectTotals.containsKey(subjectName)) {
        subjectTotals[subjectName] = <String, num>{
          'obtained': 0,
          'max': 0,
          'count': 0,
        };
      }
      
      final current = subjectTotals[subjectName]!;
      current['obtained'] = (current['obtained'] ?? 0) + mark.marksObtained;
      current['max'] = (current['max'] ?? 0) + mark.maxMarks;
      current['count'] = (current['count'] ?? 0) + 1;
    }
    
    return subjectTotals;
  }

  // Calculate grand total
  Map<String, num> _calculateGrandTotal() {
    final subjectTotals = _calculateSubjectTotals();
    num totalObtained = 0;
    num totalMax = 0;
    
    for (final subjectData in subjectTotals.values) {
      // Normalize each subject to out of 100
      final subjectMax = subjectData['max'] ?? 0;
      final subjectObtained = subjectData['obtained'] ?? 0;
      
      if (subjectMax > 0) {
        // Scale to out of 100
        final normalizedObtained = (subjectObtained / subjectMax) * 100;
        totalObtained += normalizedObtained;
        totalMax += 100; // Each subject is out of 100
      }
    }
    
    return {
      'obtained': totalObtained,
      'max': totalMax,
    };
  }

  @override
  Widget build(BuildContext context) {
    final subjectTotals = _calculateSubjectTotals();
    final grandTotal = _calculateGrandTotal();
    final average = grandTotal['max']! > 0 ? (grandTotal['obtained']! / grandTotal['max']!) * 100 : 0.0;
    
    return Scaffold(
      backgroundColor: kSoftBlue,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kSoftBlue, kSoftGreen],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(color: kPrimaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: kPrimaryBlue, size: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Grand Total Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimaryBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.assessment_rounded, color: kPrimaryBlue, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Grand Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Grand Total Value
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: kSoftBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                grandTotal['obtained']!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryBlue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '/ ${grandTotal['max']!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: kTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: kPrimaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${average.toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: kPrimaryGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              
              // Subject Totals
              if (subjectTotals.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.assignment_rounded, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('No marks available', style: TextStyle(fontSize: 16, color: kTextSecondary)),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final subjectName = subjectTotals.keys.elementAt(index);
                      final subjectData = subjectTotals[subjectName]!;
                      
                      // Normalize to out of 100
                      final subjectMax = subjectData['max'] ?? 0;
                      final subjectObtained = subjectData['obtained'] ?? 0;
                      final normalizedObtained = subjectMax > 0 ? (subjectObtained / subjectMax) * 100 : 0;
                      final percentage = subjectMax > 0 ? (normalizedObtained / 100) * 100 : 0;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: kPrimaryBlue.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subjectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: kPrimaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subjectData['count']} ${subjectData['count'] == 1 ? 'exam' : 'exams'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: kTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${normalizedObtained.toStringAsFixed(1)} / 100',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: percentage >= 50 ? kPrimaryGreen : kErrorColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: subjectTotals.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
