# Política de tratamiento de datos personales — Eventos (pretix) (Hefesto Studio)

Estado: vigente desde 2026-10-20. Responsable del tratamiento: el cliente que
opera el kit. Este documento describe qué datos guarda el kit, por qué, cuánto
tiempo los retiene y cómo se ejercen los derechos del titular (Ley 21.719).

## 1. Qué datos guarda este kit

El kit de eventos (pretix) guarda, por persona:

- **Pedido**: nombre, correo, dirección y **RUT** (dato fiscal), con los
  tickets y sus códigos QR.
- **Cuentas de la aplicación**: usuario, hash de contraseña, rol y estado.
- **Pagos**: método, referencia y fecha de cada pago, más los datos fiscales
  emitida en las facturas.
- **Correo y notificaciones**: buzón con los correos de tickets y las claves de
  verificación (`AUTHZED_*`).
- **Copias locales de respaldo**: `backups/<timestamp>/` con el dump de
  PostgreSQL (`public.dump`), los archivos (`files.tar.gz`), el estado de Redis
  (`redis.tar.gz`) y la configuración.

Es el kit con más datos personales y fiscales del grupo: un pedido identifica a
una persona y la vincula con una operación tributaria.

## 2. Qué datos NO guarda este kit

- El `.env` **no** se copia en claro al respaldo: solo sus nombres de variable
  (`env.vars`) y, si hay un receptor `age` configurado, el `.env` cifrado
  (`env.age`). Ver `docs/CONTRATO-RESPALDO.md`, regla 5.
- El kit no guarda datos de tarjetas: el pago lo resuelve una pasarela externa y aquí solo queda la referencia.

## 3. Base legal y deberes

- **Minimización**: el pedido guarda lo indispensable para emitir el ticket y la factura. No se guardan documentos de identidad ni datos de salud; el RUT solo se pide cuando la factura lo exige.
- **Finalidad**: vender entradas y gestionar asistentes. Los datos no se usan para otros fines ni se ceden a terceros.
- **Seguridad**: los respaldos se cifran en reposo hacia el destino del
  operador, la clave privada no está en este servidor y el `.env` nunca sale
  en claro.
- **Auditoría**: cada respaldo y cada restauración dejan registro en
  `logs/restore.log` con origen, sha256 verificado, destino y resultado. Es
  registro de actividades de tratamiento: no guarda valores de secretos.

## 4. Retención

| Dato | Dónde | Retención por defecto | Quién lo borra |
|---|---|---|---|
| Pedidos, asistentes y RUT | PostgreSQL (volumen `public`) | según la obligación tributaria y fiscal del cliente; **a definir por el operador** | el operador, desde la interfaz |
| Tickets y códigos QR | PostgreSQL (volumen `public`) y volumen `/files` | mientras exista el evento | el operador |
| Pagos y facturas | PostgreSQL (volumen `public`) | según la obligación tributaria del cliente | el operador |
| Cuentas de la aplicación | PostgreSQL (volumen `public`) | mientras la cuenta exista | el operador |
| Cola y estado de Redis | volumen `/redis-data` | mientras el evento exista | el operador |
| Respaldos en disco | `backups/<timestamp>/` | **a definir por el operador**; el kit no borra nada por su cuenta | el operador |
| Registro de auditoría | `logs/restore.log` | append-only; se trunca por política del cliente | el operador |

**El kit no borra respaldos ni datos por su cuenta.** Borrar es una decisión del
operador, porque un respaldo borrado no se recupera.

## 5. Derechos del titular (acceso, rectificación y supresión)

1. **Acceso**: entregar los datos de un titular concreto desde la interfaz del
   kit o desde el dump de la base.
2. **Rectificación**: corregir los datos desde la interfaz del kit.
3. **Supresión**: eliminar el registro y dejar constancia de la supresión en el
   registro de auditoría.
4. **Revocación del consentimiento**: si el tratamiento depende del
   consentimiento, eliminar el registro.

El kit garantiza que los datos son localizables, corregibles y borrables; el
cliente es quien conoce la identidad de los titulares.

## 6. Verificación

- `bats tests/backup_restore.bats` comprueba, con datos sintéticos, que el
  `.env` no queda en claro, que el manifiesto lleva las cinco claves, que un
  artefacto alterado se rechaza y que un destino no vacío aborta la
  restauración.
- `gitleaks` corre en CI sobre el repositorio y su historial.
