import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'api_service.dart';
import 'sport_info_screen.dart';
import 'bloc/jump/jump_cubit.dart';
import 'bloc/jump/jump_state.dart';

class ResultsScreen extends StatelessWidget {
  final ApiService apiService;
  final SportType? sportType;
  final String? athleteName;
  final double? height;
  final double? weight;
  final int? age;

  const ResultsScreen({
    Key? key,
    required this.apiService,
    this.sportType,
    this.athleteName,
    this.height,
    this.weight,
    this.age,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JumpCubit(apiService)..startPolling(),
      child: _ResultsScreenContent(
        initialHeight: height?.toString() ?? '170',
        initialWeight: weight?.toString() ?? '70',
        sportType: sportType,
        athleteName: athleteName,
      ),
    );
  }
}

class _ResultsScreenContent extends StatefulWidget {
  final String initialHeight;
  final String initialWeight;
  final SportType? sportType;
  final String? athleteName;

  const _ResultsScreenContent({
    Key? key,
    required this.initialHeight,
    required this.initialWeight,
    this.sportType,
    this.athleteName,
  }) : super(key: key);

  @override
  State<_ResultsScreenContent> createState() => _ResultsScreenContentState();
}

class _ResultsScreenContentState extends State<_ResultsScreenContent> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.initialHeight);
    _weightController = TextEditingController(text: widget.initialWeight);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  String _getSportTitle(SportType type) {
    switch (type) {
      case SportType.standingBroadJump: return 'Standing Broad Jump';
      case SportType.verticalJump: return 'Vertical Jump';
      case SportType.sitAndReach: return 'Sit and Reach';
      case SportType.sitUps: return 'Sit Ups';
      case SportType.medicalBallThrow: return 'Medical Ball Throw';
      case SportType.squat: return 'Squat';
    }
  }

  Color _getSportColor(SportType type) {
    switch (type) {
      case SportType.standingBroadJump: return Colors.blue;
      case SportType.verticalJump: return Colors.purple;
      case SportType.sitAndReach: return Colors.orange;
      case SportType.sitUps: return Colors.green;
      case SportType.medicalBallThrow: return Colors.indigo;
      case SportType.squat: return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.sportType != null ? _getSportTitle(widget.sportType!) : 'Jump Results';
    final themeColor = widget.sportType != null ? _getSportColor(widget.sportType!) : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: themeColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<JumpCubit>().startPolling(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<JumpCubit, JumpState>(
        builder: (context, state) {
          if (state.errorMessage != null && state.jumpCount == 0 && !state.isRunning) {
            return const SizedBox.shrink(); 
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.extended(
                onPressed: state.isRunning
                    ? () => context.read<JumpCubit>().stopDetection()
                    : () => _showStartDialog(context),
                backgroundColor: state.isRunning ? Colors.red : Colors.green,
                icon: Icon(state.isRunning ? Icons.stop : Icons.play_arrow),
                label: Text(state.isRunning ? 'Stop' : 'Start'),
              ),
              const SizedBox(height: 10),
              FloatingActionButton(
                onPressed: () => context.read<JumpCubit>().resetData(),
                backgroundColor: Colors.orange,
                child: const Icon(Icons.refresh),
                tooltip: 'Reset',
              ),
            ],
          );
        },
      ),
      body: BlocConsumer<JumpCubit, JumpState>(
        listener: (context, state) {
          // You could show snackbars here for specific events if needed
        },
        builder: (context, state) {
          if (state.errorMessage != null && state.jumpCount == 0 && state.statusMessage == 'Waiting to start...') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Connection Error:\n${state.errorMessage}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure server is running at ${ApiService.baseUrl}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<JumpCubit>().startPolling(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<JumpCubit>().startPolling();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.athleteName != null) ...[
                      Text(
                        'Athlete: ${widget.athleteName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildStatCard(
                      'Jump Count',
                      state.jumpCount.toString(),
                      Icons.directions_run,
                      Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Last Jump Height',
                      '${state.lastJumpHeight.toStringAsFixed(2)} cm',
                      Icons.height,
                      Colors.green,
                    ),
                    const SizedBox(height: 16),
                    _buildStatCard(
                      'Highest Jump',
                      '${state.maxJumpHeight.toStringAsFixed(2)} cm',
                      Icons.trending_up,
                      Colors.orange,
                    ),
                    const SizedBox(height: 16),
                    _buildStatusCard(
                      'Status',
                      state.statusMessage,
                      state.isRunning ? Icons.check_circle : Icons.pause_circle,
                      state.isRunning ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 32,
                            color: themeColor,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Data updates every second',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Server: ${ApiService.baseUrl}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Jump Detection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
                hintText: 'Enter your height in cm',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                hintText: 'Enter your weight in kg',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              final h = double.tryParse(_heightController.text) ?? 170.0;
              final w = double.tryParse(_weightController.text) ?? 70.0;
              context.read<JumpCubit>().startDetection(height: h, weight: w);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
