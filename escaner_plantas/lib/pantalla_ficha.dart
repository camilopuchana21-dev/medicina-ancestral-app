import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaFicha extends StatefulWidget {
  final String nombrePlanta;
  final double confianza;

  const PantallaFicha({super.key, required this.nombrePlanta, required this.confianza});

  @override
  State<PantallaFicha> createState() => _PantallaFichaState();
}

class _PantallaFichaState extends State<PantallaFicha> {
  Map<String, dynamic>? _datosPlanta;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _buscarEnBaseDeDatos();
  }

  Future<void> _buscarEnBaseDeDatos() async {
    try {
      // Consultamos la tabla 'plantas' en Supabase buscando por el nombre científico
      final respuesta = await Supabase.instance.client
          .from('plantas')
          .select()
          .ilike('nombre_cientifico', '%${widget.nombrePlanta}%') // Búsqueda flexible
          .maybeSingle();

      setState(() {
        _datosPlanta = respuesta;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.nombrePlanta,
                overflow: TextOverflow.ellipsis, // Para que el texto muy largo no dañe el diseño
              ),
            ),
          ],
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _datosPlanta == null
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      "Esta planta aún no está registrada en la base de datos de la comunidad.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                           ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          // Jalamos la URL de la base de datos. Si no hay, usamos una por defecto
                          _datosPlanta!['imagen_url'] ?? 'https://via.placeholder.com/400x200?text=Sin+Imagen',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          // Si la imagen falla, mostramos el ícono de la flor
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.green[100],
                              child: Icon(Icons.local_florist, size: 100, color: Colors.green[700]),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _datosPlanta!['nombre_comun'] ?? 'Sin nombre común',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text(
                        _datosPlanta!['nombre_cientifico'] ?? '',
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                      Text(
                        "Confianza de reconocimiento: ${(widget.confianza * 100).toStringAsFixed(1)}%",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const Divider(height: 30),
                      const Text("Propiedades Medicinales:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_datosPlanta!['propiedades'] ?? 'No registradas', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 20),
                      const Text("Modo de Preparación:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(_datosPlanta!['preparacion'] ?? 'No registrada', style: const TextStyle(fontSize: 16)),

                      // 👇 AQUÍ EMPIEZA LA SECCIÓN DE CRÉDITOS 👇
                      const Divider(height: 40, thickness: 1),
                      const Center(
                        child: Column(
                          children: [
                            Text(
                              "Créditos",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Desarrollado por:\nCamilo Esteban Puchana y Juan Jose Realpe\n\nUniversidad CESMAG\nDB Bar",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            SizedBox(height: 5),
                            Text(
                               "Motor de reconocimiento de imágenes:\nPlant.id (Kindwise)",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ), 
                    ],
                  ),
                ),
    );
  }
}