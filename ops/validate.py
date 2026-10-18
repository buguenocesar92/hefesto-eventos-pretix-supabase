import os,re,sys
from pathlib import Path
from urllib.parse import urlsplit

def invalid(msg):raise SystemExit(msg)
e=os.environ;local=e.get('BOOTSTRAP_MODE')=='true';u=urlsplit(e.get('PRETIX_PRETIX_URL',''))
if u.username or u.password or u.query or u.fragment or u.path not in ('','/'):invalid('Usar dominio raiz sin parametros')
if local:
    if e.get('PRETIX_PRETIX_URL')!='http://localhost:8114':invalid('Bootstrap solo localhost8114')
elif u.scheme!='https' or not u.hostname:invalid('HTTPS requerido')
for key in ['PRETIX_DATABASE_PASSWORD','PRETIX_DJANGO_SECRET']:
    if not re.fullmatch('[a-f0-9]{64}',e.get(key,'')):invalid('Configurar secreto '+key)
sslmode=e.get('PRETIX_DATABASE_SSLMODE','verify-full')
if sslmode=='verify-full' and not Path('/certs/ca.crt').is_file():invalid('Falta CA DB')
if not local:
    smtp_ready=e.get('SMTP_READY')=='true'
    if smtp_ready:
        for key in ['PRETIX_MAIL_HOST','PRETIX_MAIL_USER','PRETIX_MAIL_PASSWORD']:
            if not e.get(key) or e[key]=='REEMPLAZAR':invalid('Completar SMTP')
        if e.get('PRETIX_MAIL_PORT')!='465' or e.get('PRETIX_MAIL_SSL')!='on' or e.get('PRETIX_MAIL_TLS')!='off':invalid('SMTP465 TLS implicito requerido')
    else:
        # Correo desactivado: el kit arranca aunque SMTP_READY sea false.
        for key in ['PRETIX_MAIL_HOST','PRETIX_MAIL_USER','PRETIX_MAIL_PASSWORD','PRETIX_MAIL_PORT','PRETIX_MAIL_SSL','PRETIX_MAIL_TLS']:
            os.environ.pop(key,None)
        os.environ['PRETIX_MAIL_BACKEND']='null'
    sys.path.insert(0,'/pretix/src');os.environ['DJANGO_SETTINGS_MODULE']='production_settings'
    import django
    django.setup()
    from django.apps import apps
    User=apps.get_model('pretixbase','User')
    if not User.objects.filter(is_active=True,is_staff=True).exists():invalid('Crear administrador activo por CLI durante bootstrap')
print('Configuracion previa al arranque comprobada; SMTP real no se prueba aqui.')
