import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configs/generic_response.dart';
import '../models/car_details.dart';
import '../configs/constants.dart';

class CarService {
  // Nota: Recuerda cambiar 'localhost' por tu IP local (ej. 192.168.1.X) o 10.0.2.2 si usas emulador
  final String _baseUrl = '${Constants.baseUrl}/api/v1/cars';

  Future<GenericResponse<CarDetails>> fetchByPlate(String plate) async {
    try {
      final url = Uri.parse('$_baseUrl/$plate');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      print('5++++++++++++++++++++++++++++++++++');
      print(url);
      print('6++++++++++++++++++++++++++++++++++');

      // Parseamos el cuerpo de la respuesta a un Mapa común
      final Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Usamos directamente el constructor fromJson de tu GenericResponse.
      // Le pasamos 'fromJsonT' para que sepa cómo transformar el objeto interno 'data' en un CarDetails.
      return GenericResponse<CarDetails>.fromJson(
        jsonResponse,
        fromJsonT: (data) => CarDetails.fromJson(data as Map<String, dynamic>),
      );

    } catch (e, stackTrace) {
      print('Error en CarService: $e');
      print('Stack Trace: $stackTrace');
      
      return GenericResponse<CarDetails>(
        success: false,
        data: null,
        message: 'Ocurrió un error al conectar con el servidor',
        error: stackTrace.toString(),
      );
    }
  }
}