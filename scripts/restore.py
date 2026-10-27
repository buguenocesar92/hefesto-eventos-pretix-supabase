#!/usr/bin/env python3
"""Restauracion de hefesto-eventos en un destino nuevo y vacio.

Sin --confirmar CONFIRMAR_RESTAURACION no se escribe nada; con --dry-run se
simula. Valida el manifiesto y los sha256 antes de tocar el destino, exige los
volumenes vacios y deja restore-report.json y auditoria.

El .env NO viaja en el respaldo: el destino debe conservar el suyo
(DJANGO_SECRET, credenciales de base, claves AUTHZED). El respaldo solo deja
los nombres de variable (env.vars) y, si hay receptor age, el .env cifrado.
"""
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import CONFIG, ROOT, dc, sha  # noqa: E402
from respaldo_contrato import (RespaldoError, auditar, ejecutar,  # noqa: E402
                               ejecutar_check, escribir_informe, opciones_restore)

SOFTWARE = 'hefesto-eventos'
VERSION = '2026.8.0'
DATABASE = 'postgresql'


def main():
    modo, origen = opciones_restore(sys.argv[1:])
    origen = Path(origen).resolve()
    ejecutar_check(str(origen), SOFTWARE, VERSION, DATABASE)
    if modo == 'dry-run':
        print('Simulacion: el respaldo es integro y no se escribio nada.')
        print('Para restaurar de verdad: --confirmar CONFIRMAR_RESTAURACION')
        return 0
    for n in CONFIG:
        if not (ROOT / n).is_file() or sha(ROOT / n) != sha(origen / n):
            raise RespaldoError('Kit/configuracion distinto: ' + n, 5)
    if not (ROOT / '.env').is_file():
        raise RespaldoError('Falta el .env del destino: el .env no viaja en el respaldo', 5)
    if dc('ps', '--services', '--status', 'running',
           capture_output=True, text=True).stdout.strip():
        raise RespaldoError('Destino debe estar completamente detenido', 5)
    dc('run', '--rm', '--no-deps', '-T', 'preflight')
    count = dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'psql', 'dbtools',
               '--no-psqlrc', '-Atc',
               "SELECT count(*) FROM pg_tables WHERE schemaname='public'",
               capture_output=True, text=True).stdout.strip()
    if count != '0':
        raise RespaldoError('public no esta vacio; no se sobrescribe', 5)
    for folder in ['/files', '/redis-data']:
        if dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'find', 'filetools',
               folder, '-mindepth', '1', '-print', '-quit',
               capture_output=True, text=True).stdout.strip():
            raise RespaldoError('Volumen ocupado: ' + folder, 5)
    with (origen / 'public.dump').open('rb') as f:
        toc = dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'pg_restore',
                 'dbtools', '--list', stdin=f, stdout=subprocess.PIPE).stdout.decode()
    lines = [s for s in toc.splitlines()
             if not re.match(r'^\d+;\s+\d+\s+\d+\s+SCHEMA\s+-\s+public(?:\s|$)', s)]
    with tempfile.TemporaryDirectory(prefix='hefesto-eventos-restore-') as tmp:
        lista = Path(tmp) / 'restore.list'
        lista.write_text('\n'.join(lines) + '\n')
        os.chmod(tmp, 0o755)
        os.chmod(lista, 0o644)
        with (origen / 'public.dump').open('rb') as f:
            dc('run', '--rm', '--no-deps', '-T', '-v', tmp + ':/restore:ro',
               '--entrypoint', 'pg_restore', 'dbtools', '--exit-on-error',
               '--single-transaction', '--no-owner', '--no-acl',
               '--use-list=/restore/restore.list', '--dbname=postgres', stdin=f)
    for name, folder in [('files.tar.gz', '/files'), ('redis.tar.gz', '/redis-data')]:
        with (origen / name).open('rb') as f:
            dc('run', '--rm', '--no-deps', '-T', '--entrypoint', 'tar', 'filetools',
               '-xzf', '-', '-C', folder, stdin=f)
    dc('run', '--rm', '--no-deps', '-T', 'permissions')
    escribir_informe(origen, software=SOFTWARE, version=VERSION, database=DATABASE,
                     modo='confirmado', resultado='restaurado', destino=str(ROOT))
    auditar(ROOT, operacion='restore', kit=SOFTWARE, origen=str(origen),
            destino=str(ROOT), resultado='restaurado')
    print('Datos, archivos y Redis recuperados; no se inicia nada. Aislar salida '
          'antes de ensayar: se pueden reactivar correos, pedidos y webhooks.')
    return 0


if __name__ == '__main__':
    raise SystemExit(ejecutar(main))
