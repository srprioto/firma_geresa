package pe.gob.geresacusco.firmador;

import eu.europa.esig.dss.enumerations.DigestAlgorithm;
import eu.europa.esig.dss.enumerations.SignatureLevel;
import eu.europa.esig.dss.model.DSSDocument;
import eu.europa.esig.dss.model.InMemoryDocument;
import eu.europa.esig.dss.model.SignatureValue;
import eu.europa.esig.dss.model.ToBeSigned;
import eu.europa.esig.dss.pades.PAdESSignatureParameters;
import eu.europa.esig.dss.pades.signature.PAdESService;
import eu.europa.esig.dss.token.DSSPrivateKeyEntry;
import eu.europa.esig.dss.validation.CommonCertificateVerifier;

import pe.gob.geresacusco.firmador.dnie.DnieSignatureToken;

import java.io.ByteArrayOutputStream;
import java.security.cert.X509Certificate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Orquesta la firma de PDF con el DNIe: conecta con el chip (vía
 * {@link DnieSignatureToken}, nuestra propia implementación del
 * protocolo APDU), arma la firma PAdES con DSS, y cierra la sesión.
 */
public class SignerService {

    /** Lee (sin PIN) los datos del titular del certificado de firma del DNIe conectado. */
    public Map<String, Object> obtenerTitular() {
        DnieSignatureToken token = new DnieSignatureToken();
        try {
            List<DSSPrivateKeyEntry> claves = token.getKeys();
            if (claves.isEmpty()) {
                throw new IllegalStateException("No se encontró ningún certificado en el DNIe.");
            }
            X509Certificate cert = claves.get(0).getCertificate().getCertificate();

            Map<String, Object> item = new LinkedHashMap<>();
            item.put("sujeto", cert.getSubjectX500Principal().getName());
            item.put("numero_serie_certificado", cert.getSerialNumber().toString());
            item.put("valido_hasta", cert.getNotAfter().toString());
            return item;
        } finally {
            token.close();
        }
    }

    /** Firma digitalmente el PDF (PAdES-B) con el PIN del DNIe. */
    public byte[] firmarPdf(byte[] pdfBytes, String pin) throws Exception {
        DnieSignatureToken token = new DnieSignatureToken();
        try {
            List<DSSPrivateKeyEntry> claves = token.getKeys();
            if (claves.isEmpty()) {
                throw new IllegalStateException("No se encontró ningún certificado en el DNIe.");
            }
            DSSPrivateKeyEntry clave = claves.get(0);
            token.establecerPin(pin);

            DSSDocument documentoOriginal = new InMemoryDocument(pdfBytes);

            PAdESSignatureParameters parametros = new PAdESSignatureParameters();
            parametros.setSignatureLevel(SignatureLevel.PAdES_BASELINE_B);
            parametros.setDigestAlgorithm(DigestAlgorithm.SHA256);
            parametros.setSigningCertificate(clave.getCertificate());
            parametros.setCertificateChain(clave.getCertificateChain());

            CommonCertificateVerifier verificador = new CommonCertificateVerifier();
            PAdESService servicio = new PAdESService(verificador);

            ToBeSigned paraFirmar = servicio.getDataToSign(documentoOriginal, parametros);
            SignatureValue valorFirma = token.sign(paraFirmar, parametros.getDigestAlgorithm(), clave);
            DSSDocument documentoFirmado = servicio.signDocument(documentoOriginal, parametros, valorFirma);

            ByteArrayOutputStream salida = new ByteArrayOutputStream();
            documentoFirmado.writeTo(salida);
            return salida.toByteArray();
        } finally {
            token.close();
        }
    }
}
