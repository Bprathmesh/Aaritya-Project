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
      id: json['id'],
      text: json['text'],
      options: List<String>.from(json['options']),
      answer: json['answer'],
      hint: json['hint'],
      imageUrl: json['imageUrl'],
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
  bool isHintVisible = false;
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
    try {
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
        _animationController.forward();
      } else {
        throw Exception('Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      showErrorDialog('Error loading questions: $e');
    }
  }

  void showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to home screen
            },
          ),
        ],
      ),
    );
  }

  String cleanImageUrl(String url) {
    // Remove any duplicate "http://" or "https://"
    final regex = RegExp(r'(https?:\/\/)+(.*)', caseSensitive: false);
    final match = regex.firstMatch(url);
    if (match != null) {
      return '${match.group(1)}${match.group(2)}';
    }
    return url;
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
      isHintVisible = false;
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
        isHintVisible = false;
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

  void showHint() {
    setState(() {
      isHintVisible = true;
    });
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
                    ),
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
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: FadeTransition(
                      opacity: _animation,
                      child: SingleChildScrollView(
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
                            if (questions[currentQuestion].imageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.network(
                                  cleanImageUrl(questions[currentQuestion].imageUrl),
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Error loading image: $error');
                                    return Text('Failed to load image');
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CupertinoActivityIndicator(),
                                    );
                                  },
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
                            SizedBox(height: 20),
                            CupertinoButton(
                              child: Text('Show Hint'),
                              onPressed: showHint,
                            ),
                            if (isHintVisible)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  questions[currentQuestion].hint,
                                  style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
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