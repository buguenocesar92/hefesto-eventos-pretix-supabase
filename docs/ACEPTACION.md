# Aceptación en servidor
- Docker Compose config --quiet, imágenes compatibles con arquitectura y descarga sin errores.
- Preflight DB con verify-full, rol sin privilegios excesivos y permisos correctos; migraciones completas sin cambios en esquemas Supabase reservados. Verificar Data API desactivada desde el panel.
- Permisos UID15371, arranque de nginx/web/Celery nativos y periodic. Confirmar que solo hay una ejecución periódica y que las colas se procesan.
- Crear administrador por CLI, login y recuperación; nuevas cuentas de panel no se registran públicamente. Probar permisos entre organizadores/equipos y MFA según el procedimiento que se adopte.
- Bootstrap HTTP únicamente localhost/Mailpit. Producción HTTPS con cookies/CSRF y enlaces correctos. Solo app:80 expuesto al proxy; Redis/DB sin puerto público.
- Evento gratuito ficticio: pedido, cuota, confirmación/correo, ticket/salida activada, cancelación/expiración y check-in con segundo intento. Revisar formatos CLP y fecha/hora.
- Probar SMTP real con destinatario autorizado antes de marcar SMTP_READY y publicar. No hay pasarela real probada por realizar un pedido gratuito.
- Backup completo y recuperación en proyecto nuevo, con salida controlada antes de iniciar workers/periodic. Verificar autorización, pedidos, medios, estado de colas y ausencia de envíos externos accidentales.
- Medir recursos y concurrencia del patrón esperado. Este kit no demuestra capacidad para una venta masiva simultánea.
