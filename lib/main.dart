import 'package:flutter/material.dart';
import 'package:mk_ambulance/providers/patient_form_data.dart';
import 'package:mk_ambulance/screens/home.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PatientFormProvider()),
      ],
      child: const MKAmbulanceApp(),
    ),
  );
}

class MKAmbulanceApp extends StatelessWidget {
  const MKAmbulanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}



