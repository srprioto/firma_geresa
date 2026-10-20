class DatosFirmante {
	final String nombre;
	final String dni;

	const DatosFirmante({required this.nombre, required this.dni});
}

/// Resultado del popup del PIN: el PIN (se reutiliza en la firma final)
/// y los datos del firmante leídos del certificado.
class AccesoFirma {
	final String pin;
	final DatosFirmante datos;

	const AccesoFirma({required this.pin, required this.datos});
}