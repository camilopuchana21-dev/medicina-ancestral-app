import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'pantalla_ficha.dart';

class PantallaEscaner extends StatefulWidget {
  final List<CameraDescription> cameras;
  const PantallaEscaner({super.key, required this.cameras});

  @override
  State<PantallaEscaner> createState() => _PantallaEscanerState();
}

class _PantallaEscanerState extends State<PantallaEscaner> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false; // Para mostrar un cargando

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Función que envía la foto a la IA
  Future<void> _reconocerPlanta() async {
    try {
      setState(() => _isProcessing = true);

      // 1. Tomar la foto
      final XFile foto = await _controller.takePicture();
      File archivoImagen = File(foto.path);

      // 2. Convertir la imagen a Base64
      List<int> imageBytes = await archivoImagen.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 3. Enviar a la API de Plant.id
      final respuesta = await http.post(
        Uri.parse('https://api.plant.id/v2/identify'),
        headers: {
          'Content-Type': 'application/json',
          'Api-Key': 'clave' 
        },
        body: jsonEncode({
          "images": [base64Image],
          "organs": ["leaf", "flower"]
        }),
      );

      setState(() => _isProcessing = false);

      // 4. Procesar la respuesta de la IA
      if (respuesta.statusCode == 200) {
        final data = jsonDecode(respuesta.body);
        if (data['suggestions'] != null && data['suggestions'].isNotEmpty) {
          String nombrePlanta = data['suggestions'][0]['plant_name'];
          double probabilidad = data['suggestions'][0]['probability'];
          
          // Mostrar el resultado en pantalla
          _mostrarResultado(nombrePlanta, probabilidad);
        } else {
          _mostrarError("No se reconoció ninguna planta. Intenta de nuevo.");
        }
      } else {
        _mostrarError("Error de conexión con la IA. Código: ${respuesta.statusCode}");
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _mostrarError("Error al procesar la imagen: $e");
    }
  }

   void _mostrarResultado(String nombre, double probabilidad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¡Planta Reconocida!"),
        content: Text("Es: $nombre\nConfianza: ${(probabilidad * 100).toStringAsFixed(1)}%"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cierra la ventanita
              // Navega a la Ficha AR
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaFicha(
                    nombrePlanta: nombre,
                    confianza: probabilidad,
                  ),
                ),
              );
            }, 
            child: const Text("Ver Ficha AR")
          )
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text("Escanear Planta"),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
                        return Stack(
              children: [
                // --- INICIO DEL CAMBIO PARA PANTALLA COMPLETA ---
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.previewSize!.height,
                      height: _controller.value.previewSize!.width,
                      child: CameraPreview(_controller),
                    ),
                  ),
                ),
                // --- FIN DEL CAMBIO ---
                
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton(
                      backgroundColor: Colors.green[700],
                      onPressed: _isProcessing ? null : _reconocerPlanta,
                      child: _isProcessing 
                          ? const CircularProgressIndicator(color: Colors.white) 
                          : const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
              ], // 👈 ¡ESTE CORCHETE CIERRA LA LISTA DE HIJOS!
            ); // 👈 ¡ESTE PARÉNTESIS Y PUNTO Y COMA CIERRAN EL STACK!
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}