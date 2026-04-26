#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
SHIP NOC - Automated Triage Agent
Detecta fallos, ejecuta diagnósticos de red de Nivel 1 y genera tickets ITIL.
"""

import subprocess
import json
import logging
import datetime
import socket
import psutil # Requiere: pip install psutil

# Configuración de Logging para análisis forense (estándar NOC)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s',
    handlers=[logging.FileHandler("/var/log/noc_triage.log"), logging.StreamHandler()]
)

class NocAutomatedTriage:
    def __init__(self, target_host="8.8.8.8", threshold_cpu=90.0):
        self.target_host = target_host
        self.threshold_cpu = threshold_cpu
        self.hostname = socket.gethostname()

    def check_system_health(self):
        """Monitorea recursos críticos. Retorna True si hay anomalías."""
        cpu_usage = psutil.cpu_percent(interval=2)
        ram_usage = psutil.virtual_memory().percent
        
        if cpu_usage > self.threshold_cpu:
            logging.error(f"SLA RISK: CPU al {cpu_usage}% (Umbral: {self.threshold_cpu}%)")
            return True
        if ram_usage > 95.0:
            logging.error(f"SLA RISK: RAM crítica al {ram_usage}%")
            return True
        
        logging.info("Estado del sistema: OK. Dentro de parámetros SLA.")
        return False

    def execute_network_diagnostics(self):
        """Ejecuta los diagnósticos L1 requeridos por el NOC (Ping, Traceroute, NSLookup)."""
        logging.info("Iniciando diagnósticos automatizados de red L1...")
        diagnostics = {}

        try:
            # Prueba de Ping (Conectividad básica)
            ping_out = subprocess.check_output(
                ["ping", "-c", "4", self.target_host], universal_newlines=True
            )
            diagnostics['ping'] = ping_out.split('\n')[-3:] # Guarda solo el resumen
            
            # Prueba de NSLookup (Resolución DNS)
            dns_out = subprocess.check_output(
                ["nslookup", self.target_host], universal_newlines=True
            )
            diagnostics['dns_resolution'] = "OK" if "name" in dns_out.lower() else "WARNING"

        except subprocess.CalledProcessError as e:
            logging.error(f"Fallo en ejecución de diagnóstico de red: {e}")
            diagnostics['network_error'] = str(e)

        return diagnostics

    def generate_itil_payload(self, diagnostics_data):
        """Genera el JSON estandarizado para herramientas como ServiceNow o Jira."""
        ticket_payload = {
            "incident": {
                "timestamp": datetime.datetime.utcnow().isoformat(),
                "node": self.hostname,
                "priority": "P2 - High", # Riesgo de SLA
                "category": "Infrastructure/Compute",
                "short_description": "Auto-Triage: Anomalía de recursos detectada",
                "diagnostics_l1_attached": diagnostics_data,
                "status": "Escalated to L2"
            }
        }
        
        # Guarda el payload para ingesta vía API
        with open("/tmp/incident_payload.json", "w") as json_file:
            json.dump(ticket_payload, json_file, indent=4)
        
        logging.info("ITIL Payload generado correctamente en /tmp/incident_payload.json")
        return ticket_payload

    def run_cycle(self):
        """Método principal de ejecución."""
        logging.info("=== Iniciando ciclo de monitoreo NOC ===")
        anomaly_detected = self.check_system_health()
        
        if anomaly_detected:
            logging.warning("Iniciando protocolo de mitigación L1...")
            net_data = self.execute_network_diagnostics()
            self.generate_itil_payload(net_data)
            # Aquí se podría disparar un script de Bash de mitigación usando subprocess
        else:
            logging.info("Ciclo finalizado sin incidentes.")

if __name__ == "__main__":
    agent = NocAutomatedTriage(target_host="google.com")
    agent.run_cycle()
