package pe.gob.geresacusco.firmador.dnie;

import javax.smartcardio.CardChannel;
import javax.smartcardio.CardException;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;

/**
 * Envoltorio delgado sobre {@link CardChannel} para enviar comandos APDU
 * (ISO 7816-4) y validar la respuesta.
 */
public final class ApduTransceiver {

    private final CardChannel canal;

    public ApduTransceiver(CardChannel canal) {
        this.canal = canal;
    }

    public ResponseAPDU transmitir(byte[] apdu) throws CardException {
        return canal.transmit(new CommandAPDU(apdu));
    }

    /**
     * Envía el comando y exige que el código de estado (SW) sea
     * exactamente 0x9000 (éxito). Devuelve solo los datos de la
     * respuesta (sin los 2 bytes de SW).
     */
    public byte[] transmitirEsperandoExito(byte[] apdu) throws CardException {
        ResponseAPDU respuesta = transmitir(apdu);
        if (respuesta.getSW() != 0x9000) {
            throw new CardException(String.format(
                    "Respuesta inesperada de la tarjeta: SW=%04X", respuesta.getSW()));
        }
        return respuesta.getData();
    }
}
