import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'api_service.dart';
import 'strings.dart';
import 'bloc/squat_cubit.dart';
import 'bloc/squat_state.dart';
import 'bloc/language_cubit.dart';

class SquatScreen extends StatelessWidget {
  final ApiService apiService;

  const SquatScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SquatCubit(apiService: apiService),
      child: const _SquatScreenContent(),
    );
  }
}

class _SquatScreenContent extends StatelessWidget {
  const _SquatScreenContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.teal,
            title: Text(
              Strings.get('squat', languageState.languageCode),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: languageState.languageCode != 'en'
                            ? () => context.read<LanguageCubit>().changeLanguage('en')
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'EN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: languageState.languageCode == 'en'
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: Colors.white30,
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: languageState.languageCode != 'hi'
                            ? () => context.read<LanguageCubit>().changeLanguage('hi')
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            'हि',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: languageState.languageCode == 'hi'
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<SquatCubit>().fetchStatus();
                },
                tooltip: Strings.get('refresh', languageState.languageCode),
              ),
            ],
          ),
          body: Container(
            color: Colors.grey.shade50,
            child: BlocBuilder<SquatCubit, SquatState>(
              builder: (context, state) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.teal.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.accessibility_new,
                              color: Colors.white,
                              size: 50,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              Strings.get('squat', languageState.languageCode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.statusMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (state.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Squat Count Card
                      _buildStatCard(
                        Strings.get('squatCount', languageState.languageCode),
                        state.squatCount.toString(),
                        Icons.fitness_center,
                        Colors.teal,
                        0,
                      ),
                      const SizedBox(height: 16),

                      // Current Stage Card
                      _buildStatCard(
                        Strings.get('currentStage', languageState.languageCode),
                        state.currentStage == 'down' 
                            ? Strings.get('down', languageState.languageCode)
                            : Strings.get('up', languageState.languageCode),
                        state.currentStage == 'down' 
                            ? Icons.arrow_downward 
                            : Icons.arrow_upward,
                        state.currentStage == 'down' ? Colors.orange : Colors.green,
                        1,
                      ),
                      const SizedBox(height: 16),

                      // Current Angle Card
                      _buildStatCard(
                        Strings.get('bodyAngle', languageState.languageCode),
                        '${state.currentAngle.toStringAsFixed(1)}${Strings.get('degrees', languageState.languageCode)}',
                        Icons.straighten,
                        Colors.blue,
                        2,
                      ),
                      const SizedBox(height: 16),

                      // Status Card
                      _buildStatusCard(
                        Strings.get('statusMessage', languageState.languageCode),
                        state.statusMessage,
                        state.isRunning
                            ? Icons.check_circle
                            : Icons.pause_circle,
                        state.isRunning ? Colors.green : Colors.grey,
                        3,
                      ),
                      const SizedBox(height: 24),

                      // Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.teal.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                size: 28,
                                color: Colors.teal.shade700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Live Data Updates',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              state.isRunning
                                  ? 'Real-time monitoring active'
                                  : 'Start detection to begin monitoring',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              BlocBuilder<SquatCubit, SquatState>(
                builder: (context, state) {
                  return FloatingActionButton.extended(
                    onPressed: state.isLoading
                        ? null
                        : state.isRunning
                            ? () => context.read<SquatCubit>().stopSquat()
                            : () => context.read<SquatCubit>().startSquat(),
                    backgroundColor:
                        state.isRunning ? Colors.red.shade600 : Colors.green.shade600,
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(state.isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      state.isLoading
                          ? 'Loading...'
                          : state.isRunning
                              ? Strings.get('stop', languageState.languageCode)
                              : Strings.get('start', languageState.languageCode),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    elevation: 8,
                  );
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<SquatCubit, SquatState>(
                builder: (context, state) {
                  return FloatingActionButton(
                    onPressed: state.isLoading
                        ? null
                        : () => context.read<SquatCubit>().resetSquat(),
                    backgroundColor: Colors.orange.shade600,
                    child: const Icon(Icons.refresh),
                    tooltip: Strings.get('reset', languageState.languageCode),
                    elevation: 8,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color.lerp(color, Colors.black, 0.3),
                      letterSpacing: 0.5,
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

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color.lerp(color, Colors.black, 0.3),
                      height: 1.4,
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
}

