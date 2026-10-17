# Evento de demostración
Crear manualmente un organizador de prueba y un evento llamado Taller Hefesto — DEMO. Usar contactos ficticios y correo Mailpit. Mantener el evento en modo de prueba y revisar en la versión instalada cómo se distingue de una venta real.

1. Elegir idioma español y zona America/Santiago. Revisar moneda CLP y cómo se representan importes antes de fijar precios. No copiar reglas tributarias de una demo a un evento real.
2. Crear una categoría Entrada general y un producto de prueba. Para la primera prueba usar precio cero, cuota pequeña y fechas claramente identificadas. La cuota debe estar configurada explícitamente y comprobarse con más de una sesión de navegador.
3. Definir periodo de inscripción, preguntas mínimas y mensaje de confirmación. Evitar RUT/documentos u otros datos que el proceso no requiera. Revisar finalidad, acceso y retención con el organizador.
4. Probar pedido gratuito completo desde otra sesión: selección → datos → revisión → confirmación → correo → entrada si la salida correspondiente está habilitada.
5. Activar y comprobar el formato de entrada/PDF que vaya a utilizar el evento. Confirmar legibilidad, nombre/fecha y código. No se entregan tickets reales precargados en el ZIP.
6. Configurar lista de check-in y probar el procedimiento nativo o aplicación de escaneo elegida. Validar permiso del dispositivo/token, una entrada válida y el segundo intento de esa misma entrada. No afirmar que un lector está instalado sin realizar la prueba.
7. Probar expiración/cancelación y liberación de cuota con el estado de pedido esperado. Confirmar el comportamiento con periodic y Celery activos; no basta probar solo la página de venta.

Antes de publicar: aprobar productos, cupos, periodos, remitente, textos, condiciones del evento, política de cancelación y medios de pago. Los pagos de prueba o gratuitos no verifican una pasarela real. Cambiar a modo real solo tras aprobación del organizador.
