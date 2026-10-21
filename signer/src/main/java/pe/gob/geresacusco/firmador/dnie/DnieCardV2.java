package pe.gob.geresacusco.firmador.dnie;

import javax.smartcardio.Card;
import javax.smartcardio.CardException;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;
import java.io.ByteArrayOutputStream;
import java.util.HexFormat;

/**
 * Protocolo APDU para DNIe "versión 2". Es un protocolo distinto al de
 * la versión 3 ({@link DnieCard}): otro archivo para el certificado,
 * otra forma de leerlo, otra referencia de PIN, y — lo más importante —
 * aquí sí hay que mandar el DigestInfo completo (DER) al firmar, no el
 * hash crudo.
 *
 * Documentado a partir del bytecode de la clase original "O" y su
 * helper "g" (que arma el DigestInfo); reimplementado con código propio.
 */
public final class DnieCardV2 implements DnieCardOperations {

    // AID "Generic": acá no hay un AID "maestro" previo como en v3, se
    // selecciona directo.
    private static final byte[] AID_GENERICO =
            HexFormat.of().parseHex("E828BD080FD25047656E65726963");

    // Identificador (EF) del archivo del certificado de firma en v2
    // (distinto del "CE82" de v3).
    private static final byte[] EF_CERTIFICADO_FIRMA = {0x00, 0x1D};

    // MSE:SET para v2: algoritmo (ref. 0x8A) y clave (ref. 0x81) — otras
    // referencias que las de v3.
    private static final byte[] MSE_SET_FIRMA =
            HexFormat.of().parseHex("002241B60680018A840181");

    // Prefijo DER estándar de DigestInfo para SHA-256 (RFC 8017 / PKCS#1):
    // SEQUENCE { SEQUENCE { OID sha256, NULL }, OCTET STRING (32 bytes) }
    private static final byte[] PREFIJO_DIGESTINFO_SHA256 =
            HexFormat.of().parseHex("3031300D060960864801650304020105000420");

    private final Card tarjeta;
    private final ApduTransceiver apdu;
    private boolean aplicacionSeleccionada = false;

    public DnieCardV2(Card tarjeta) {
        this.tarjeta = tarjeta;
        this.apdu = new ApduTransceiver(tarjeta.getBasicChannel());
    }

    @Override
    public void cerrar() {
        try {
            tarjeta.disconnect(true);
        } catch (CardException ignorado) {
        }
    }

    private void seleccionarAplicacionSiHaceFalta() throws CardException {
        if (aplicacionSeleccionada) {
            return;
        }
        byte[] comandoSelect = concatenar(
                new byte[]{0x00, (byte) 0xA4, 0x04, 0x00, (byte) AID_GENERICO.length},
                AID_GENERICO);
        apdu.transmitirEsperandoExito(comandoSelect);
        aplicacionSeleccionada = true;
    }

    @Override
    public byte[] leerCertificadoFirma() throws CardException {
        seleccionarAplicacionSiHaceFalta();

        byte[] comandoSelectEf = concatenar(
                new byte[]{0x00, (byte) 0xA4, 0x02, 0x04, (byte) EF_CERTIFICADO_FIRMA.length},
                EF_CERTIFICADO_FIRMA);
        apdu.transmitirEsperandoExito(comandoSelectEf);

        return leerBinarioCompleto();
    }

    /**
     * Lectura por bloques usando READ BINARY con instrucción impar
     * (0xB1): el offset va dentro de los datos del comando, como un
     * objeto TLV (tag 0x54), no en P1/P2 como en la versión clásica. La
     * respuesta de cada bloque viene envuelta en un objeto TLV también,
     * así que hay que descartar su cabecera para quedarnos con el
     * contenido real.
     */
    private byte[] leerBinarioCompleto() throws CardException {
        ByteArrayOutputStream datos = new ByteArrayOutputStream();
        int offset = 0;

        try {
            tarjeta.beginExclusive();
            while (true) {
                byte[] datosOffset = {
                        0x54, 0x02,
                        (byte) ((offset >> 8) & 0xFF), (byte) (offset & 0xFF)
                };
                CommandAPDU comando = new CommandAPDU(0x00, 0xB1, 0x00, 0x00, datosOffset, 255);
                ResponseAPDU respuesta = apdu.transmitir(comando.getBytes());
                int sw = respuesta.getSW();
                byte[] cuerpo = respuesta.getData();

                if (sw != 0x6B00 && cuerpo.length >= 4) {
                    // El contenido real viene envuelto en un objeto TLV:
                    // se descartan los primeros 3 bytes (cabecera) y el
                    // último byte, quedándonos con los datos del bloque.
                    byte[] contenido = java.util.Arrays.copyOfRange(cuerpo, 3, cuerpo.length - 1);
                    datos.write(contenido);
                    offset += contenido.length;
                }

                if (sw == 0x6282) {
                    break; // fin de archivo
                }
                if (sw == 0x6B00) {
                    break; // offset fuera de rango: no hay más datos
                }
                // sw == 0x9000 (u otro que incluya datos válidos): seguir leyendo
            }
        } catch (java.io.IOException e) {
            throw new CardException("Error leyendo el certificado: " + e.getMessage(), e);
        } finally {
            tarjeta.endExclusive();
        }

        return datos.toByteArray();
    }

