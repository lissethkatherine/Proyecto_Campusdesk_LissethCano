#!/usr/bin/env bash
# ==============================================================================
# CAMPUSDESK - Backend en modo desarrollo (Ubuntu / Linux / macOS / Git Bash)
# Levanta PostgreSQL y Redis en Docker y arranca Spring Boot FUERA de Docker
# leyendo las variables del archivo .env
# Uso:  bash local-backend.sh
# ==============================================================================
set -euo pipefail
cd "$(dirname "$0")"

if [ ! -f .env ]; then
  echo "ERROR: falta el archivo .env. Ejecute:  cp .env.example .env  y complete los valores."
  exit 1
fi

# Carga .env ignorando el retorno de carro (\r) por si se edito en Windows
set -a
# shellcheck disable=SC1090
source <(sed 's/\r$//' .env)
set +a

# Dentro de Docker el backend usa los nombres de servicio; fuera de Docker usa los puertos publicados en tu equipo
export DB_URL="jdbc:postgresql://localhost:${DB_PORT:-5436}/${POSTGRES_DB:-sistema_gestion_usuarios}"
export DB_USERNAME="${POSTGRES_USER:-admin}"
export DB_PASSWORD="${POSTGRES_PASSWORD:?Defina POSTGRES_PASSWORD en .env}"
export REDIS_HOST="localhost"
export REDIS_PORT="${REDIS_HOST_PORT:-6385}"
export REDIS_PASSWORD="${REDIS_PASSWORD:?Defina REDIS_PASSWORD en .env}"
export JWT_SECRET="${JWT_SECRET:?Defina JWT_SECRET en .env (minimo 32 caracteres)}"
export SERVER_PORT="${BACKEND_PORT:-8056}"

echo "-> Levantando PostgreSQL y Redis (esperando a que esten saludables)..."
docker compose up -d --wait campusdesk-db campusdesk-redis

echo "-> Iniciando Spring Boot en http://localhost:${SERVER_PORT}  (Ctrl+C para detener)"
cd spring-security-user-role-management
sh ./gradlew bootRun
