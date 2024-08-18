import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(QuizApp());
}

class QuizApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Purple Quiz App',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemPurple,
        brightness: Brightness.light,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Purple Quiz'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Purple Quiz!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              CupertinoButton.filled(
                child: Text('Start Quiz'),
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => QuizScreen()),
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

class Question {
  final int id;
  final String text;
  final List<String> options;
  final int answer;

  Question({required this.id, required this.text, required this.options, required this.answer});

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      text: json['text'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
    );
  }
}

class QuizScreen extends StatefulWidget {
  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with SingleTickerProviderStateMixin {
  List<Question> questions = [];
  int currentQuestion = 0;
  int score = 0;
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _timer;
  int _timeLeft = 30;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchQuestions() async {
    final response = await http.get(Uri.parse('http://localhost:8080/api/quiz'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        questions = (data['questions'] as List)
            .map((q) => Question.fromJson(q))
            .toList();
        isLoading = false;
      });
      startTimer();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        timer.cancel();
        goToNextQuestion();
      }
    });
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 30;
    });
    startTimer();
  }

  void answerQuestion(int selectedAnswer) async {
    if (selectedAnswer == questions[currentQuestion].answer) {
      score++;
      await playSound('correct.wav');
    } else {
      await playSound('incorrect.wav');
    }
    goToNextQuestion();
  }

  void goToNextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
      _animationController.forward(from: 0.0);
      resetTimer();
    } else {
      _timer?.cancel();
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (context) => ResultsScreen(score: score, total: questions.length),
        ),
      );
    }
  }

  Future<void> playSound(String soundFile) async {
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Quiz'),
      ),
      child: SafeArea(
        child: isLoading
            ? Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentQuestion + 1}/${questions.length}',
                          style: TextStyle(fontSize: 18),
                        ),
                        Text(
                          'Time: $_timeLeft s',
                          style: TextStyle(fontSize: 18, color: CupertinoColors.systemRed),
                        ),
                      ],
    )
  ),
                  Container(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      child: CupertinoListSection.insetGrouped(
                          margin: EdgeInsets.zero,
                          children: [
                        Container(
                          height: 6,
                          child: FractionallySizedBox(
                            widthFactor: (currentQuestion + 1) / questions.length,
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.activeBlue,
                                borderRadius: BorderRadius.all(Radius.circular(10)),
                              ),
                            ),
                          ),
                        )
                      ]),
                    ),
                  ),
                  Expanded(
                    child: FadeTransition(
                      opacity: _animation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              questions[currentQuestion].text,
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          ...questions[currentQuestion].options.asMap().entries.map((option) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: CupertinoButton.filled(
                                child: Text(option.value),
                                onPressed: () => answerQuestion(option.key),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class ResultsScreen extends StatelessWidget {
  final int score;
  final int total;

  ResultsScreen({required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Quiz Results'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Your score:',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              Text(
                '$score / $total',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: CupertinoColors.systemPurple),
              ),
              SizedBox(height: 20),
              Text(
                'Great job!',
                style: TextStyle(fontSize: 20, color: CupertinoColors.systemGreen),
              ),
              SizedBox(height: 40),
              CupertinoButton.filled(
                child: Text('Restart Quiz'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}