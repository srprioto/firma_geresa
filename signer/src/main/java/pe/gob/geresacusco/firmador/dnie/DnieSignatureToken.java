package pe.gob.geresacusco.firmador.dnie;

import eu.europa.esig.dss.enumerations.DigestAlgorithm;
import eu.europa.esig.dss.enumerations.SignatureAlgorithm;
import eu.europa.esig.dss.model.SignatureValue;
import eu.europa.esig.dss.model.ToBeSigned;
import eu.europa.esig.dss.model.x509.CertificateToken;
import eu.europa.esig.dss.spi.DSSUtils;
import eu.europa.esig.dss.token.DSSPrivateKeyEntry;
import eu.europa.esig.dss.token.SignatureTokenConnection;

import org.bouncycastle.asn1.ASN1ObjectIdentifier;
import org.bouncycastle.asn1.DERNull;
import org.bouncycastle.asn1.x509.AlgorithmIdentifier;
import org.bouncycastle.asn1.x509.DigestInfo;

import javax.smartcardio.Card;
import javax.smartcardio.CardException;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.TerminalFactory;
import java.io.ByteArrayInputStream;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;

/**
 * Implementación de {@link SignatureTokenConnection} de DSS respaldada
 * por acceso directo al chip del DNIe vía javax.smartcardio +
 * jnasmartcardio (PC/SC estándar) — no depende de ningún driver de
 * fabricante, así que funciona con cualquier lector que Windows
 * reconozca.
 *
 * El PIN se recibe por {@link #establecerPin(String)} ANTES de llamar a
 * {@link #sign}, porque la interfaz estándar de DSS no incluye el PIN en
 * su firma de método — el DNIe sí lo necesita en el momento de firmar.
 */
public class DnieSignatureToken implements SignatureTokenConnection {

    private Card tarjeta;
    private DnieCard dnieCard;
    private CertificateToken certificadoFirma;
    private String pin;

    private void conectar() throws CardException {
        if (tarjeta != null) {
            return;
        }

        TerminalFactory factory;
        try {
            factory = TerminalFactory.getInstance("PC/SC", null, new jnasmartcardio.Smartcardio());
        } catch (Exception e) {
            throw new CardException("No se pudo inicializar PC/SC: " + e.getMessage(), e);
        }

        List<CardTerminal> terminales;
        try {
            terminales = factory.terminals().list();
        } catch (CardException e) {
            throw new CardException(
                    "No se encontró ningún lector de tarjetas conectado.", e);
        }

        for (CardTerminal terminal : terminales) {
            if (terminal.isCardPresent()) {
                this.tarjeta = terminal.connect("*");
                this.dnieCard = new DnieCard(this.tarjeta);
                return;
            }
        }
        throw new CardException(
                "No se detectó ningún lector con una tarjeta/DNIe insertada.");
    }

    /** Debe llamarse antes de {@link #sign}; el DNIe necesita el PIN para firmar. */
    public void establecerPin(String pin) {
        this.pin = pin;
    }

    @Override
    public List<DSSPrivateKeyEntry> getKeys() {
        try {
            conectar();
            if (certificadoFirma == null) {
                byte[] der = dnieCard.leerCertificadoFirma();
                CertificateFactory cf = CertificateFactory.getInstance("X.509");
                X509Certificate cert = (X509Certificate)
                        cf.generateCertificate(new ByteArrayInputStream(der));
                certificadoFirma = new CertificateToken(cert);
            }
            List<DSSPrivateKeyEntry> lista = new ArrayList<>();
            lista.add(new DniePrivateKeyEntry(certificadoFirma));
            return lista;
        } catch (Exception e) {
            throw new RuntimeException(
                    "No se pudo leer el certificado del DNIe: " + e.getMessage(), e);
        }
    }

    // --- Las siguientes son todas las variantes de "firmar" que exige la
    // interfaz SignatureTokenConnection de DSS. En nuestro flujo real
    // (SignerService → PAdESService) solo se usa la primera variante de
    // "sign"; las demás quedan implementadas igual por si DSS las usa
    // internamente en otro escenario, todas reutilizando la misma lógica.

    @Override
    public SignatureValue sign(ToBeSigned toBeSigned, DigestAlgorithm digestAlgorithm,
                                DSSPrivateKeyEntry keyEntry) {
        byte[] digest = DSSUtils.digest(digestAlgorithm, toBeSigned.getBytes());
        SignatureAlgorithm algoritmo = SignatureAlgorithm.getAlgorithm(
                keyEntry.getEncryptionAlgorithm(), digestAlgorithm, null);
        return firmarDigestConPin(digest, digestAlgorithm, algoritmo);
    }

    @Override
    public SignatureValue sign(ToBeSigned toBeSigned, DigestAlgorithm digestAlgorithm,
                                eu.europa.esig.dss.enumerations.MaskGenerationFunction mgf,
                                DSSPrivateKeyEntry keyEntry) {
        // Mismo caso que el signDigest con MGF más abajo: el DNIe, tal
        // como está configurado, no firma con RSA-PSS.
        throw new UnsupportedOperationException(
                "El DNIe no está configurado para firmar con RSA-PSS (MaskGenerationFunction). "
                        + "Usa un nivel de firma que no lo requiera (PAdES-B estándar no lo necesita).");
    }

