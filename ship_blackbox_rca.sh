#!/bin/bash
# =====================================================================
# SHIP NOC - Black Box RCA (Root Cause Analysis) Dumper
# Captura forense automatizada en incidentes críticos.
# =====================================================================

# Modo Estricto: Falla inmediatamente si hay errores o variables no definidas.
set -euo pipefail

# ==================== CONFIGURACIÓN ====================
THRESHOLD_CPU=90
DUMP_DIR="/var/log/ship_rca_dumps"
COOLDOWN_MINUTES=15 # Evita llenar el disco si el CPU sigue al 100%
LOCK_FILE="/tmp/ship_rca.lock"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DUMP_PATH="${DUMP_DIR}/rca_dump_${TIMESTAMP}"

# ==================== INICIALIZACIÓN ====================
mkdir -p "$DUMP_DIR"

log_msg() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] $1"
}

# ==================== VERIFICACIÓN DE COOLDOWN ====================
# Si ya se hizo un dump recientemente, abortamos para no saturar I/O
if [ -f "$LOCK_FILE" ]; then
    LAST_RUN=$(stat -c %Y "$LOCK_FILE")
    NOW=$(date +%s)
    DIFF=$(( (NOW - LAST_RUN) / 60 ))
    if [ "$DIFF" -lt "$COOLDOWN_MINUTES" ]; then
        exit 0 # Aún en periodo de gracia, salida silenciosa.
    fi
fi

# ==================== DETECCIÓN DE ANOMALÍAS ====================
# Extrae el uso de CPU usando herramientas nativas de Linux (vmstat)
CPU_IDLE=$(vmstat 1 2 | tail -1 | awk '{print $15}')
CPU_USAGE=$((100 - CPU_IDLE))

if [ "$CPU_USAGE" -ge "$THRESHOLD_CPU" ]; then
    log_msg "CRÍTICO: CPU al ${CPU_USAGE}%. Iniciando volcado forense RCA..."
    
    # Actualizamos el Lock File
    touch "$LOCK_FILE"
    mkdir -p "$DUMP_PATH"

    # 1. Radiografía de Procesos (Los 15 que más consumen)
    ps aux --sort=-%cpu | head -n 16 > "${DUMP_PATH}/top_cpu_processes.txt"
    ps aux --sort=-%mem | head -n 16 > "${DUMP_PATH}/top_mem_processes.txt"

    # 2. Estado de la Red (Conexiones activas y saturación de puertos)
    ss -tunap > "${DUMP_PATH}/network_connections.txt"
    netstat -s > "${DUMP_PATH}/network_stats.txt"

    # 3. Logs del Kernel (Buscando OOM Killer, fallos de disco, etc.)
    dmesg | tail -n 200 > "${DUMP_PATH}/kernel_dmesg.txt"

    # 4. Logs del Sistema (Últimos 10 minutos de journalctl)
    journalctl --since "10 minutes ago" --no-pager > "${DUMP_PATH}/system_journal.txt"

    # 5. Estado del disco e Inodos
    df -h > "${DUMP_PATH}/disk_usage.txt"
    df -i > "${DUMP_PATH}/inode_usage.txt"

    # ==================== COMPRESIÓN Y LIMPIEZA ====================
    log_msg "Volcado completo. Comprimiendo evidencia..."
    tar -czf "${DUMP_PATH}.tar.gz" -C "$DUMP_DIR" "rca_dump_${TIMESTAMP}"
    rm -rf "$DUMP_PATH" # Borra la carpeta temporal, deja solo el .tar.gz

    # Opcional: Eliminar dumps más antiguos de 7 días para rotación
    find "$DUMP_DIR" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;

    log_msg "RCA Dump generado exitosamente: ${DUMP_PATH}.tar.gz"
fi
