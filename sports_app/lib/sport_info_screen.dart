import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'api_service.dart';
import 'results_screen.dart';
import 'squat_screen.dart';
import 'situps_screen.dart';
import 'strings.dart';
import 'bloc/auth_cubit.dart';
import 'bloc/auth_state.dart';
import 'bloc/language_cubit.dart';

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
        return 'standingBroadJump';
      case SportType.verticalJump:
        return 'verticalJump';
      case SportType.sitAndReach:
        return 'sitAndReach';
      case SportType.sitUps:
        return 'sitUps';
      case SportType.medicalBallThrow:
        return 'medicalBallThrow';
      case SportType.squat:
        return 'squat';
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
        return 'measureHorizontalJumping';
      case SportType.verticalJump:
        return 'measureVerticalJumping';
      case SportType.sitAndReach:
        return 'testYourFlexibility';
      case SportType.sitUps:
        return 'countSitUps';
      case SportType.medicalBallThrow:
        return 'throwMedicineBall';
      case SportType.squat:
        return 'performSquats';
    }
  }

  List<String> _getInstructions(String lang) {
    switch (widget.sportType) {
      case SportType.standingBroadJump:
        return [
          Strings.get('standBehindStartingLine', lang),
          Strings.get('bendKneesAndSwing', lang),
          Strings.get('jumpForwardAsFar', lang),
          Strings.get('landOnBothFeet', lang),
          Strings.get('stayInPositionUntil', lang),
        ];
      case SportType.verticalJump:
        return [
          Strings.get('standWithFeetShoulderWidth', lang),
          Strings.get('reachUpWithOneHand', lang),
          Strings.get('bendKneesAndJump', lang),
          Strings.get('reachUpAtPeak', lang),
          Strings.get('landSafelyOnBothFeet', lang),
        ];
      case SportType.sitAndReach:
        return [
          Strings.get('sitOnFloorLegsExtended', lang),
          Strings.get('placeFeetsAgainst', lang),
          Strings.get('reachForwardSlowly', lang),
          Strings.get('holdPositionFor2Seconds', lang),
          Strings.get('keepKneesStraight', lang),
        ];
      case SportType.sitUps:
        return [
          Strings.get('lieOnYourBack', lang),
          Strings.get('placeHandsBehindHead', lang),
          Strings.get('raiseYourTorso', lang),
          Strings.get('lowerBackToStarting', lang),
          Strings.get('repeatForTestDuration', lang),
        ];
      case SportType.medicalBallThrow:
        return [
          Strings.get('standBehindThrowingLine', lang),
          Strings.get('holdMedicineBall', lang),
          Strings.get('throwBallForwardAsFar', lang),
          Strings.get('useProperThrowingTechnique', lang),
          Strings.get('stayBehindLineUntil', lang),
        ];
      case SportType.squat:
        return [
          Strings.get('standWithFeetShoulderWidth', lang),
          Strings.get('lowerYourBodyByBending', lang),
          Strings.get('goDownUntilThighs', lang),
          Strings.get('returnToStandingPosition', lang),
          Strings.get('repeatForTestDuration', lang),
        ];
    }
  }

  void _startTest() {
    final authState = context.read<AuthCubit>().state;

    final height = authState.height ?? 170.0;
    final weight = authState.weight ?? 70.0;
    final age = authState.age ?? 25;
    final name = authState.name ?? 'Athlete';

    if (widget.sportType == SportType.squat) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SquatScreen(apiService: widget.apiService),
        ),
      );
    } else if (widget.sportType == SportType.sitUps) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SitupsScreen(apiService: widget.apiService),
        ),
      );
    } else {
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
    return BlocBuilder<LanguageCubit, LanguageState>(
      builder: (context, languageState) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: _sportColor,
            title: Text(
              Strings.get(_sportTitle, languageState.languageCode),
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
                    InkWell(
                      onTap: languageState.languageCode != 'en'
                          ? () => context.read<LanguageCubit>().changeLanguage('en')
                          : null,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('EN'),
                      ),
                    ),
                    Container(width: 1, height: 24, color: Colors.white30),
                    InkWell(
                      onTap: languageState.languageCode != 'hi'
                          ? () => context.read<LanguageCubit>().changeLanguage('hi')
                          : null,
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('हि'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: Container(
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _sportColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(_sportIcon, color: Colors.white, size: 50),
                        const SizedBox(height: 12),
                        Text(
                          Strings.get(_sportTitle, languageState.languageCode),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Strings.get(
                              _sportDescription, languageState.languageCode),
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
                            Icon(Icons.info_outline,
                                color: _sportColor, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              Strings.get(
                                  'instructions', languageState.languageCode),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        ..._getInstructions(languageState.languageCode)
                            .asMap()
                            .entries
                            .map(
                          (entry) {
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
                                            fontSize: 12,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

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
                          child: Text(
                            Strings.get(
                                'startTest', languageState.languageCode),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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
      },
    );
  }
}
                           