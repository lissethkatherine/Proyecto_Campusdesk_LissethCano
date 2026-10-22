# CAMPUSDESK — Plataforma de Gestión de Incidencias Técnicas

**CAMPUSDESK** es un sistema integral de mesa de ayuda y gestión del ciclo de vida de incidencias técnicas en entornos académicos y corporativos. Diseñado bajo una arquitectura desacoplada y moderna, implementa control de acceso basado en roles (RBAC), máquina de estados finita estricta, trazabilidad inmutable de auditoría y persistencia de sesiones en caché distribuida.

---

## 1. Autora

- **Alisson** — desarrollo individual (backend, base de datos, frontend, pruebas y documentación).

---

## 2. Arquitectura y Tecnologías

El sistema se compone de dos capas principales completamente contenerizadas:

- **Backend REST API**:
  - **Lenguaje**: Java 21 (Eclipse Temurin 21 LTS).
  - **Framework**: Spring Boot 4.1.1.
  - **Seguridad**: Spring Security con autenticación basada en tokens JWT (HMAC-SHA256) y validación de sesiones en Redis.
  - **Persistencia Relacional**: PostgreSQL 16 Alpine con Spring Data JPA y Hibernate 7.
  - **Caché y Sesiones**: Redis 7 Alpine para validación de tokens activos, metadata de sesión y revocación en logout.
  - **Documentación API**: OpenAPI 3.0 / Swagger UI (SpringDoc).
  - **Herramienta de Construcción**: Gradle 8.14.3 con Gradle Wrapper.

- **Frontend Web**:
  - **Estructura y Lógica**: HTML5 semántico y JavaScript estándar (Vanilla JS ES6+).
  - **Estilos**: CSS3 con diseño responsivo, CSS variables para diseño coherente y transiciones fluidas.
  - **Servidor Web**: Nginx 1.27 Alpine en contenedor Docker dedicado.

---

## 3. Puertos Oficiales del Proyecto

| Servicio | Contenedor | Puerto Host | Puerto Interno | Protocolo / URL |
| :--- | :--- | :--- | :--- | :--- |
| **Frontend Web** | `campusdesk-frontend` | **5506** | 80 | `http://localhost:5506` |
| **Backend REST API** | `campusdesk-backend` | **8056** | 8056 | `http://localhost:8056` |
| **Swagger UI** | `campusdesk-backend` | **8056** | 8056 | `http://localhost:8056/swagger-ui/index.html` |
| **PostgreSQL 16** | `campusdesk-db` | **5436** | 5432 | `localhost:5436` |
| **Redis 7** | `campusdesk-redis` | **6385** | 6379 | `localhost:6385` |

---

## 4. Estructura del Repositorio

```text
Proyecto_CAMPUSDESK/
├── .env.example                                Plantilla de variables de entorno seguras
├── docker-compose.yml                          Orquestación de servicios (BD, Redis, Backend, Frontend)
├── verify.ps1                                  Script de certificación de pruebas (Windows PowerShell)
├── verify.sh                                   Script de certificación de pruebas (Linux / macOS / Bash)
├── init-db/
│   └── init.sql                                Semilla inicial de base de datos con cuentas y roles
├── docs/
│   └── evidencias/
│       └── README.md                           Catálogo de evidencias y lista de capturas
├── Frontend/
│   ├── index.html                              Página de inicio
│   ├── login.html                              Formulario de inicio de sesión
│   ├── registro.html                           Formulario de registro con política de contraseñas
│   ├── dashboard.html                          Dashboard interactivo, métricas, tickets y administración
│   ├── css/
│   │   ├── styles.css                          Tokens de diseño, componentes y diseño responsivo
│   │   └── auth.css                            Estilos de login y registro
│   ├── js/
│   │   ├── app.js                              Lógica de cliente REST, modales, RBAC y delegación de eventos
│   │   └── auth-guard.js                       Protección de páginas privadas y cierre de sesión
│   ├── assets/img/
│   │   └── vista-previa.png                    Imagen de vista previa
│   ├── Dockerfile                              Empaquetado Nginx Alpine del cliente web
│   └── nginx.conf                              Configuración Nginx
└── spring-security-user-role-management/
    ├── build.gradle                            Configuración Gradle y dependencias Spring Boot 4
    ├── Dockerfile                              Multi-stage build (JDK 21 builder -> JRE 21 runtime)
    └── src/
        ├── main/
        │   ├── java/campusdesk/
        │   │   ├── config/                     CORS, Redis, OpenAPI
        │   │   ├── controller/                 Endpoints REST (Auth, Tickets, Comments, Dashboard, Users)
        │   │   ├── dto/                        DTOs de petición y respuesta validados
        │   │   ├── entity/                     Entidades JPA (User, Ticket, TicketHistory, TicketComment)
        │   │   ├── exception/                  Manejo global de excepciones (ApiExceptionHandler)
        │   │   ├── repository/                 Repositorios Spring Data JPA
        │   │   ├── security/                   Filtro JWT, JwtTokenProvider, SecurityConfig
        │   │   └── service/                    Interfaces de la lógica de negocio
        │   │       └── impl/                   Implementaciones: RBAC y máquina de estados
        │   └── resources/
        │       ├── application.properties      Configuración base
        │       └── application-dev.properties  Perfil de desarrollo
        └── test/                               Suite de pruebas unitarias y de integración
```

