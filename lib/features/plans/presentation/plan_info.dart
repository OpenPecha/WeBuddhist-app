import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/auth/application/auth_provider.dart';
import 'package:flutter_pecha/features/plans/data/providers/user_plans_provider.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends ConsumerStatefulWidget {
  // Changed to StatefulWidget
  const PlanInfo({super.key, required this.plan});
  final PlansModel plan;

  @override
  ConsumerState<PlanInfo> createState() => _PlanInfoState();
}

class _PlanInfoState extends ConsumerState<PlanInfo> {
  @override
  Widget build(BuildContext context) {
    // final authState = ref.watch(authProvider);
    // final isGuest = authState.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plan Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlanImage(context),
            SizedBox(height: 20),
            _buildPlanTitleDays(context),
            SizedBox(height: 20),
            _buildActionButtons(context),
            SizedBox(height: 20),
            _buildPlanDescription(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return Hero(
      tag: widget.plan.title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          'assets/images/bg.jpg',
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.25,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPlanTitleDays(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          widget.plan.title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        Text(
          '${widget.plan.totalDays} Days',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () => handleStartPlan(), // Updated to call without ref
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          'Start Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Updated handleStartPlan function
  Future<void> handleStartPlan() async {
    final planId = widget.plan.id;
    final authState = ref.read(authProvider);

    try {
      // Subscribe to plan using the authenticated HTTP client
      final success = await ref.read(
        userPlanSubscribeFutureProvider(planId).future,
      );

      if (success) {
        // Success: Show plan listed in my plans
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully enrolled in ${widget.plan.title}!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Invalidate the user plans provider to refresh the data
          ref.invalidate(userPlansFutureProvider(authState.userId!));

          // Wait a moment for the data to refresh, then navigate
          await Future.delayed(Duration(milliseconds: 500));

          // Navigate to plan details with the subscribed plan
          if (mounted) {
            context.push('/plans/details', extra: widget.plan);
          }
        }
      } else {
        // Failed to enroll
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to enroll in plan. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors during enrollment
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enrolling in plan: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      print('Enrollment error: $e'); // For debugging
    }
  }

  Widget _buildPlanDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.plan.description ?? 'No description available.',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
