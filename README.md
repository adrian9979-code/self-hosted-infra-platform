# Plataforma de Infraestructura Autoalojada

Entorno personal de infraestructura construido sobre GNU/Linux, orientado a despliegue de servicios, administración del sistema y control total del entorno.

Este repositorio documenta la construcción, operación y evolución de una plataforma autoalojada basada en virtualización y contenedores, con énfasis en control del sistema, aislamiento y portabilidad.

## Stack técnico

- GNU/Linux (Arch Linux)
- SSH para acceso y administración remota
- Docker y Docker Compose para despliegue de servicios
- Nginx como proxy web
- Bash para automatización
- Sistemas de archivos Linux (EXT4, BTRFS, XFS)
- Estrategias de backup (incluyendo snapshots en BTRFS)
- nftables para control de red y filtrado de tráfico
- GRUB como gestor de arranque
- Compilación y ajuste de kernel

## Enfoque

El sistema parte de una instalación manual de Arch Linux, gestionando desde el arranque con GRUB hasta los servicios en ejecución.

Se trabaja directamente con:

- configuración del sistema base
- acceso remoto mediante SSH
- despliegue de servicios en contenedores
- control de red mediante nftables
- administración de almacenamiento y respaldos
- automatización de tareas operativas

## Componentes del entorno

- Sistema base minimalista
- Servicios desplegados en contenedores Docker
- Orquestación con Docker Compose
- Proxy Nginx para exposición de servicios
- Base de datos persistente
- Scripts en Bash para operación y mantenimiento
- Gestión de almacenamiento con distintos sistemas de archivos
- Reglas de red y filtrado mediante nftables

## Operación

Despliegue de servicios:

```bash
docker compose up -d