    @Override
    public SignatureValue sign(ToBeSigned toBeSigned, SignatureAlgorithm signatureAlgorithm,
                                DSSPrivateKeyEntry keyEntry) {
        DigestAlgorithm digestAlgorithm = signatureAlgorithm.getDigestAlgorithm();
        byte[] digest = DSSUtils.digest(digestAlgorithm, toBeSigned.getBytes());
        return firmarDigestConPin(digest, digestAlgorithm, signatureAlgorithm);
    }

    @Override
    public SignatureValue signDigest(eu.europa.esig.dss.model.Digest digest,
                                      SignatureAlgorithm signatureAlgorithm,
                                      DSSPrivateKeyEntry keyEntry) {
        return firmarDigestConPin(digest.getValue(), digest.getAlgorithm(), signatureAlgorithm);
    }

    @Override
    public SignatureValue signDigest(eu.europa.esig.dss.model.Digest digest,
                                      DSSPrivateKeyEntry keyEntry) {
        SignatureAlgorithm algoritmo = SignatureAlgorithm.getAlgorithm(
                keyEntry.getEncryptionAlgorithm(), digest.getAlgorithm(), null);
        return firmarDigestConPin(digest.getValue(), digest.getAlgorithm(), algoritmo);
    }

    @Override
    public SignatureValue signDigest(eu.europa.esig.dss.model.Digest digest,
                                      eu.europa.esig.dss.enumerations.MaskGenerationFunction mgf,
                                      DSSPrivateKeyEntry keyEntry) {
        // El DNIe, tal como lo configuramos (MSE:SET con la referencia de
        // algoritmo 0x42), firma con RSA + relleno PKCS#1 v1.5 clásico,
        // no con RSA-PSS (que es lo que usaría una función de generación
        // de máscara). Si en algún momento se necesita PSS, hay que
        // revisar qué otra referencia de algoritmo espera el chip.
        throw new UnsupportedOperationException(
                "El DNIe no está configurado para firmar con RSA-PSS (MaskGenerationFunction). "
                        + "Usa un nivel de firma que no lo requiera (PAdES-B estándar no lo necesita).");
    }

    private SignatureValue firmarDigestConPin(byte[] digest, DigestAlgorithm digestAlgorithm,
                                               SignatureAlgorithm signatureAlgorithm) {
        if (pin == null || pin.isEmpty()) {
            throw new IllegalStateException(
                    "No se estableció el PIN antes de firmar (llama a establecerPin(pin) primero).");
        }
        try {
            conectar();

            // INTENTO 2: el chip respondió SW=6985 ("condiciones de uso no
            // satisfechas") al mandarle el DigestInfo completo (hash +
            // envoltorio ASN.1 con el OID del algoritmo). La hipótesis
            // ahora es que, como el algoritmo ya se fijó en el MSE:SET
            // (referencia 0x42), el chip espera solo el HASH CRUDO y arma
            // el relleno PKCS#1 internamente. Si esto tampoco funciona,
            // volvemos al DigestInfo completo (más abajo, comentado) y
            // probamos otras variantes.
            byte[] firmaCruda = dnieCard.firmarConPin(pin, digest);
            // byte[] digestInfo = construirDigestInfo(digestAlgorithm, digest);
            // byte[] firmaCruda = dnieCard.firmarConPin(pin, digestInfo);

            return new SignatureValue(signatureAlgorithm, firmaCruda);

        } catch (PinIncorrectoException e) {
            throw new RuntimeException(
                    "PIN incorrecto. Intentos restantes: " + e.getIntentosRestantes(), e);
        } catch (TarjetaBloqueadaException e) {
            throw new RuntimeException(e.getMessage(), e);
        } catch (Exception e) {
            throw new RuntimeException("Error firmando con el DNIe: " + e.getMessage(), e);
        } finally {
            // El PIN nunca se retiene más de lo necesario.
            pin = null;
        }
    }

    /**
     * Arma la estructura DigestInfo (ASN.1: algoritmo de hash + hash),
     * tal como la espera el comando PSO:COMPUTE DIGITAL SIGNATURE del
     * chip para RSA con relleno PKCS#1 v1.5.
     *
     * NOTA: este es el punto más sensible a validar con hardware real.
     * Si la firma resultante no pasa la verificación, este es el primer
     * lugar a revisar (podría necesitar un relleno distinto, según cómo
     * esté configurada la referencia de algoritmo 0x42 del comando
     * MSE:SET).
     */
    private static byte[] construirDigestInfo(DigestAlgorithm algoritmo, byte[] digest) throws Exception {
        ASN1ObjectIdentifier oid = new ASN1ObjectIdentifier(algoritmo.getOid());
        AlgorithmIdentifier algId = new AlgorithmIdentifier(oid, DERNull.INSTANCE);
        DigestInfo digestInfo = new DigestInfo(algId, digest);
        return digestInfo.getEncoded();
    }

    @Override
    public void close() {
        if (dnieCard != null) {
            dnieCard.cerrar();
        }
        tarjeta = null;
        dnieCard = null;
        pin = null;
    }
}
