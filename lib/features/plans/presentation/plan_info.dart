import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/plans_model.dart';
import 'package:go_router/go_router.dart';

class PlanInfo extends StatelessWidget {
  const PlanInfo({super.key, required this.plan});
  final PlansModel plan;

  @override
  Widget build(BuildContext context) {
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
            Text(
              'Plan Description\nThis is a plan description and for testing purposes.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanImage(BuildContext context) {
    return Hero(
      tag: plan.title,
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
          plan.title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        Text(
          '6 Days',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: () {
          context.push('/plans/details');
        },
        style: FilledButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
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
}
