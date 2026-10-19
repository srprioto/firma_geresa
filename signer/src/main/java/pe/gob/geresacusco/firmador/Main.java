package pe.gob.geresacusco.firmador;

import io.javalin.Javalin;
import io.javalin.http.UploadedFile;

import java.util.List;
import java.util.Map;

/**
 * API local (http://127.0.0.1:8000) que expone el firmador a Flutter.
 */
public class Main {

    public static void main(String[] args) {
        SignerService signerService = new SignerService();
        VerifierService verifierService = new VerifierService();

        Javalin app = Javalin.create().start(8000);

        app.get("/lector/estado", ctx -> {
            try {
                Map<String, Object> titular = signerService.obtenerTitular();
                ctx.json(Map.of("detectado", true, "titular", titular));
            } catch (Exception e) {
                ctx.json(Map.of("detectado", false, "error", String.valueOf(e.getMessage())));
            }
        });

        app.get("/lector/titular", ctx -> {
            try {
                ctx.json(signerService.obtenerTitular());
            } catch (Exception e) {
                ctx.status(400).json(Map.of("detail", String.valueOf(e.getMessage())));
            }
        });

        app.post("/firmar", ctx -> {
            try {
                UploadedFile pdf = ctx.uploadedFile("pdf");
                String pin = ctx.formParam("pin");

                if (pdf == null) {
                    ctx.status(400).json(Map.of("detail", "Falta el archivo 'pdf'."));
                    return;
                }
                if (pin == null || pin.isBlank()) {
                    ctx.status(400).json(Map.of("detail", "Falta el PIN."));
                    return;
                }

                // El campo 'dni' es opcional: si viene, se compara con el
                // sujeto del certificado solo como chequeo informativo.
                String dni = ctx.formParam("dni");
                if (dni != null && !dni.isBlank()) {
                    Map<String, Object> titular = signerService.obtenerTitular();
                    if (!String.valueOf(titular.get("sujeto")).contains(dni.trim())) {
                        ctx.header("X-Advertencia-DNI",
                                "El DNI ingresado no aparece tal cual en el certificado detectado.");
                    }
                }

                byte[] pdfBytes = pdf.content().readAllBytes();
                byte[] firmado = signerService.firmarPdf(pdfBytes, pin);

                ctx.contentType("application/pdf");
                ctx.result(firmado);
            } catch (Exception e) {
                ctx.status(400).json(Map.of("detail", String.valueOf(e.getMessage())));
            }
        });

        app.post("/verificar", ctx -> {
            try {
                UploadedFile pdf = ctx.uploadedFile("pdf");
                if (pdf == null) {
                    ctx.status(400).json(Map.of("detail", "Falta el archivo 'pdf'."));
                    return;
                }
                byte[] pdfBytes = pdf.content().readAllBytes();
                List<Map<String, Object>> reportes = verifierService.verificarPdf(pdfBytes);
                ctx.json(Map.of("firmas", reportes));
            } catch (Exception e) {
                ctx.status(400).json(Map.of("detail", String.valueOf(e.getMessage())));
            }
        });

        System.out.println("Firmador GERESA Cusco escuchando en http://127.0.0.1:8000");
    }
}
