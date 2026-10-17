# Validación · 2026-10-16
Comprobado localmente:
- Sintaxis Python por AST, scripts shell con sh -n y parseo de ambos YAML.
- Imágenes fijadas por digest, ausencia de puertos de host en Compose base y migraciones separadas con AUTOMIGRATE=skip.
- configure.py crea .env 0600, genera dos secretos distintos y no sobrescribe un entorno existente.
- validate.py ejecutado en modo bootstrap con existencia de CA simulada: admite localhost esperado y rechaza URL externa HTTP, secreto corto y publicación sin SMTP_READY. No se realizó TLS ni consulta Django/usuario real.
- Con comandos Docker simulados: parada app/periodic/Redis, dump/tar ficticios, manifiesto y checksums, filtrado SCHEMA public de pg_restore, rechazo de tablas/volúmenes no vacíos, reactivación de servicios tras fallo de dump y completed solo en copia terminada.
- Verificador rechaza archivos alterados, rutas absolutas/../ y symlinks de tar.
- Integridad ZIP y exclusión de .env real, certificados reales, copias y cachés.

No se ejecutó Docker, pretix, PostgreSQL/Supabase, Redis, supervisor, Django, migraciones, SMTP ni navegador. Los archivos dump de prueba son ficticios; no prueban pg_restore ni la recuperación de un pedido/ticket. La consulta de administrador del guard requiere validación con el modelo real y la imagen.

Pendiente: docs/ACEPTACION.md completo en VPS, con certificado/rol/migraciones reales, privilegios Supabase, arranque supervisor y workers, periodic, correo, HTTPS/CSRF, evento gratuito ficticio, cuotas, ticket/check-in y recuperación integral en un destino aislado. No hay evento publicado, destinatario contactado, pasarela activada o cobro realizado.
