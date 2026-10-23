import 'package:firmador_geresa/assets/tools/files_manag/json_storage.dart';

String obtenerRutaNextcloud() {
	final ruta = JsonStorage.getString('ruta_nextcloud');
	
	// Si el JSON tiene la ruta (y no está vacía), la usa. 
	// Si el JSON está vacío (primera vez), usa la de 'nuevo_back' por defecto.
	return (ruta == null || ruta.trim().isEmpty) 
			? 'C:/Users/RenatoLuna/Desktop/nuevo_back' 
			: ruta.trim();
}