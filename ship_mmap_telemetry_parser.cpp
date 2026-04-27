// =====================================================================
// SHIP NOC - High-Performance Telemetry Parser (Zero-Copy)
// Compilación: g++ -O3 -std=c++17 ship_mmap_telemetry_parser.cpp -o telemetry_parser
// =====================================================================

#include <iostream>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#include <cstring>
#include <string_view>
#include <vector>

// Firmas críticas de incidentes que rompen SLAs en entornos Cloud (OCI/AWS)
constexpr std::string_view CRITICAL_SIGNATURES[] = {
    "Out of memory: Killed process",
    "Kernel panic - not syncing",
    "ext4_fs_error",
    "deadlock detected"
};

void scan_memory_mapped_file(const char* filepath) {
    // 1. Abrir archivo a bajo nivel (POSIX)
    int fd = open(filepath, O_RDONLY);
    if (fd == -1) {
        std::cerr << "[ERROR] Fallo al abrir el archivo. Verifique permisos.\n";
        return;
    }

    // 2. Obtener tamaño exacto del archivo
    struct stat sb;
    if (fstat(fd, &sb) == -1) {
        std::cerr << "[ERROR] Fallo al obtener metadatos del archivo.\n";
        close(fd);
        return;
    }

    size_t length = sb.st_size;
    if (length == 0) {
        std::cout << "[INFO] Archivo de telemetría vacío.\n";
        close(fd);
        return;
    }

    // 3. MAGIA DE INGENIERÍA: Memory Mapping (Bypass de RAM)
    // Mapea el disco directamente al espacio de direcciones virtuales del proceso.
    char* data = static_cast<char*>(mmap(nullptr, length, PROT_READ, MAP_PRIVATE, fd, 0));
    if (data == MAP_FAILED) {
        std::cerr << "[FATAL] Fallo al ejecutar mmap. El kernel denegó la operación.\n";
        close(fd);
        return;
    }

    std::cout << "[INFO] Mapeo Zero-Copy exitoso. Escaneando " << (length / 1024 / 1024) << " MB...\n";

    // 4. Búsqueda de alta velocidad usando std::string_view (C++17)
    // No se hace ninguna copia de strings, solo se mueven punteros.
    std::string_view file_view(data, length);
    int incidents_found = 0;

    for (const auto& signature : CRITICAL_SIGNATURES) {
        size_t pos = file_view.find(signature);
        while (pos != std::string_view::npos) {
            std::cout << "[CRÍTICO ENCONTRADO] SLA en riesgo. Firma: '" << signature 
                      << "' en el byte de offset: " << pos << "\n";
            incidents_found++;
            pos = file_view.find(signature, pos + signature.length());
        }
    }

    std::cout << "=== ANÁLISIS FORENSE COMPLETADO ===\n";
    std::cout << "Incidentes críticos detectados: " << incidents_found << "\n";

    // 5. Liberar recursos y desmontar punteros
    munmap(data, length);
    close(fd);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Uso: " << argv[0] << " <ruta_al_archivo_masivo.log>\n";
        return 1;
    }

    std::cout << "--- SHIP NOC High-Speed Telemetry Parser ---\n";
    scan_memory_mapped_file(argv[1]);

    return 0;
}
