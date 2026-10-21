package pe.gob.geresacusco.firmador.dnie;

import javax.smartcardio.Card;
import javax.smartcardio.CardException;
import java.util.Arrays;
import java.util.HexFormat;

/**
 * Identifica qué versión de DNIe está conectada, a partir de su ATR
 * (la "huella" que la tarjeta reporta al conectarse — estándar ISO
 * 7816-3), y devuelve la implementación de protocolo correspondiente.
 *
 * Los patrones de ATR se documentaron a partir del bytecode del
 * software oficial de RENIEC (clase "I").
 */
public final class DnieVersionDetector {

    private static final byte[] ATR_V1 =
            HexFormat.of().parseHex("3BDD18008131FE4580F9A0000000770100700A90008B");

    private static final byte[] ATR_V2_LARGO =
            HexFormat.of().parseHex("3BDC18FF8191FE1FC38073C821136605036351000250");

    private static final byte[] ATR_V2_CORTO =
            HexFormat.of().parseHex("3B80800101");

    private DnieVersionDetector() {
    }

    public static DnieCardOperations detectar(Card tarjeta) throws CardException {
        byte[] atr = tarjeta.getATR().getBytes();
        System.out.println("[DNIe] ATR detectado: " + HexFormat.of().formatHex(atr).toUpperCase());

        if (Arrays.equals(atr, ATR_V1)) {
            throw new CardException(
                    "Se detectó un DNIe versión 1 (ATR coincide con el patrón de v1). "
                            + "Esta versión todavía no está implementada en el firmador.");
        }

        if (Arrays.equals(atr, ATR_V2_LARGO) || Arrays.equals(atr, ATR_V2_CORTO)) {
            return new DnieCardV2(tarjeta);
        }

        // Si no coincide con v1 ni v2, asumimos v3 (es lo que hacía el
        // software original: probaba un comando y, si respondía bien,
        // asumía v3; aquí simplificamos asumiéndolo directamente, ya que
        // es la versión más común hoy).
        return new DnieCard(tarjeta);
    }
}
