package pe.gob.geresacusco.firmador;

import eu.europa.esig.dss.model.DSSDocument;
import eu.europa.esig.dss.model.InMemoryDocument;
import eu.europa.esig.dss.simplereport.SimpleReport;
import eu.europa.esig.dss.validation.CommonCertificateVerifier;
import eu.europa.esig.dss.validation.SignedDocumentValidator;
import eu.europa.esig.dss.validation.reports.Reports;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Verifica las firmas embebidas en un PDF ya firmado, usando el
 * validador de DSS.
 *
 * Por ahora NO se cargan certificados raíz de confianza propios de
 * RENIEC/IOFE (eso queda pendiente a propósito, como quedamos). Esto
 * valida integridad del documento y la estructura de la firma; la
 * confianza completa de la cadena se añade después.
 *
 * Si algún método de SimpleReport no coincide exactamente con tu
 * versión de DSS, revisa el javadoc del jar descargado: esta es la API
 * de reportes estándar de DSS, pero los nombres de métodos han ido
 * cambiando ligeramente entre versiones 5.x y 6.x.
 */
public class VerifierService {

    public List<Map<String, Object>> verificarPdf(byte[] pdfBytes) {
        DSSDocument documento = new InMemoryDocument(pdfBytes);

        SignedDocumentValidator validador = SignedDocumentValidator.fromDocument(documento);
        validador.setCertificateVerifier(new CommonCertificateVerifier());

        Reports reportes = validador.validateDocument();
        SimpleReport reporteSimple = reportes.getSimpleReport();

        List<Map<String, Object>> resultado = new ArrayList<>();
        for (String idFirma : reporteSimple.getSignatureIdList()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("id_firma", idFirma);
            item.put("firmante", reporteSimple.getSignedBy(idFirma));
            item.put("indicacion", String.valueOf(reporteSimple.getIndication(idFirma)));
            resultado.add(item);
        }
        return resultado;
    }
}
