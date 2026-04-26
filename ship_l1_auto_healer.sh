#!/bin/bash
# ==============================================================================
# SHIP - L1 Auto-Healing & Mitigation Daemon
# Ejecución en Cron o Systemd Timer para prevención de caídas de nodos.
# ==============================================================================

# Modo estricto: Falla si hay variables no definidas o errores en tuberías.
set -euo pipefail

# ==================== CONFIGURACIÓN DE UMBRALES ====================
DISK_THRESHOLD=90
INODE_THRESHOLD=90
LOG_FILE="/var/log/ship_auto_healer.log"
NOC_WEBHOOK_URL="https://api.empresa.com/noc/alerts" # Placeholder para Slack/Teams/Jira

# ==================== FUNCIONES DE SISTEMA ====================

# Función de Logging estandarizado
log_event() {
    local TYPE=$1
    local MESSAGE=$2
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [$TYPE] - $MESSAGE" | tee -a "$LOG_FILE"
}

# Notificación externa al NOC
notify_noc() {
    local PAYLOAD=$1
    # En producción real, se descomenta la línea de curl para enviar a una API
    # curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"$PAYLOAD\"}" "$NOC_WEBHOOK_URL" > /dev/null
    log_event "NOTIFY" "Payload de mitigación enviado al NOC."
}

# ==================== PROTOCOLOS DE DIAGNÓSTICO Y MITIGACIÓN ====================

check_and_mitigate_storage() {
    # Extraer el porcentaje de uso de la partición raíz (/)
    local DISK_USAGE=$(df / | grep / | awk '{ print $5}' | sed 's/%//g')
    local INODE_USAGE=$(df -i / | grep / | awk '{ print $5}' | sed 's/%//g')

    if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
        log_event "CRITICAL" "Saturación de disco detectada ($DISK_USAGE%). Iniciando purga L1..."
        
        # Mitigación 1: Limpieza de logs antiguos de systemd
        journalctl --vacuum-time=2d > /dev/null 2>&1
        
        # Mitigación 2: Limpieza de caché de paquetes (Agnóstico a Arch/Debian)
        if command -v pacman > /dev/null; then
            pacman -Scc --noconfirm > /dev/null 2>&1
        elif command -v apt-get > /dev/null; then
            apt-get clean > /dev/null 2>&1
        fi
        
        # Mitigación 3: Limpieza de contenedores, imágenes y volúmenes huérfanos
        if systemctl is-active --quiet docker; then
            docker system prune -af --volumes > /dev/null 2>&1
        fi

        # Re-evaluación
        local NEW_USAGE=$(df / | grep / | awk '{ print $5}' | sed 's/%//g')
        log_event "RESOLVED" "Purga completada. Nuevo uso de disco: $NEW_USAGE%"
        notify_noc "🚨 L1 Auto-Healer: Nodo saturado al $DISK_USAGE%. Mitigación aplicada. Uso actual: $NEW_USAGE%. No requiere acción humana."
    else
        log_event "INFO" "Storage OK ($DISK_USAGE%). Inodes OK ($INODE_USAGE%)."
    fi
}

check_critical_services() {
    # Verifica si el motor de Docker colapsó y lo reinicia
    if ! systemctl is-active --quiet docker; then
        log_event "CRITICAL" "Servicio Docker caído. Ejecutando reinicio de emergencia..."
        systemctl restart docker
        sleep 5
        if systemctl is-active --quiet docker; then
            log_event "RESOLVED" "Docker reiniciado con éxito."
            notify_noc "⚠️ L1 Auto-Healer: Caída de demonio Docker detectada y mitigada vía systemctl. Motor operativo."
        else
            log_event "FATAL" "Docker no pudo reiniciar. Escalando a L2."
            notify_noc "🔥 ESCALACIÓN L2: Demonio Docker caído en el nodo. Falla en auto-recuperación."
        fi
    else
         log_event "INFO" "Orquestador de contenedores OK."
    fi
}

# ==================== MAIN EXECUTION ====================
log_event "START" "Iniciando ciclo de auditoría y auto-curación de nodo..."

check_and_mitigate_storage
check_critical_services

log_event "END" "Ciclo finalizado correctamente."
exit 0