---

## 5. Variables de Entorno y Secretos

El archivo `.env` local no se encuentra versionado (`.gitignore`). Para configurar un nuevo entorno, copie `.env.example` a `.env`:

```bash
# Ubuntu / Linux / macOS
cp .env.example .env
```
```powershell
# Windows (PowerShell)
Copy-Item .env.example .env
```

Para generar un `JWT_SECRET` aleatorio de 64 caracteres:

```bash
# Ubuntu / Linux / macOS
openssl rand -base64 48
```
```powershell
# Windows (PowerShell)
$b = New-Object byte[] 48; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)
```

### Variables Requeridas:
- `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`: base de datos PostgreSQL (la contraseña es **obligatoria**: `docker compose` no inicia si no se define).
- `REDIS_PASSWORD`: contraseña de Redis (**obligatoria**).
- `JWT_SECRET`: secreto HMAC-SHA256 para firmar los tokens (**obligatorio**, mínimo 32 caracteres; la aplicación no inicia si no cumple).
- `TECHNICIAN_DEFAULT_PASSWORD`: contraseña inicial **común** para los técnicos que cree el administrador (8+ caracteres, con mayúscula, minúscula y número). Cada técnico puede cambiarla luego. Si no se define, se usa el valor de `.env.example`; **cámbielo en su `.env`**.
- `CORS_ALLOWED_ORIGINS`: lista explícita de orígenes permitidos (por defecto: `http://localhost:5506,http://localhost:5500`).

---

## 6. Roles, Permisos y Máquina de Estados

### Matriz de Roles (RBAC)

| Operación | Rol `USER` | Rol `TECHNICIAN` | Rol `ADMIN` |
| :--- | :---: | :---: | :---: |
| Registrarse e iniciar sesión | Sí | Sí | Sí |
| Crear nueva incidencia (inicia en `ABIERTA`) | Sí | No | No |
| Editar incidencia (solo solicitante, `ABIERTA`, sin técnico) | **Sí** | No | No |
| Consultar incidencias | Solo propias | Solo asignadas | Todas |
| Asignar / reasignar técnico (solo en `ABIERTA` o `ASIGNADA`) | No | No | **Sí** |
| Pasar a `EN_PROCESO` | No | **Solo técnico asignado** | No |
| Pasar a `RESUELTA` | No | **Solo técnico asignado** | No |
| Pasar a `CERRADA` | **Solo solicitante** | No | No |
| Cancelar la incidencia (`CANCELADA`, desde `ABIERTA`, `ASIGNADA` o `EN_PROCESO`) | **Solo solicitante** | No | No |
| Comentar en incidencias | Propias (no cerradas) | Asignadas (no cerradas) | Todas (no cerradas) |
| Consultar lista de técnicos (`/api/users/technicians`) | No (HTTP 403) | No (HTTP 403) | **Sí** (HTTP 200) |
| Consultar lista de usuarios (`/api/users`) | No (HTTP 403) | No (HTTP 403) | **Sí** (HTTP 200) |
| Crear técnicos (`POST /api/users/technicians`, contraseña inicial común) | No (HTTP 403) | No (HTTP 403) | **Sí** (HTTP 201) |
| Cambiar la propia contraseña (`PATCH /api/users/me/password`) | **Sí** | **Sí** | **Sí** |

### Transiciones de Estado y Respuestas HTTP
- **Asignación en estado incompatible** (`EN_PROCESO`, `RESUELTA`, `CERRADA`): **HTTP 409 Conflict**.
- **Transición no autorizada** (ej. admin o usuario intentando pasar a `EN_PROCESO` o `RESUELTA`): **HTTP 403 Forbidden**.
- **Cierre por usuario no solicitante**: **HTTP 403 Forbidden**.
- **Salto arbitrario de estados** (ej. de `ABIERTA` a `RESUELTA` sin pasar por `EN_PROCESO`): **HTTP 409 Conflict**.
- **Comentarios o cambios en ticket `CERRADA` o `CANCELADA`**: **HTTP 409 Conflict** (inmutabilidad).
- **Cancelación por alguien que no es el solicitante**: **HTTP 403 Forbidden**. **Cancelar un ticket `RESUELTA`** (se cierra, no se cancela): **HTTP 409 Conflict**.
- **Retrocesos o destinos no permitidos** (ej. volver a `ABIERTA` o `ASIGNADA` mediante `/status`): **HTTP 409 Conflict**.
- **Contraseña débil en registro o al cambiarla**: **HTTP 400 Bad Request**.
- **Contraseña actual incorrecta al cambiarla**: **HTTP 400 Bad Request**. Al cambiarla con éxito se revocan todas las sesiones del usuario.
- **Petición sin token**: **HTTP 401 Unauthorized** (JSON uniforme).

