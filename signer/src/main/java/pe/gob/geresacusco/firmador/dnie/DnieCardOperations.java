package pe.gob.geresacusco.firmador.dnie;

import javax.smartcardio.CardException;

/**
 * Operaciones mínimas que necesitamos de cualquier versión de DNIe. Cada
 * versión del chip (v2, v3...) habla un protocolo APDU distinto por
 * debajo, pero expone esto mismo hacia el resto de la aplicación.
 */
public interface DnieCardOperations {

    byte[] leerCertificadoFirma() throws CardException;

    byte[] firmarConPin(String pin, byte[] hash)
            throws CardException, PinIncorrectoException, TarjetaBloqueadaException;

    void cerrar();
}
