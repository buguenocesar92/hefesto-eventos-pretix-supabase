# Hefesto Eventos · pretix 2026.8.0 + Supabase
Kit nativo para inscripciones, reservas y entradas de eventos pequeños o medianos. Usa la interfaz de pretix; no es una réplica ni un sistema de pagos propio. Incluye preparación de Supabase, correo de prueba, tareas periódicas y recuperación conjunta de datos.

## Stack y alcance
pretix standalone + PostgreSQL externo en proyecto Supabase dedicado + Redis7.4. La imagen all incluye nginx, web y Celery; además se ejecuta un servicio periodic para runperiodic. El kit fija dos procesos web y dos procesos de tareas; solo debe existir un periodic por instalación. No se añaden workers duplicados fuera del standalone.

Imágenes fijadas por digest. Supabase se usa como PostgreSQL, sin Auth/Storage/REST. Se guardan medios/entradas en un volumen local. No se han activado pagos, remitentes reales, plugins Enterprise, Flow/Webpay ni facturación SII. La creación y publicación de un evento se hace manualmente con autorización del organizador.

Requisitos: Linux, Docker Engine con Compose v2, Python3.11+, dominio HTTPS, SMTP TLS465 y proyecto Supabase nuevo PostgreSQL16/17. Como punto de partida de prueba, reservar 2–4 CPU y 4GB de RAM en el VPS más espacio para medios/copias; medir carga y tiempos antes de vender capacidad. Este es un despliegue small-scale, sin garantía para aperturas con miles de compradores simultáneos.

## Preparar Supabase
1. Ejecutar `python3 scripts/configure.py`: crea .env 0600 y dos secretos independientes; no sobrescribe un archivo existente.
2. Crear proyecto Supabase **nuevo y exclusivo** y desactivar Data API. No usar la base de KraftDo u otro sistema.
3. Ejecutar sql/01-supabase-app.sql como administrador en SQL Editor. Crea rol pretix_app sin privilegios administrativos, permisos de public y privilegios por defecto restringidos. Falla si hay tablas en public; no borra datos.
4. Asignar al rol la clave DB_PASSWORD del .env mediante `\password pretix_app` en una sesión psql administrativa. Así no se pega la contraseña en SQL versionado ni en el historial del comando. No cambiarla después sin coordinar servidor/proveedor.
5. Completar DB_HOST y DB_USER. Preferir conexión directa5432; si el VPS no tiene IPv6, usar pooler **Session**5432 con usuario pretix_app.PROJECTREF. No usar Transaction6543: pretix utiliza locks y cursores y sus migraciones deben operar en una sesión adecuada.
6. Descargar la CA real del proyecto a certs/ca.crt, legible para UID15371. Se fuerza verify-full; no reemplazarlo por require o disable para ocultar un fallo de host/CA.
7. Marcar las dos confirmaciones SUPABASE_* true solo tras completar esos pasos. El preflight comprueba rol, permisos, versión y tablas, no demuestra por sí solo la opción del panel Data API. No se requiere service_role.

## Setup privado con correo capturado

```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml config --quiet
docker compose -f compose.yaml -f compose.bootstrap.yaml up -d
```

Esperar a que preflight, permissions y migrate terminen correctamente. Abrir túnel desde tu equipo:
`ssh -L 8114:127.0.0.1:8114 -L 8030:127.0.0.1:8030 usuario@servidor`

La tienda/panel de prueba se abre en http://localhost:8114 y Mailpit en http://localhost:8030. Solo se publican estos puertos en loopback. La conexión a Supabase sí utiliza red externa; el bootstrap no es un entorno totalmente aislado.

Crear administrador por CLI, con contraseña introducida interactivamente:

```sh
docker compose -f compose.yaml -f compose.bootstrap.yaml run --rm app createsuperuser
```

Entrar al panel nativo, crear organizador y evento ficticio según docs/EVENTO-DEMO.md. Comprobar correo en Mailpit, recuperación de acceso y las tareas periódicas. No hay usuario ni contraseña predeterminados. registration=off impide alta pública de usuarios del panel; los compradores siguen el flujo propio de pedidos del evento.

## Correo y servicio público
Completar PUBLIC_URL con dominio HTTPS raíz sin barra final; MAIL_FROM y SMTP_HOST/USER/PASSWORD para un proveedor TLS implícito465. El dominio/remitente debe estar autorizado por ese proveedor. Probar entrega real de forma privada y marcar SMTP_READY=true. La marca es una confirmación operativa: el guard no envía un correo de prueba ni valida las credenciales del proveedor.

El arranque público comprueba que existe administrador activo del sistema. No crea cuentas automáticamente ni salta migraciones. El secreto Django se toma de .env y debe conservarse junto a los datos recuperados. Los datos de autenticación de los usuarios siguen el modelo nativo de pretix; no se sustituye su hash por contraseñas en texto.

## Coolify
Importar carpeta/repo privado como Docker Compose y seleccionar **compose.yaml**. Mantener ops/ y certs/ para sus montajes. Introducir variables del recurso sin versionar .env; usar `config --quiet` al validar para no imprimir secretos.

