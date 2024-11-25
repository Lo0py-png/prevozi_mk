import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; // For TapGestureRecognizer
import 'package:wave/config.dart';
import 'package:wave/wave.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class WaveAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;
  final Widget title;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const WaveAppBar({
    super.key,
    this.height = kToolbarHeight + 50.0,
    required this.title,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: preferredSize.height,
      child: Stack(
        children: [
          WaveWidget(
            config: CustomConfig(
              gradients: [
                [const Color.fromARGB(255, 255, 124, 1), Colors.orange],
                [
                  const Color.fromARGB(253, 255, 166, 0),
                  const Color.fromARGB(253, 255, 166, 0)
                ]
              ],
              durations: [15000, 19440],
              heightPercentages: [0.20, 0.25],
              gradientBegin: Alignment.bottomLeft,
              gradientEnd: Alignment.topRight,
            ),
            waveAmplitude: 0,
            size: Size(double.infinity, preferredSize.height),
          ),
          AppBar(
            centerTitle: true,
            leading: leading,
            title: title,
            elevation: 0.0,
            backgroundColor: Colors.transparent,
            bottom: bottom,
          ),
        ],
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final String label;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final bool obscureText;
  final String? Function(String?)? validator; // Add this line

  const CustomTextFormField({
    Key? key,
    required this.label,
    required this.onChanged,
    this.errorText,
    this.obscureText = false,
    this.validator, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        onChanged: onChanged,
        validator: validator, // Add this line to use the passed validator
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.montserrat(),
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  late String email;
  late String password;
  late String name;
  late String surname;
  late String phoneNumber;
  bool _isAgreed = false;
  String? _agreementError;

  TapGestureRecognizer? _termsRecognizer;
  TapGestureRecognizer? _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _launchURL('https://upsy.mk/terms-and-conditions');
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _launchURL('https://upsy.mk/privacy-policy');
      };
  }

  @override
  void dispose() {
    _termsRecognizer?.dispose();
    _privacyRecognizer?.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        // Ensure it opens in a browser
      );
    } else {
      throw 'Не можам да го отворам $url';
    }
  }

  Future<void> _registerUser() async {
    try {
      final phoneQuerySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (phoneQuerySnapshot.docs.isNotEmpty) {
        _showErrorDialog('Овој телефонски број веќе се користи.');
        return;
      }

      final newUser = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(newUser.user!.uid).set({
        'name': name,
        'surname': surname,
        'email': email,
        'phoneNumber': phoneNumber,
      });

      Navigator.pushReplacementNamed(context, '/');
    } on FirebaseAuthException catch (e) {
      String message = 'Настана грешка. Проверете ги вашите податоци.';
      if (e.code == 'email-already-in-use') {
        message = 'Оваа е-пошта веќе се користи.';
      } else if (e.code == 'invalid-email') {
        message = 'Е-поштата не е валидна.';
      } else if (e.code == 'weak-password') {
        message = 'Лозинката е слаба.';
      }
      _showErrorDialog(message);
    }
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Грешка при регистрација'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[Text(message)],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Во ред'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String? _passwordValidator(String? value) {
    final passwordRegEx = RegExp(r'^(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{5,}$');
    if (!passwordRegEx.hasMatch(value!)) {
      return 'Лозинката мора да содржи најмалку 5 знаци, една голема буква и број.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: WaveAppBar(
        title: Text(
          'Регистрација',
          style: GoogleFonts.montserrat(
            color: const Color.fromARGB(255, 34, 34, 34),
            fontSize: 40.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: screenWidth,
            minHeight: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          ),
          child: IntrinsicHeight(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(253, 255, 166, 0),
                    Color.fromARGB(255, 228, 178, 40),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    CustomTextFormField(
                      label: 'Име',
                      onChanged: (value) => name = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Внесете име';
                        }
                        return null;
                      },
                    ),
                    CustomTextFormField(
                      label: 'Презиме',
                      onChanged: (value) => surname = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Внесете презиме';
                        }
                        return null;
                      },
                    ),
                    CustomTextFormField(
                      label: 'Е-пошта',
                      onChanged: (value) => email = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Внесете е-пошта';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                            .hasMatch(value)) {
                          return 'Е-поштата не е валидна';
                        }
                        return null;
                      },
                    ),
                    CustomTextFormField(
                      label: 'Лозинка',
                      onChanged: (value) => password = value,
                      validator: _passwordValidator,
                      obscureText: true,
                    ),
                    CustomTextFormField(
                      label: 'Телефонски број',
                      onChanged: (value) => phoneNumber = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Телефонскиот број е задолжителен.';
                        } else if (!RegExp(r'^07\d{7}$').hasMatch(value)) {
                          return 'Телефонскиот број мора да започне со 07 и да има 9 цифри.';
                        }
                        return null;
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _isAgreed,
                          onChanged: (value) {
                            setState(() {
                              _isAgreed = value!;
                              _agreementError = null;
                            });
                          },
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text:
                                      'Се согласувам дека сум над 18 години и со ',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.black, fontSize: 13),
                                ),
                                TextSpan(
                                  text: 'Правила и Услови',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                  recognizer: _termsRecognizer,
                                ),
                                TextSpan(
                                  text: ' и ',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.black),
                                ),
                                TextSpan(
                                  text: 'Политика на Приватност',
                                  style: GoogleFonts.montserrat(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                  recognizer: _privacyRecognizer,
                                ),
                                const TextSpan(
                                  text: '.',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_agreementError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          _agreementError!,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 8.0,
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          if (!_isAgreed) {
                            setState(() {
                              _agreementError =
                                  'Мора да се согласите со правилата и условите и политиката на приватност.';
                            });
                            return;
                          }
                          await _registerUser();
                        }
                      },
                      child: Text(
                        'Регистрирај се',
                        style: GoogleFonts.montserrat(
                            color: Colors.white, fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
