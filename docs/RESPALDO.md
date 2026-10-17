# Respaldo y recuperación conjunta
`python3 scripts/backup.py` registra servicios activos, detiene periodic/app, después Redis, comprueba parada, genera pg_dump de public y copia /data y Redis junto con .env/CA/configuración. Escribe completed y SHA-256 solo al finalizar. Reinicia los servicios previamente activos incluso si una copia falla. Hay indisponibilidad durante la copia; no ejecutar con migraciones u otras instancias usando la misma DB/volúmenes.

`python3 scripts/check_backup.py /ruta/respaldo` comprueba hashes y tar. Rechaza escapes, enlaces, dispositivos, duplicados y setuid/setgid; límite de2millones de entradas/500GiB por tar. Los hashes no prueban autenticidad. La copia contiene pedidos, datos personales, archivos, sesiones, colas y secretos: cifrar fuera del VPS y acordar retención/acceso.

No incluye imágenes Docker, DNS/TLS/Coolify, datos de pasarelas ni archivos almacenados externamente si se añade S3. Mantener registro de versión y una copia consistente antes de cada cambio. Un backup lógico de public no representa toda la configuración del proyecto Supabase.

## Restaurar en otro proyecto
1. Descomprimir este mismo kit. Crear un **nuevo** proyecto Supabase y aplicar SQL/rol/clave, CA y Data API desactivada. Crear un proyecto Compose único y volúmenes nuevos. Mantener destino completamente detenido; no ejecutar migrate antes de restaurar.
2. Configurar .env de destino con sus credenciales DB y CA. Conservar DJANGO_SECRET exacto del respaldo. Los scripts comparan el resto del código/configuración para evitar mezclar versiones.
3. Ejecutar `python3 scripts/restore.py /ruta/respaldo --accept-restored-jobs`. Comprueba hashes, ausencia de servicios activos, public vacío y ambos volúmenes vacíos. Restaura public sin owner/ACL de origen y en una transacción, conserva public existente y extrae medios/Redis. No borra datos ni inicia servicios.
4. Si una fase falla, el destino puede quedar parcial: investigar y repetir en otro destino nuevo, no sobreescribir a ciegas.
5. Antes de arrancar un ensayo, preparar y comprobar una política de salida que permita únicamente DNS y la conexión TLS5432 al proyecto Supabase de prueba y bloquee correos/webhooks/pasarelas externos. Este kit **no instala reglas de firewall**. No usar network internal sin más: también cortaría la conexión a Supabase. Si no puede garantizarse el aislamiento, no iniciar una copia de colas de producción para ensayar.
6. Usar bootstrap para localhost/Mailpit como capa adicional de captura de correo, no como aislamiento suficiente. Configuraciones de remitentes/proveedores guardadas en DB o tareas antiguas podrían saltarse el SMTP global; por eso se exige controlar salida.
7. Probar login, autorización, evento/pedidos de prueba, medios y colas en el destino aislado. Revisar duplicados/reintentos y estado de pagos con el responsable antes de cualquier corte real. No promover una copia con workers activos sobre la misma operación que el servidor original.

La restauración puede recuperar sesiones, correos pendientes, pedidos y tareas; no se autoriza enviarlos a clientes por ejecutar el script. Los proveedores externos pueden conservar operaciones más recientes que el backup: la recuperación requiere reconciliar esos estados antes de volver a vender.
