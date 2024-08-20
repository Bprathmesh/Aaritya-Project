import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(ProviderScope(child: QuizApp()));
}

// Theme provider
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<ThemeData> {
  ThemeNotifier() : super(_lightTheme);

  static final _lightTheme = ThemeData(
    primarySwatch: Colors.purple,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.purple[50],
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
    ),
  );

  static final _darkTheme = ThemeData(
    primarySwatch: Colors.purple,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.grey[900],
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple[300],
        foregroundColor: Colors.black,
      ),
    ),
  );

  void toggleTheme() {
    state = state.brightness == Brightness.light ? _darkTheme : _lightTheme;
  }
}

class QuizApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Enhanced Quiz App',
      theme: theme,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced Quiz App'),
        actions: [
          Consumer(
            builder: (context, ref, _) => IconButton(
              icon: Icon(Icons.brightness_6),
              onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/quiz_logo.svg',
                height: 150,
              ),
              SizedBox(height: 30),
              Text(
                'Welcome to Enhanced Quiz!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 20),
              Text(
                'Test your knowledge and have fun!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                child: Text('Start Quiz'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizScreen()),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Create Quiz'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateQuizScreen()),
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                child: Text('How to Play'),
                onPressed: () => _showHowToPlay(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToPlay(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('How to Play'),
        content: Text(
          '1. Answer questions within the time limit\n'
          '2. Use hints if you need help\n'
          '3. Score points for correct answers\n'
          '4. Try to beat your high score!\n'
          '5. Create your own quizzes to challenge friends',
        ),
        actions: [
          TextButton(
            child: Text('Got it!'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int answer;
  final String hint;
  final String imageUrl;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.answer,
    required this.hint,
    required this.imageUrl,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'].toString(),
      text: json['text'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
      hint: json['hint'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'options': options,
    'answer': answer,
    'hint': hint,
    'imageUrl': imageUrl,
  };
}

// Modified Quiz provider
final quizProvider = FutureProvider<List<Question>>((ref) async {
  final apiQuestions = await fetchAPIQuestions();
  final localQuestions = await fetchLocalQuestions();
  return [...apiQuestions, ...localQuestions];
});

Future<List<Question>> fetchAPIQuestions() async {
  try {
    final response = await http.get(Uri.parse('http://localhost:8080/api/quiz'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['questions'] as List).map((q) => Question.fromJson(q)).toList();
    } else {
      throw Exception('Failed to load questions from API');
    }
  } catch (e) {
    print('Error fetching API questions: $e');
    return [];
  }
}

Future<List<Question>> fetchLocalQuestions() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  List<String> savedQuestions = prefs.getStringList('custom_questions') ?? [];
  return savedQuestions.map((q) => Question.fromJson(json.decode(q))).toList();
}

class QuizScreen extends ConsumerStatefulWidget {
  final List<Question>? questions;

  QuizScreen({this.questions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int currentQuestion = 0;
  int score = 0;
  bool isHintVisible = false;
  late ConfettiController _confettiController;
  int _timeLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    startTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 30;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        _answerQuestion(false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = widget.questions != null
        ? AsyncValue.data(widget.questions!)
        : ref.watch(quizProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                'Time: $_timeLeft',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: quizAsync.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (questions) => _buildQuizContent(questions),
      ),
    );
  }

  Widget _buildQuizContent(List<Question> questions) {
    if (currentQuestion >= questions.length) {
      return _buildResultScreen();
    }

    Question question = questions[currentQuestion];
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: (currentQuestion + 1) / questions.length),
                  SizedBox(height: 20),
                  Text(
                    'Question ${currentQuestion + 1}/${questions.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 20),
                  Text(
                    question.text,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 20),
                  if (question.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        question.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  SizedBox(height: 20),
                  ...question.options.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        child: Text(entry.value),
                        onPressed: () => _answerQuestion(entry.key == question.answer),
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 20),
                  if (!isHintVisible)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Show Hint'),
                      onPressed: () => setState(() => isHintVisible = true),
                    ),
                  if (isHintVisible)
                    Text(
                      question.hint,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3.14 / 2,
              colors: [Colors.purple, Colors.orange],
              emissionFrequency: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(bool isCorrect) {
    _timer?.cancel();
    if (isCorrect) {
      score++;
      _confettiController.play();
    }
    setState(() {
      currentQuestion++;
      isHintVisible = false;
    });
    _animationController.forward(from: 0.0);
    if (currentQuestion < (widget.questions ?? ref.read(quizProvider).value!).length) {
      startTimer();
    }
  }

  Widget _buildResultScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Quiz Completed!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 20),
          Text(
            'Your Score: $score',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 40),
          ElevatedButton(
            child: Text('Return to Home'),
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

class CreateQuizScreen extends StatefulWidget {
  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  String _questionText = '';
  List<String> _options = ['', '', '', ''];
  int _correctAnswer = 0;
  String _hint = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Quiz')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Question'),
                validator: (value) => value!.isEmpty ? 'Please enter a question' : null,
                onSaved: (value) => _questionText = value!,
              ),
              SizedBox(height: 20),
              ...List.generate(4, (index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    decoration: InputDecoration(labelText: 'Option ${index + 1}'),
                    validator: (value) => value!.isEmpty ? 'Please enter an option' : null,
                    onSaved: (value) => _options[index] = value!,
                  ),
                );
              }),
              SizedBox(height: 20),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Correct Answer'),
                items: [0, 1, 2, 3].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('Option ${value + 1}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _correctAnswer = value!),
                validator: (value) => value == null ? 'Please select the correct answer' : null,
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Hint'),
                onSaved: (value) => _hint = value!,
              ),
              SizedBox(height: 40),
              ElevatedButton(
                child: Text('Preview Question'),
                onPressed: _previewQuestion,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Save Question'),
                onPressed: _saveQuestion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewQuestion() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      Question previewQuestion = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _questionText,
        options: _options,
        answer: _correctAnswer,
        hint: _hint,
        imageUrl: '',
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => QuizScreen(questions: [previewQuestion]),
        ),
      );
    }
  }

  void _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      Question newQuestion = Question(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: _questionText,
        options: _options,
        answer: _correctAnswer,
        hint: _hint,
        imageUrl: '',
      );

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> savedQuestions = prefs.getStringList('custom_questions') ?? [];
      savedQuestions.add(json.encode(newQuestion.toJson()));
      await prefs.setStringList('custom_questions', savedQuestions);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question saved successfully!')),
      );

      Navigator.of(context).pop();
    }
  }
}