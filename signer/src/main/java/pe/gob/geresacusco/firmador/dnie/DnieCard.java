package pe.gob.geresacusco.firmador.dnie;

import javax.smartcardio.Card;
import javax.smartcardio.CardException;
import javax.smartcardio.ResponseAPDU;
import java.io.ByteArrayOutputStream;
import java.util.Arrays;
import java.util.HexFormat;

/**
 * Habla directo con el chip del DNIe usando comandos APDU (ISO 7816-4 /
 * 7816-8), sin pasar por ningún driver PKCS#11 de fabricante ni por el
 * almacén de certificados de Windows.
 *
 * El protocolo (AID de la aplicación, identificador del archivo del
 * certificado, estructura del comando de firma) se documentó analizando
 * el bytecode del software oficial de RENIEC (firmaperulib), que a su
 * vez usa javax.smartcardio + la librería abierta jnasmartcardio para
 * esto mismo. Esta clase es una reimplementación propia, con nuestro
 * propio código, del mismo protocolo — no contiene código copiado de
 * RENIEC.
 *
 * Esta clase implementa específicamente el protocolo del DNIe "versión
 * 3". Para la versión 2, que usa un protocolo distinto (archivo del
 * certificado, comandos y formato de PIN diferentes), ver
 * {@link DnieCardV2}. {@link DnieVersionDetector} elige cuál usar según
 * el ATR de la tarjeta conectada.
 */
public final class DnieCard implements DnieCardOperations {

    // AID de la aplicación del DNIe dentro del chip.
    private static final byte[] AID_APLICACION =
            HexFormat.of().parseHex("A000000077030C60000000FE00000500");

    // AID del segundo nivel de selección (su nombre en ASCII termina en "Generic").
    private static final byte[] AID_GENERICO =
            HexFormat.of().parseHex("E828BD080FD25047656E65726963");

    // Identificador (EF) del archivo que contiene el certificado de FIRMA
    // (distinto del de autenticación).
    private static final byte[] EF_CERTIFICADO_FIRMA =
            HexFormat.of().parseHex("CE82");

    // Comando MSE:SET que prepara la clave privada de firma (referencia
    // 0x82) y el algoritmo (referencia 0x42) antes de firmar.
    private static final byte[] MSE_SET_FIRMA =
            HexFormat.of().parseHex("002241B606840182800142");

    private final Card tarjeta;
    private final ApduTransceiver apdu;

    public DnieCard(Card tarjeta) {
        this.tarjeta = tarjeta;
        this.apdu = new ApduTransceiver(tarjeta.getBasicChannel());
    }

    public void cerrar() {
        try {
            tarjeta.disconnect(true);
        } catch (CardException ignorado) {
            // No hay mucho que hacer si falla el desconectado; no es crítico.
        }
    }

    private void seleccionarAplicacion() throws CardException {
        apdu.transmitirEsperandoExito(comandoSelectPorAid(AID_APLICACION));
        apdu.transmitirEsperandoExito(comandoSelectPorAid(AID_GENERICO));
    }

    private static byte[] comandoSelectPorAid(byte[] aid) {
        return concatenar(new byte[]{0x00, (byte) 0xA4, 0x04, 0x04, (byte) aid.length}, aid);
    }

    /** Lee el certificado de FIRMA completo (en formato DER) del chip. */
    public byte[] leerCertificadoFirma() throws CardException {
        seleccionarAplicacion();

        byte[] comandoSelectEf = concatenar(
                new byte[]{0x00, (byte) 0xA4, 0x02, 0x0C, (byte) EF_CERTIFICADO_FIRMA.length},
                EF_CERTIFICADO_FIRMA);
        apdu.transmitirEsperandoExito(comandoSelectEf);

        ByteArrayOutputStream datos = new ByteArrayOutputStream();
        int offset = 0;

        while (true) {
            byte[] comandoReadBinary = {
                    0x00, (byte) 0xB0,
                    (byte) ((offset >> 8) & 0xFF), (byte) (offset & 0xFF),
                    (byte) 0xFF // Le = 255: lee hasta 255 bytes por bloque
            };
            ResponseAPDU respuesta = apdu.transmitir(comandoReadBinary);
            int sw = respuesta.getSW();
            byte[] bloque = respuesta.getData();

            if (sw == 0x9000) {
                // Bloque completo: lo guardamos y seguimos leyendo.
                datos.write(bloque, 0, bloque.length);
                offset += bloque.length;
            } else if (sw == 0x6282) {
                // Fin de archivo alcanzado en este mismo bloque (lectura
                // corta): guardamos lo que vino y terminamos.
                datos.write(bloque, 0, bloque.length);
                break;
            } else if (sw == 0x6B00) {
                // El offset ya cayó fuera del archivo: no hay más datos.
                break;
            } else {
                throw new CardException(String.format(
                        "Error leyendo el certificado de firma: SW=%04X", sw));
            }
        }

        return datos.toByteArray();
    }

