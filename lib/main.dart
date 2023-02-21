import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_login_screen/test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_login_screen/widget/enable_local_auth_modal_bottom_sheet.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const Color primaryColor = Color(0xFF13B5A2);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  LocalAuthentication auth = LocalAuthentication();
  bool? _canCheckBiometric;
  List<BiometricType>? _availableBio;
  String authrized = "not Auth";

  Future<void> _CheckBiometric() async {
    bool? canCheckBiometrics;
    try {
      canCheckBiometrics = await auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;
    setState(() {
      _canCheckBiometric = canCheckBiometrics;
    });
  }

  Future<void> _getAvaialableBio() async {
    List<BiometricType>? availableBio;
    try {
      availableBio = await auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
    }
    setState(() {
      _availableBio = availableBio;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
          localizedReason: "Scan yore finger to authentecate",
          useErrorDialogs: true,
          stickyAuth: false,
          biometricOnly: true);
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      authrized = authenticated ? "succsess" : "failed";

      print(authrized);

      if (authenticated) {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Test(),
            ));
      }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _getAvaialableBio();
    _CheckBiometric();
  }

  // Create storage
  final _storage = const FlutterSecureStorage();
  final String KEY_USERNAME = "KEY_USERNAME";
  final String KEY_PASSWORD = "KEY_PASSWORD";
  final String KEY_LOCAL_AUTH_ENABLED = "KEY_LOCAL_AUTH_ENABLED";

  final TextEditingController _usernameController =
      TextEditingController(text: "");
  final TextEditingController _passwordController =
      TextEditingController(text: "");

  bool passwordHidden = true;
  bool _savePassword = true;

  var localAuth = LocalAuthentication();

  // Read values
  Future<void> _readFromStorage() async {
    String isLocalAuthEnabled =
        await _storage.read(key: "KEY_LOCAL_AUTH_ENABLED") ?? "false";

    if ("true" == isLocalAuthEnabled) {
      bool didAuthenticate = await localAuth.authenticate(
          localizedReason: 'Please authenticate to sign in');

      if (didAuthenticate) {
        _usernameController.text = await _storage.read(key: KEY_USERNAME) ?? '';
        _passwordController.text = await _storage.read(key: KEY_PASSWORD) ?? '';
      }
    } else {
      _usernameController.text = await _storage.read(key: KEY_USERNAME) ?? '';
      _passwordController.text = await _storage.read(key: KEY_PASSWORD) ?? '';
    }
  }

  _onFormSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_savePassword) {
        // reset fingerprint auth values. Only for demo purpose
        await _storage.write(key: KEY_LOCAL_AUTH_ENABLED, value: "false");

        // Write values
        await _storage.write(
            key: KEY_USERNAME, value: _usernameController.text);
        await _storage.write(
            key: KEY_PASSWORD, value: _passwordController.text);

        // check if biometric auth is supported
        if (await localAuth.canCheckBiometrics) {
          // Ask for enable biometric auth
          showModalBottomSheet<void>(
            context: context,
            builder: (BuildContext context) {
              return EnableLocalAuthModalBottomSheet(
                  action: _onEnableLocalAuth);
            },
          );
        }
      }
    }
  }

  /// Method associated to UI Button in modalBottomSheet.
  /// It enables local_auth and saves data into storage
  _onEnableLocalAuth() async {
    // Save
    await _storage.write(key: KEY_LOCAL_AUTH_ENABLED, value: "true");

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(
          "Fingerprint authentication enabled.\nClose the app and restart it again"),
    ));
  }

  _onForgotPassword() {}

  _onSignUp() {}

  @override
  void dispose() {
    super.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          padding: EdgeInsets.all(size.width - size.width * .85),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: size.height * .10,
              ),
              const Text(
                "Welcome back.",
                style: TextStyle(
                    color: Color(0xFF161925),
                    fontWeight: FontWeight.w600,
                    fontSize: 32),
              ),
              SizedBox(
                height: size.height * .05,
              ),
              SizedBox(
                width: size.width,
                child: ElevatedButton(
                  onPressed: _authenticate,
                  child: const Text("Sign In"),
                  style: ElevatedButton.styleFrom(
                      primary: primaryColor,
                      textStyle: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(
                height: size.height * .015,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
