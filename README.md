# Pipeline-T09-be

Backend Spring Boot para el sistema de gestión agrícola **Agro DB**.

## Tecnologías

- Java 25
- Spring Boot 3.5.14
- Spring Data JPA + Hibernate
- SQL Server 2022
- Tomcat 10.1.55
- Swagger / OpenAPI 3
- Docker + Docker Compose

## Requisitos

- Docker Desktop instalado
- Red Docker `my-network` creada

## Levantar el proyecto

```bash
# 1. Crear la red (solo la primera vez)
docker network create my-network

# 2. Levantar base de datos
docker compose -f docker-compose-massiel/docker-compose-db.yml up -d

# 3. Levantar backend
docker compose -f docker-compose-massiel/docker-compose-be.yml up -d
```

## Acceso

| Recurso     | URL                                      |
|-------------|------------------------------------------|
| API         | http://localhost:8085                    |
| Swagger UI  | http://localhost:8085/swagger-ui.html    |
| API Docs    | http://localhost:8085/api-docs           |
| SSMS / DB   | localhost,1435 · usuario: sa             |

## Seguridad

El pipeline de CI incluye escaneo de vulnerabilidades con **Trivy** (`.github/workflows/trivy-security-ci.yml`).

- Se ejecuta en cada push y PR a `main` / `develop`
- Escanea niveles: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL
- Objetivo: 0 vulnerabilidades
