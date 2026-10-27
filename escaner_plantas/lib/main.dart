import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 👈 Importamos Supabase
import 'pantalla_escaner.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. INICIALIZAMOS SUPABASE (PEGA TUS DATOS AQUÍ 👇)
  await Supabase.initialize(
    url: '', // Ejemplo: https://xxxxxx.supabase.co
    anonKey: '', // Ejemplo: sb_publishable_xxxxxx
  );

  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error al inicializar cámaras: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicina Ancestral AR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: PantallaEscaner(cameras: cameras),
      debugShowCheckedModeBanner: false,
    );
  }
}