    /**
     * Verifica el PIN del DNIe de forma independiente (por ejemplo, para
     * un futuro botón de "comprobar PIN" sin firmar nada). Para firmar,
     * usa {@link #firmarConPin(String, byte[])} en su lugar: el chip
     * necesita que la verificación de PIN y la firma ocurran en la misma
     * sesión, sin volver a seleccionar la aplicación entre medio.
     *
     * @throws PinIncorrectoException si el PIN es incorrecto (indica
     *                                 cuántos intentos quedan).
     * @throws TarjetaBloqueadaException si ya no quedan intentos.
     */
    public void verificarPin(String pin) throws CardException, PinIncorrectoException, TarjetaBloqueadaException {
        seleccionarAplicacion();
        enviarVerifyPin(pin);
    }

    private void enviarVerifyPin(String pin) throws CardException, PinIncorrectoException, TarjetaBloqueadaException {
        if (pin == null || pin.length() < 4 || pin.length() > 8) {
            throw new IllegalArgumentException("El PIN debe tener entre 4 y 8 caracteres.");
        }

        // El PIN se envía en un bloque de 12 bytes: los dígitos seguidos
        // de relleno 0xFF hasta completar los 12 bytes.
        byte[] bloquePin = new byte[12];
        Arrays.fill(bloquePin, (byte) 0xFF);
        byte[] pinBytes = pin.getBytes();
        System.arraycopy(pinBytes, 0, bloquePin, 0, Math.min(pinBytes.length, 12));

        byte[] comandoVerify = concatenar(
                new byte[]{0x00, 0x20, 0x00, 0x03, (byte) bloquePin.length},
                bloquePin);

        ResponseAPDU respuesta;
        try {
            respuesta = apdu.transmitir(comandoVerify);
        } finally {
            Arrays.fill(bloquePin, (byte) 0x00);
            Arrays.fill(pinBytes, (byte) 0x00);
        }

        int sw = respuesta.getSW();
        if (sw == 0x9000) {
            return; // PIN correcto
        }

        int sw1 = (sw >> 8) & 0xFF;
        if (sw1 == 0x63) {
            int intentosRestantes = sw & 0x0F;
            throw new PinIncorrectoException(intentosRestantes);
        }
        if (sw == 0x6983) {
            throw new TarjetaBloqueadaException();
        }
        throw new CardException(String.format("Error verificando el PIN: SW=%04X", sw));
    }

    /**
     * Verifica el PIN y firma el DigestInfo recibido (algoritmo de hash +
     * hash, codificado en DER) en una sola secuencia ininterrumpida:
     * seleccionar aplicación → verificar PIN → preparar clave (MSE:SET) →
     * firmar (PSO:COMPUTE SIGNATURE).
     *
     * Es importante que no haya una reselección de la aplicación entre la
     * verificación del PIN y la firma: el chip resetea el estado de "PIN
     * verificado" si se vuelve a seleccionar la aplicación en medio (así
     * se descubrió al probar con hardware real: sin esto, la firma falla
     * con SW=6982 "estado de seguridad no satisfecho").
     */
    public byte[] firmarConPin(String pin, byte[] digestInfo)
            throws CardException, PinIncorrectoException, TarjetaBloqueadaException {
        seleccionarAplicacion();
        enviarVerifyPin(pin);

        apdu.transmitirEsperandoExito(MSE_SET_FIRMA);

        byte[] comandoFirma = concatenar(
                new byte[]{0x00, 0x2A, (byte) 0x9E, (byte) 0x9A, (byte) digestInfo.length},
                digestInfo,
                new byte[]{0x00});

        return apdu.transmitirEsperandoExito(comandoFirma);
    }

    private static byte[] concatenar(byte[]... partes) {
        int total = 0;
        for (byte[] p : partes) {
            total += p.length;
        }
        byte[] resultado = new byte[total];
        int pos = 0;
        for (byte[] p : partes) {
            System.arraycopy(p, 0, resultado, pos, p.length);
            pos += p.length;
        }
        return resultado;
    }
}
