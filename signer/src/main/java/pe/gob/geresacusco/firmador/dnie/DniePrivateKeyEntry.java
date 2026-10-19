package pe.gob.geresacusco.firmador.dnie;

import eu.europa.esig.dss.enumerations.EncryptionAlgorithm;
import eu.europa.esig.dss.model.x509.CertificateToken;
import eu.europa.esig.dss.token.DSSPrivateKeyEntry;

/**
 * Adapta el certificado de firma leído del DNIe al formato que espera
 * DSS ({@link DSSPrivateKeyEntry}).
 */
public final class DniePrivateKeyEntry implements DSSPrivateKeyEntry {

    private final CertificateToken certificado;

    public DniePrivateKeyEntry(CertificateToken certificado) {
        this.certificado = certificado;
    }

    @Override
    public CertificateToken getCertificate() {
        return certificado;
    }

    @Override
    public CertificateToken[] getCertificateChain() {
        // El DNIe solo entrega el certificado del titular; no trae la
        // cadena completa embebida en el chip (eso se añadirá más
        // adelante al cargar las raíces de RENIEC/IOFE, pendiente a
        // propósito como quedamos).
        return new CertificateToken[]{certificado};
    }

    @Override
    public EncryptionAlgorithm getEncryptionAlgorithm() {
        return EncryptionAlgorithm.RSA;
    }
}
