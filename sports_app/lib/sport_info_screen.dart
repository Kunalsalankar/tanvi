import 'package:flutter/material.dart';
import 'api_service.dart';
import 'results_screen.dart';
import 'squat_screen.dart';

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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _startTest() {
    if (_formKey.currentState!.validate()) {
      final height = double.tryParse(_heightController.text) ?? 170.0;
      final weight = double.tryParse(_weightController.text) ?? 70.0;
      final age = int.tryParse(_ageController.text) ?? 25;
      final name = _nameController.text.trim();

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
          child: Form(
            key: _formKey,
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

                // Form Fields Card
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
                            Icons.person_outline,
                            color: _sportColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Athlete Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter your full name',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Height Field
                      TextFormField(
                        controller: _heightController,
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          hintText: 'Enter your height in cm',
                          prefixIcon: const Icon(Icons.height),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0 || height > 300) {
                            return 'Please enter a valid height (1-300 cm)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Weight Field
                      TextFormField(
                        controller: _weightController,
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: 'Enter your weight in kg',
                          prefixIcon: const Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0 || weight > 300) {
                            return 'Please enter a valid weight (1-300 kg)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age Field
                      TextFormField(
                        controller: _ageController,
                        decoration: InputDecoration(
                          labelText: 'Age',
                          hintText: 'Enter your age',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your age';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age <= 0 || age > 120) {
                            return 'Please enter a valid age (1-120)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Start Button
                SizedBox(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

