package pe.gob.geresacusco.firmador.dnie;

/**
 * Se agotaron los intentos de PIN: el DNIe quedó bloqueado para firmar.
 * Esto corresponde al código de estado ISO 7816 "69 83" (método de
 * autenticación bloqueado). Desbloquear el DNIe requiere trámite
 * presencial en RENIEC (con el PUK/clave de desbloqueo), no es algo que
 * esta aplicación pueda remediar.
 */
public class TarjetaBloqueadaException extends Exception {
    public TarjetaBloqueadaException() {
        super("El DNIe está bloqueado (se agotaron los intentos de PIN). "
                + "Debe desbloquearse en un centro de atención de RENIEC.");
    }
}
