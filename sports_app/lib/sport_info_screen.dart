import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'api_service.dart';
import 'results_screen.dart';
import 'squat_screen.dart';
import 'situps_screen.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/auth_state.dart';

enum SportType {
  standingBroadJump,
  verticalJump,
  sitAndReach,
  sitUps,
  medicalBallThrow,
  squat,
}

class SportInfoScreen extends StatefulWidget {
  final SportType sportType;
  final ApiService apiService;

  const SportInfoScreen({
    Key? key,
    required this.sportType,
    required this.apiService,
  }) : super(key: key);

  @override
  State<SportInfoScreen> createState() => _SportInfoScreenState();
}

class _SportInfoScreenState extends State<SportInfoScreen> {
  String get _sportTitle {
    switch (widget.sportType) {
      case SportType.standingBroadJump:
        return 'Standing Broad Jump';
      case SportType.verticalJump:
        return 'Vertical Jump';
      case SportType.sitAndReach:
        return 'Sit and Reach';
      case SportType.sitUps:
        return 'Sit Ups';
      case SportType.medicalBallThrow:
        return 'Medical Ball Throw';
      case SportType.squat:
        return 'Squat';
    }
  }

  IconData get _sportIcon {
    switch (widget.sportType) {
      case SportType.standingBroadJump:
        return Icons.directions_run;
      case SportType.verticalJump:
        return Icons.sports_handball;
      case SportType.sitAndReach:
        return Icons.sports_gymnastics;
      case SportType.sitUps:
        return Icons.fitness_center;
      case SportType.medicalBallThrow:
        return Icons.sports_kabaddi;
      case SportType.squat:
        return Icons.accessibility_new;
    }
  }

  Color get _sportColor {
    switch (widget.sportType) {
      case SportType.standingBroadJump:
        return Colors.blue;
      case SportType.verticalJump:
        return Colors.purple;
      case SportType.sitAndReach:
        return Colors.orange;
      case SportType.sitUps:
        return Colors.green;
      case SportType.medicalBallThrow:
        return Colors.indigo;
      case SportType.squat:
        return Colors.teal;
    }
  }

  String get _sportDescription {
    switch (widget.sportType) {
      case SportType.standingBroadJump:
        return 'Measure your horizontal jumping distance. Stand at the starting line and jump as far as you can.';
      case SportType.verticalJump:
        return 'Measure your vertical jumping height. Reach up and jump as high as you can.';
      case SportType.sitAndReach:
        return 'Test your flexibility by reaching forward while sitting with legs extended.';
      case SportType.sitUps:
        return 'Count the number of sit-ups you can perform in the test duration.';
      case SportType.medicalBallThrow:
        return 'Throw a medicine ball and measure the distance it travels.';
      case SportType.squat:
        return 'Perform squats and count the number of repetitions you complete.';
    }
  }

  List<String> get _instructions {
    switch (widget.sportType) {
      case SportType.standingBroadJump:
        return [
          'Stand behind the starting line',
          'Bend your knees and swing your arms',
          'Jump forward as far as possible',
          'Land on both feet',
          'Stay in position until measurement is complete',
        ];
      case SportType.verticalJump:
        return [
          'Stand with feet shoulder-width apart',
          'Reach up with one hand to mark standing reach',
          'Bend knees and jump as high as possible',
          'Reach up at the peak of your jump',
          'Land safely on both feet',
        ];
      case SportType.sitAndReach:
        return [
          'Sit on the floor with legs extended',
          'Place feet against the measuring box',
          'Reach forward slowly',
          'Hold the position for 2 seconds',
          'Keep knees straight throughout',
        ];
      case SportType.sitUps:
        return [
          'Lie on your back with knees bent',
          'Place hands behind your head',
          'Raise your torso until elbows touch knees',
          'Lower back down to starting position',
          'Repeat for the test duration',
        ];
      case SportType.medicalBallThrow:
        return [
          'Stand behind the throwing line',
          'Hold the medicine ball with both hands',
          'Throw the ball forward as far as possible',
          'Use proper throwing technique',
          'Stay behind the line until ball lands',
        ];
      case SportType.squat:
        return [
          'Stand with feet shoulder-width apart',
          'Lower your body by bending knees',
          'Go down until thighs are parallel to floor',
          'Return to standing position',
          'Repeat for the test duration',
        ];
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _startTest() {
    final authState = context.read<AuthCubit>().state;
    
    final height = authState.height ?? 170.0;
    final weight = authState.weight ?? 70.0;
    final age = authState.age ?? 25;
    final name = authState.name ?? 'Athlete';

    // Navigate to appropriate screen based on sport type
    if (widget.sportType == SportType.squat) {
      // Navigate to squat screen for squat sport
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SquatScreen(
            apiService: widget.apiService,
          ),
        ),
      );
    } else if (widget.sportType == SportType.sitUps) {
      // Navigate to sit-ups screen for sit-ups sport
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SitupsScreen(
            apiService: widget.apiService,
          ),
        ),
      );
    } else {
      // Navigate to results screen for other sports
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(
            apiService: widget.apiService,
            sportType: widget.sportType,
            athleteName: name,
            height: height,
            weight: weight,
            age: age,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _sportColor,
        title: Text(
          _sportTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                // Sport Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _sportColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _sportIcon,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _sportTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _sportDescription,
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

                // Instructions Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: _sportColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ..._instructions.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _sportColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${entry.key + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Start Button
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _startTest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _sportColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Start Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

