import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

public class TradeLogAnalyzer {

    public static void main(String[] args) {
        // Validación de argumentos (Edge case: el usuario no pasó el archivo)
        if (args.length == 0) {
            System.err.println("Uso crítico: java TradeLogAnalyzer <ruta_del_archivo.log>");
            System.exit(1);
        }

        String logFilePath = args[0];
        Map<String, Integer> errorCounts = new HashMap<>();
        int totalLinesProcessed = 0;

        System.out.println("[*] Iniciando Triage de Logs en: " + logFilePath);

        // Uso de try-with-resources para evitar fugas de descriptores de archivos (File Descriptors)
        try (BufferedReader reader = new BufferedReader(new FileReader(logFilePath))) {
            String line;
            
            // Leemos línea por línea para no saturar la memoria RAM (Heap) con logs masivos
            while ((line = reader.readLine()) != null) {
                totalLinesProcessed++;
                
                // Filtramos anomalías críticas
                if (line.contains("ERROR") || line.contains("FATAL") || line.contains("Exception")) {
                    String errorType = categorizeError(line);
                    // Actualizamos el contador de este error específico
                    errorCounts.put(errorType, errorCounts.getOrDefault(errorType, 0) + 1);
                }
            }
        } catch (IOException e) {
            System.err.println("[!] Fallo de I/O al intentar leer el archivo: " + e.getMessage());
            System.exit(1);
        }

        generateReport(totalLinesProcessed, errorCounts);
    }

    // Método para clasificar el tipo de incidente basado en el texto
    private static String categorizeError(String logLine) {
        if (logLine.contains("NullPointerException")) return "NullPointerException (Fallo de Código)";
        if (logLine.contains("ConnectionTimeout")) return "ConnectionTimeout (Fallo de Red/Infra)";
        if (logLine.contains("TransactionRejected")) return "TransactionRejected (Lógica de Negocio)";
        return "Generic_ERROR (Requiere revisión manual L3)";
    }

    // Método para imprimir el resumen ejecutivo
    private static void generateReport(int lines, Map<String, Integer> counts) {
        System.out.println("\n=== REPORTE DE TRIAGE L2 (AUTOMATIZADO) ===");
        System.out.println("Líneas procesadas: " + lines);
        
        if (counts.isEmpty()) {
            System.out.println("Estado de la Planta: VERDE. No se detectaron incidentes críticos.");
        } else {
            System.out.println("Estado de la Planta: ROJO. Incidentes detectados:");
            for (Map.Entry<String, Integer> entry : counts.entrySet()) {
                System.out.println(" -> [" + entry.getValue() + "] " + entry.getKey());
            }
        }
        System.out.println("===========================================");
    }
}
