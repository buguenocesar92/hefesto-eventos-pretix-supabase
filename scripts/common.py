"""Utilidades propias del kit hefesto-eventos (pretix + PostgreSQL).

El contrato comun de respaldo vive en scripts/respaldo_contrato.py; aqui solo
queda lo especifico del kit.
"""
import hashlib
import subprocess
import tarfile
from pathlib import Path, PurePosixPath

ROOT = Path(__file__).resolve().parents[1]
# Configuracion que viaja en el respaldo. El .env NO esta aqui: lo trata
# respaldo_contrato.exportar_env (nombres en claro, valor cifrado con age).
CONFIG = ['compose.yaml', 'compose.bootstrap.yaml', 'ops/pretix.cfg', 'ops/pretixtask.conf',
          'ops/start.sh', 'ops/periodic.sh', 'ops/validate.py', 'ops/preflight.sh',
          'ops/preflight.sql', 'certs/ca.crt']
SERVICES = ['app', 'periodic', 'redis']


def dc(*a, **kw):
    return subprocess.run(['docker', 'compose', '--project-directory', str(ROOT),
                           '-f', str(ROOT / 'compose.yaml'), *a], check=True, **kw)


def sha(p):
    with p.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def safe_tar(path):
    names = set()
    size = 0
    with tarfile.open(path, 'r|gz') as tf:
        for m in tf:
            n = PurePosixPath(m.name)
            if n.is_absolute() or '..' in n.parts or not (m.isfile() or m.isdir()) \
                    or m.mode & 0o6000 or str(n) in names:
                raise SystemExit('Ruta/tipo/modo tar no admitido')
            names.add(str(n))
            size += m.size
            if len(names) > 2000000 or size > 500 * 1024 ** 3:
                raise SystemExit('Tar excede limite')
