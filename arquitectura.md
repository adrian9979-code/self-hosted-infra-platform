# Arquitectura del sistema

## Visión general
Esta plataforma corre dentro de una máquina virtual usando KVM.

El sistema base es Arch Linux instalado manualmente, con servicios desplegados en contenedores Docker.

## Capas principales
- Máquina host
- Máquina virtual (KVM)
- Arch Linux
- Docker / Docker Compose
- Aplicación (blog / sistema)

## Objetivos de diseño
- Portabilidad
- Aislamiento
- Seguridad
- Control total del sistema
- Posibilidad de migración a hardware físico

## Notas
El sistema se mantiene minimalista para poder escalar sin necesidad de reconstruir todo desde cero.
