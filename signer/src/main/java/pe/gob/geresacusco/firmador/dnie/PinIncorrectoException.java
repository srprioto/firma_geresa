package pe.gob.geresacusco.firmador.dnie;

/**
 * El PIN ingresado es incorrecto. El chip del DNIe informa cuántos
 * intentos quedan antes de bloquearse (patrón estándar ISO 7816: el
 * código de estado "63 Cx" donde x es el número de intentos restantes).
 */
public class PinIncorrectoException extends Exception {

    private final int intentosRestantes;

    public PinIncorrectoException(int intentosRestantes) {
        super("PIN incorrecto. Intentos restantes: " + intentosRestantes);
        this.intentosRestantes = intentosRestantes;
    }

    public int getIntentosRestantes() {
        return intentosRestantes;
    }
}