    /**
     * Consulta cuántos intentos de PIN quedan, sin verificar nada
     * (comando VERIFY sin datos: es la forma estándar ISO 7816 de
     * consultar el contador de intentos).
     */
    public int intentosPinRestantes() throws CardException {
        seleccionarAplicacionSiHaceFalta();
        ResponseAPDU respuesta = apdu.transmitir(new byte[]{0x00, 0x20, 0x00, (byte) 0x81});
        int sw1 = respuesta.getSW1();
        int sw2 = respuesta.getSW2();
        int sw = respuesta.getSW();

        if (sw1 == 0x90 && sw2 == 0x00) {
            return 5; // valor por defecto cuando no se ha intentado todavía
        }
        if (sw1 == 0x63 && sw2 >= 0xC0) {
            return (sw2 % 10) - 2;
        }
        if (sw == 0x6983) {
            return 0;
        }
        throw new CardException(String.format("Respuesta inesperada consultando intentos: SW=%04X", sw));
    }

    @Override
    public byte[] firmarConPin(String pin, byte[] hashSinFormatear)
            throws CardException, PinIncorrectoException, TarjetaBloqueadaException {
        seleccionarAplicacionSiHaceFalta();

        // 1) Verificar PIN. En v2 el bloque de PIN son los dígitos tal
        //    cual (sin relleno), a diferencia del bloque de 12 bytes con
        //    relleno 0xFF que usa v3.
        byte[] pinBytes = pin.getBytes();
        byte[] comandoVerify = concatenar(
                new byte[]{0x00, 0x20, 0x00, (byte) 0x81, (byte) pinBytes.length},
                pinBytes);

        ResponseAPDU respuestaVerify;
        try {
            respuestaVerify = apdu.transmitir(comandoVerify);
        } finally {
            java.util.Arrays.fill(pinBytes, (byte) 0x00);
        }

        int sw = respuestaVerify.getSW();
        if (sw != 0x9000) {
            if (sw == 0x6983) {
                throw new TarjetaBloqueadaException();
            }
            int sw1 = (sw >> 8) & 0xFF;
            int sw2 = sw & 0xFF;
            if (sw1 == 0x63) {
                int intentosRestantes = Math.max(0, (sw2 % 10) - 2);
                throw new PinIncorrectoException(intentosRestantes);
            }
            throw new CardException(String.format("Error verificando el PIN: SW=%04X", sw));
        }

        // 2) Preparar la clave de firma.
        apdu.transmitirEsperandoExito(MSE_SET_FIRMA);

        // 3) El chip espera el DigestInfo completo (DER), no el hash
        //    crudo — a diferencia de v3. Si ya viene con forma de
        //    DigestInfo (más largo que un hash SHA-256 de 32 bytes), se
        //    usa tal cual; si viene como hash crudo de 32 bytes, se le
        //    antepone el prefijo DER de SHA-256.
        byte[] digestInfo = hashSinFormatear.length == 32
                ? concatenar(PREFIJO_DIGESTINFO_SHA256, hashSinFormatear)
                : hashSinFormatear;

        // 4) Firmar. A diferencia de v3, este comando no pide un largo
        //    de respuesta explícito (sin byte Le al final).
        CommandAPDU comandoFirma = new CommandAPDU(0x00, 0x2A, 0x9E, 0x9A, digestInfo);
        ResponseAPDU respuestaFirma = apdu.transmitir(comandoFirma.getBytes());
        if (respuestaFirma.getSW() != 0x9000) {
            throw new CardException(String.format(
                    "Respuesta inesperada al firmar: SW=%04X", respuestaFirma.getSW()));
        }
        return respuestaFirma.getData();
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
