Self-Hosted Infrastructure Platform (SHIP) 🛡️🚀

Infraestructura de servidor de alto rendimiento basada en Arch Linux, diseñada bajo principios de Hardening, aislamiento de servicios y administración manual de bajo nivel. Este entorno no utiliza scripts de automatización genéricos; cada componente ha sido configurado desde el pacstrap para garantizar el control total del hardware y los datos.
🏗️ Filosofía de Ingeniería

El objetivo central es la reducción de la superficie de ataque y la maximización de la eficiencia mediante el uso de tecnologías de infraestructura como código (IaC) y filtrado de paquetes a nivel de kernel.
🛠️ Stack Tecnológico

    Host OS: Arch Linux (Instalación minimalista, gestión manual de servicios).

    Networking: nftables (Stateful Firewall con políticas restrictivas).

    Orquestación: Docker + Docker Compose (Arquitectura de microservicios).

    Storage: Gestión dinámica con BTRFS (Snapshots/Subvolúmenes) y XFS/EXT4 para cargas específicas.

    Seguridad: OpenSSH Hardening, aislamiento de redes virtuales y filtrado DNS.

    Monitoreo: Stack de observabilidad con Uptime Kuma.

🛡️ Hardening y Seguridad de Red
1. Filtrado de Paquetes (nftables.conf)

Se implementa un firewall stateful con política DROP por defecto en todas las cadenas.

    Filtrado de Estado: Solo se permiten conexiones established y related.

    Protección Anti-Brute Force: Rate limit estricto en el puerto 22 (10 intentos por minuto).

    Validación de Tráfico: Descarte automático de paquetes con estado invalid.

2. Seguridad de Acceso (OpenSSH)

Configuración de sshd_config bajo estándar de máxima seguridad:

    Zero Password Auth: Autenticación exclusiva mediante llaves criptográficas (Ed25519).

    Root Isolation: Acceso directo a root denegado (PermitRootLogin no).

    Network Restriction: Deshabilitado el reenvío de túneles y X11 para mitigar movimientos laterales.

    Keep-Alive: Auditoría de inactividad automática cada 300 segundos.

📦 Orquestación de Servicios (Docker IaC)

La plataforma utiliza redes aisladas para segmentar el tráfico de backend y frontend:

    Red internal: Comunicación privada entre la app y la base de datos (PostgreSQL 16), sin exposición de puertos al host.

    Red public: Exposición controlada de servicios mediante proxy inverso.

    Seguridad DNS: Integración de Pi-hole para el filtrado de telemetría y dominios maliciosos a nivel de red.

YAML

# Estructura lógica del despliegue
services:
  app: # Core Business Logic
  db:  # Persistent Storage (PostgreSQL)
  dns: # Pi-hole Security Layer
  mon: # Uptime Kuma Observability

💾 Gestión de Almacenamiento y Resiliencia

El sistema está diseñado para la persistencia de datos y la recuperación ante desastres mediante:

    BTRFS Copy-on-Write (CoW): Creación de snapshots atómicos antes de cambios críticos en el sistema base.

    Persistencia de Volúmenes: Separación física de datos de aplicación y metadatos del contenedor.

    Systemd Automation: Uso de unidades de servicio personalizadas para la gestión del ciclo de vida de scripts de mantenimiento y automatización de backups.

📋 Operación de la Plataforma
Despliegue inicial de servicios:
Bash

docker compose up -d --build

Auditoría de reglas de red:
Bash

sudo nft list ruleset

Verificación de logs del sistema:
Bash

journalctl -u docker.service -f

⚖️ Licencia

Este proyecto se distribuye bajo la Licencia MIT. Ver el archivo LICENSE para más detalles.