---

### Estado `CANCELADA` (cancelar una incidencia)
Si el solicitante resuelve el problema por su cuenta (por ejemplo, era un cable mal conectado), puede **cancelar** su incidencia mientras esté `ABIERTA`, `ASIGNADA` o `EN_PROCESO` (botón «Cancelar Incidencia» en el detalle, con motivo opcional; o `PATCH /api/tickets/{id}/status` con `{"status":"CANCELADA"}`). El técnico deja de tener trabajo pendiente en ese ticket. `CANCELADA` es un estado final e inmutable, igual que `CERRADA`: el historial se conserva y ya no admite cambios ni comentarios. Es una extensión del flujo original, agregada por indicación del profesor.

### Gestión de técnicos y contraseñas
1. El **administrador** entra a **Administración → ➕ Crear Técnico** e ingresa nombre y correo. El técnico queda con rol `TECHNICIAN` y la contraseña inicial común (`TECHNICIAN_DEFAULT_PASSWORD`).
2. El **técnico** inicia sesión con esa contraseña y la cambia desde **🔑 Contraseña** (pide la actual y la nueva con la política: 8+ caracteres, mayúscula, minúscula y número). Al guardar se cierra su sesión y debe volver a entrar.

## 7. Cuentas de Prueba Pre-sembradas

Cuentas de **demostración** inicializadas en `init.sql` (solo guardan el hash BCrypt). Los secretos reales (JWT, PostgreSQL, Redis) viven únicamente en el archivo `.env`, que no se versiona:

| Rol | Correo Electrónico | Contraseña |
| :--- | :--- | :--- |
| **ADMIN** | `superadmin@campusdesk.com` | `Adm5209Camp` |
| **TECHNICIAN** | `tecnico@campusdesk.com` | `Tec9270Soporte` |
| **USER** | `carlos@campusdesk.com` | `Usr2703Camp` |

---

## 8. Persistencia y Sesiones con Redis 7

Redis se utiliza como almacén en memoria de alto rendimiento para:
1. **Validación de Sesiones**: Cada token JWT generado en login se registra en Redis (clave `campusdesk:session:{hash SHA-256 del token}`) con un TTL de 8 horas (`SESSION_TTL_SECONDS`). Si la clave no existe, el token se rechaza (401) aunque su firma y vencimiento sean válidos.
2. **Revocación Inmediata (Logout)**: Al invocar `POST /api/auth/logout`, la clave de sesión se elimina de Redis, invalidando el JWT inmediatamente aunque no haya expirado cronológicamente.
3. **Roles en caché**: el filtro JWT toma el rol y los permisos desde la sesión guardada en Redis, sin consultar PostgreSQL en cada petición.
4. **Cambio de contraseña**: al cambiarla se borran todas las sesiones del usuario (`invalidateAllSessionsByUser`).
5. **Resiliencia**: Si Redis experimenta una caída momentánea, las operaciones de sesión capturan la excepción controladamente (`RedisConnectionFailureException`) reportando el estado sin corromper la persistencia de datos relacionales en PostgreSQL.

### ¿Por qué Redis si el token se guarda en `sessionStorage`?
Son dos piezas distintas. El navegador guarda el **token** (la «llave»); Redis guarda en el servidor la **lista de sesiones válidas** (quién puede usar cada llave). Un JWT por sí solo no se puede cancelar: valdría hasta vencer aunque el usuario cierre sesión o cambie su contraseña. Con Redis, el servidor puede revocarlo. Demostración:
```bash
TOKEN=$(curl -s -X POST http://localhost:8056/api/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"carlos@campusdesk.com","password":"<contraseña>"}' | grep -o '"token":"[^"]*' | cut -d'"' -f4)
curl -i http://localhost:8056/api/tickets -H "Authorization: Bearer $TOKEN"      # 200
docker exec campusdesk-redis redis-cli -a "$REDIS_PASSWORD" --no-auth-warning KEYS 'campusdesk:session:*'   # la sesión existe
curl -X POST http://localhost:8056/api/auth/logout -H "Authorization: Bearer $TOKEN"
curl -i http://localhost:8056/api/tickets -H "Authorization: Bearer $TOKEN"      # 401: el token sigue sin vencer, pero Redis ya no lo acepta
```
Limitación honesta: si Redis cae, las rutas protegidas responden 503 (no se acepta un token sin comprobar su sesión).