Asignar dominio HTTPS únicamente al servicio **app**, puerto **80**. No publicar Redis, dbtools, periodic, migrate ni puertos del host. TLS termina en Coolify; pretix confía en X-Forwarded-Proto del proxy. Revisar HTTPS/cookies/CSRF con el dominio real. El kit no cambia Cloudflare o DNS.

No usar el override bootstrap en público ni exponer Mailpit. Si se cambia de Compose manual a Coolify, los volúmenes pueden tener otros nombres: hacer respaldo/restauración y confirmar el volumen administrado por Coolify; no asumir que encontrará el del proyecto manual.

En una instalación manual previa, el `compose.yaml` ya no declara un `name:` de proyecto. Para conservar los volúmenes `files` y `redis_data` originales hay que fijar `COMPOSE_PROJECT_NAME=hefesto-eventos` en `.env` antes del primer `docker compose up` en Coolify; sin esa variable Docker deriva el nombre del directorio y los datos quedarían vacíos.

En una instalación manual, para retirar el bootstrap detener con ambos archivos y recrear solo con compose.yaml, comprobando que desaparezcan los puertos de prueba. Cambiar YAML no actualiza un contenedor ya creado.

### Despliegue en Coolify (MVP Hefesto)

Variables nuevas (con su valor por defecto en compose.yaml):

- `DB_NAME`: nombre de la base en el Postgres compartido. Por defecto `postgres`. Cuando cada app usa su propia base en un Supabase compartido (formato `mvp_<slug>`), establecer esta variable.
- `DB_SSLMODE`: modo SSL del driver. Por defecto `verify-full`. Si el Postgres compartido está en una red interna sin CA, usar `disable` o `require` según el caso. Con `DB_SSLMODE` distinto de `verify-full`, el directorio `certs/ca.crt` no es obligatorio y los chequeos de `ops/preflight.sh`/`ops/validate.py` lo omiten.
- **Sin chequeo de host:** el kit no verifica que `DB_HOST` pertenezca a `*.supabase.co`. Con `DB_SSLMODE=disable` cualquier host interno sirve; el operador es responsable de que la red esté aislada.
- `SMTP_READY=false`: arranque sin SMTP real. El correo queda desactivado (backend dummy de Django) hasta que el operador confirme entrega y vuelva a poner `SMTP_READY=true`.

Healthcheck del servicio `app`: el compose declara un `healthcheck` que hace `GET http://localhost/healthcheck/` con `python3 -c` (no usa credenciales), con `interval: 30s`, `timeout: 10s`, `retries: 5` y `start_period: 120s`. Coolify lo refleja como estado del contenedor sin intervención del operador.

`scripts/coolify-check.sh` automatiza la validación del contrato (sin secrets ni redes): ejecutar `bash scripts/coolify-check.sh` para validar el contrato (requiere `docker compose` y `jq`).

#### Administrador inicial

`ops/validate.py` aborta el arranque de `app` y `periodic` mientras no exista un usuario staff activo. Hay que crearlo **antes del primer arranque de `app`** usando el servicio `migrate`, que no monta `start.sh` ni exige SMTP. Por ejemplo, sobre el recurso de Coolify o vía CLI:

```sh
docker compose run --rm migrate createsuperuser
```

Alternativamente, abrir la Terminal de Coolify sobre el servicio `migrate` y ejecutar `createsuperuser` ahí. La contraseña se introduce interactivamente y no queda en el historial.

#### Requisitos del rol en Postgres

`ops/preflight.sql:6` exige que el rol conectado se llame exactamente `pretix_app`; cualquier otro nombre rompe el preflight antes de migrar. Ademas, `:17` rechaza roles con `rolinherit`, por lo que el rol **debe crearse `NOINHERIT`**. Si se usa el formato `mvp_<slug>`, ese rol debe ser el dueño de la base (crearla como `pretix_app` o cambiar la propiedad antes del primer arranque). La alternativa es parametrizar `ops/preflight.sql` con `current_user` y `-v db_user`, decisión del operador.

## Datos y tareas
/data contiene medios, tickets generados y otros archivos; UID15371, con lectura necesaria para nginx nativo. No se fuerza no-new-privileges: la imagen oficial usa sudo para iniciar supervisor, por lo que bloquearlo rompería el arranque. Las credenciales del sistema/proveedores se pasan por entorno y no están escritas en pretix.cfg; administradores de Docker pueden leer el entorno.

Redis está en una red interna y no tiene puerto público. Se persiste porque contiene colas/resultados. Las sesiones se conservan en base de datos en esta configuración. periodic ejecuta el comando nativo cada60s después de terminar la ejecución anterior; no añadir otro cron idéntico. No se usan réplicas de lectura para inventario/pedidos.

## Entrega y monetización
Ofrecer instalación, configuración del evento, diseño del proceso, capacitación y soporte según alcance. Tarifas, contratos, reparto de ingresos y cobros requieren definición adicional. Mantener la marca/créditos de pretix y revisar LICENSE-pretix.txt: incluye AGPLv3 y términos adicionales/excepciones; este kit no concede licencia Enterprise ni elimina requisitos de distribución/servicio.

No se ha publicado un evento ni enviado correo/cobrado dinero. Scripts revisados localmente; completar docs/ACEPTACION.md en VPS antes de operar con público.
