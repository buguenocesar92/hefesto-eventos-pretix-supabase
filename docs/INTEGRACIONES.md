# Traspaso a plataformas de Hefesto
Odoo: empezar con exportaciones nativas de asistentes/pedidos y definir un mapeo revisado por el responsable. Distinguir pedido, pago, devolución y documento contable; no crear automáticamente una factura por cada fila sin definir el modelo. No se incluye conector Odoo ni importación contable automática.

WordPress/WooCommerce: enlazar la tienda publicada de pretix desde el sitio del evento. La duplicación de stock entre dos tiendas requiere integración explícita y pruebas; este kit no sincroniza cupos o ventas con WooCommerce.

API: pretix tiene API nativa y mecanismos de autorización. Crear en el panel un token limitado al organizador/operaciones necesarias, guardarlo en el entorno del consumidor y probar con un evento ficticio. No hay token precargado, cliente externo conectado ni webhook enviado por esta entrega.

Pagos: no hay Flow/Webpay/Stripe configurados ni credenciales de cobro incluidas. Revisar proveedor/plugin, compatibilidad y licencia de la versión exacta antes de implementarlo; no prometer soporte solo por usar pretix. Mantener el evento de prueba o gratuito hasta validar el proceso real.

Entrega al organizador: dominio, responsable del sistema y del evento, permisos, remitente probado, cupos/productos aprobados, proceso de check-in, exportación de prueba, respaldo y registro de recuperación. La cuenta staff es de operación del sistema; asignar los permisos de equipo/organizador necesarios mediante el modelo nativo y probar separación entre organizadores.

Licencia: conservar créditos y marca de pretix, revisar el texto completo incluido y las licencias de cualquier plugin. El kit usa el motor comunitario y no desbloquea funciones Enterprise ni sustituye una licencia comercial.