---

## 9. Instrucciones de Ejecución (Windows y Ubuntu)

Todo corre en **su propio equipo**: no depende de Railway, Neon ni de ningún servicio en la nube. Funciona igual en Windows 10/11 (PowerShell) y en Ubuntu 22.04/24.04 (bash).

### Requisitos

| Programa | Windows | Ubuntu |
|---|---|---|
| Docker con Compose v2 | Docker Desktop | `sudo apt install docker.io docker-compose-v2` y `sudo usermod -aG docker $USER` (cierre sesión y vuelva a entrar) |
| JDK 21 (solo opción B) | Temurin 21 | `sudo apt install openjdk-21-jdk` |
| Python 3 (solo opción B, frontend) | `py -3` | `python3` (ya viene instalado) |

Los puertos 8056, 5506, 5436 y 6385 deben estar libres (se pueden cambiar en `.env`).

### Opción A: Todo con Docker Compose (Recomendado)

1. Crear el `.env` (ver sección 5) y completar las contraseñas y el `JWT_SECRET`.
2. Iniciar y construir todos los contenedores (igual en ambos sistemas):
   ```bash
   docker compose up -d --build
   ```
   También sirven los scripts: `bash deploy.sh` (Ubuntu) o `.\deploy.ps1` (Windows).
3. Comprobar el estado: `docker compose ps`
4. Acceder:
   - Frontend: `http://localhost:5506`
   - Backend: `http://localhost:8056`
   - Swagger: `http://localhost:8056/swagger-ui/index.html`
5. Detener: `docker compose down` (conserva los datos). Para borrar también los datos y volver a cargar `init.sql`: `docker compose down -v`.

### Opción B: Desarrollo (Spring Boot fuera de Docker, p. ej. con IntelliJ)

1. **Backend** (levanta PostgreSQL y Redis en Docker y arranca Spring Boot leyendo el `.env`):
   ```bash
   # Ubuntu / Linux / macOS
   bash local-backend.sh
   ```
   ```powershell
   # Windows (PowerShell)
   powershell -ExecutionPolicy Bypass -File .\local-backend.ps1
   ```
2. **Frontend** (servidor estático en el puerto 5500; el 5506 queda reservado para Nginx de Docker):
   ```bash
   # Ubuntu / Linux / macOS
   python3 -m http.server 5500 --directory Frontend
   ```
   ```powershell
   # Windows (PowerShell)
   py -3 -m http.server 5500 --directory Frontend
   ```
   Abrir `http://localhost:5500/login.html`.

**Con IntelliJ:** IntelliJ no lee el `.env`. Levante primero la infraestructura (`docker compose up -d --wait campusdesk-db campusdesk-redis`) y en *Run → Edit Configurations → CampusdeskApplication → Environment variables* agregue (separadas por `;`):

```
DB_URL=jdbc:postgresql://localhost:5436/sistema_gestion_usuarios;DB_USERNAME=admin;DB_PASSWORD=<su clave>;REDIS_HOST=localhost;REDIS_PORT=6385;REDIS_PASSWORD=<su clave>;JWT_SECRET=<mínimo 32 caracteres>
```

### Problemas comunes

- **`Unable to start embedded Tomcat` / la app se cae al iniciar:** casi siempre faltan `DB_PASSWORD`, `JWT_SECRET` o `REDIS_PASSWORD`, o PostgreSQL/Redis no están encendidos. Mire el **último** `Caused by:`.
- **Ubuntu: `permission denied` con Docker:** agregue su usuario al grupo `docker` (ver Requisitos) o use `sudo`.
- **Ubuntu: `./gradlew: Permission denied`:** use `sh ./gradlew ...` o `chmod +x gradlew`.
- **`bad interpreter` / `\r` en un `.sh`:** el archivo quedó con saltos de línea de Windows. Corrija con `sed -i 's/\r$//' archivo.sh` (el `.gitattributes` del proyecto lo evita).

---

## 10. Pruebas y Certificación

### Suite de Tests Automatizados (Backend)
Desde la carpeta `spring-security-user-role-management`:
```powershell
.\gradlew.bat clean test
```
*Ejecute el comando y anexe la captura del resultado en `docs/evidencias/`.*

### Script de Certificación Integral Oficial
Desde la raíz del proyecto:
- En Windows (PowerShell):
  ```powershell
  .\verify.ps1
  ```
- En Linux / macOS / Bash:
  ```bash
  ./verify.sh
  ```
*Ejecute el script con el sistema levantado y anexe la captura del resultado en `docs/evidencias/`.*

### Catálogo de Evidencias
Consulte la documentación detallada de evidencias y la guía de capturas visuales en:
- [docs/evidencias/README.md](docs/evidencias/README.md)
