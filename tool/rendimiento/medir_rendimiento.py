"""Mide el tiempo de respuesta del catálogo y de la disponibilidad (GH#27, QA-014).

Hace N consultas secuenciales a cada endpoint, cada una con una conexión nueva y
`Cache-Control: no-cache`, y escribe un CSV con cada medición más un resumen
(p50, p95, máximo y porcentaje de consultas en 3 s o menos).

Uso:
  # Backend local (catálogo + disponibilidad, con un cliente de prueba)
  python tool/rendimiento/medir_rendimiento.py --base http://127.0.0.1:8000/api \
      --credenciales ~/.stylo-local/dart_defines.local.json --salida docs/evidencias/rendimiento-2026-11-11/local

  # Producción: SOLO endpoints públicos de lectura (sin login, sin escrituras)
  python tool/rendimiento/medir_rendimiento.py --base https://<servicio>.onrender.com/api --solo-publico \
      --salida docs/evidencias/rendimiento-2026-11-11/produccion

Las credenciales se leen del archivo local (claves TEST_CLIENT_USER/TEST_CLIENT_PASS) y nunca se imprimen.
"""
import argparse, csv, datetime as dt, json, os, platform, statistics, time, urllib.request, urllib.error
from pathlib import Path

LIMITE_S = 3.0


def pedir(url, metodo='GET', cuerpo=None, token=None, timeout=30):
    datos = json.dumps(cuerpo).encode() if cuerpo is not None else None
    req = urllib.request.Request(url, data=datos, method=metodo)
    req.add_header('Cache-Control', 'no-cache')
    req.add_header('Accept', 'application/json')
    if datos is not None:
        req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', f'Bearer {token}')
    t0 = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            cuerpo_r = r.read()
            codigo = r.status
    except urllib.error.HTTPError as e:
        cuerpo_r, codigo = e.read(), e.code
    return time.perf_counter() - t0, codigo, cuerpo_r


def percentil(valores, p):
    v = sorted(valores)
    k = (len(v) - 1) * p
    f, c = int(k), min(int(k) + 1, len(v) - 1)
    return v[f] + (v[c] - v[f]) * (k - f)


def resumen(nombre, filas):
    t = [f['segundos'] for f in filas]
    ok = [f for f in filas if f['http'] == 200]
    dentro = sum(1 for f in ok if f['segundos'] <= LIMITE_S)
    return {
        'consulta': nombre, 'n': len(filas), 'http_200': len(ok),
        'p50_ms': round(statistics.median(t) * 1000, 1), 'p95_ms': round(percentil(t, 0.95) * 1000, 1),
        'max_ms': round(max(t) * 1000, 1), 'min_ms': round(min(t) * 1000, 1),
        'promedio_ms': round(statistics.mean(t) * 1000, 1),
        'pct_<=3s': round(100 * dentro / len(filas), 1), 'cumple_95pct_<=3s': dentro / len(filas) >= 0.95,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--base', required=True)
    ap.add_argument('--n', type=int, default=30)
    ap.add_argument('--credenciales')
    ap.add_argument('--solo-publico', action='store_true')
    ap.add_argument('--salida', required=True)
    a = ap.parse_args()
    if a.solo_publico is False and 'onrender.com' in a.base:
        raise SystemExit('En producción solo se permite --solo-publico (lectura de endpoints públicos).')
    base = a.base.rstrip('/')
    out = Path(a.salida)
    out.mkdir(parents=True, exist_ok=True)

    consultas = {'catalogo_servicios': lambda: pedir(f'{base}/public/servicios/'),
                 'catalogo_productos': lambda: pedir(f'{base}/public/productos/')}
    contexto = {}
    if not a.solo_publico:
        cred = json.load(open(os.path.expanduser(a.credenciales), encoding='utf-8'))
        _, c, b = pedir(f'{base}/login/', 'POST', {'email': cred['TEST_CLIENT_USER'], 'password': cred['TEST_CLIENT_PASS']})
        token = json.loads(b).get('access') if c == 200 else None
        if not token:
            raise SystemExit(f'No se pudo iniciar sesión con el cliente de prueba (HTTP {c}).')
        servicios = json.loads(pedir(f'{base}/public/servicios/')[2])
        lista = servicios.get('servicios', servicios) if isinstance(servicios, dict) else servicios
        serv = lista[0]
        sid, dur = serv.get('id') or serv.get('id_servicio'), int(serv.get('duracion_minutos') or serv.get('duracion') or 30)
        barberos = json.loads(pedir(f'{base}/barberos/?servicio_id={sid}', token=token)[2])['barberos']
        bid = barberos[0].get('id') or barberos[0].get('id_barbero')
        fecha = (dt.date.today() + dt.timedelta(days=1))
        if fecha.weekday() == 6:
            fecha += dt.timedelta(days=1)
        contexto = {'servicio_id': sid, 'duracion': dur, 'barbero_id': bid, 'fecha': fecha.isoformat()}
        q = f'{base}/disponibilidad/?barbero_id={bid}&fecha={fecha.isoformat()}&duracion={dur}'
        consultas['disponibilidad'] = lambda: pedir(q, token=token)

    filas = []
    for nombre, fn in consultas.items():
        fn()  # una consulta de calentamiento que no se cuenta (se documenta)
        for i in range(1, a.n + 1):
            seg, codigo, cuerpo = fn()
            filas.append({'consulta': nombre, 'i': i, 'segundos': round(seg, 4), 'http': codigo, 'bytes': len(cuerpo),
                          'hora': dt.datetime.now().isoformat(timespec='seconds')})
    with open(out / 'mediciones.csv', 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=list(filas[0]))
        w.writeheader()
        w.writerows(filas)
    res = [resumen(n, [f for f in filas if f['consulta'] == n]) for n in consultas]
    meta = {'base': base if 'onrender.com' not in base else 'produccion (Render, solo lectura publica)',
            'fecha': dt.datetime.now().isoformat(timespec='seconds'), 'n_por_consulta': a.n,
            'equipo': f'{platform.system()} {platform.release()} · Python {platform.python_version()}',
            'cache': 'conexion nueva por consulta y Cache-Control: no-cache; 1 consulta de calentamiento no contada',
            'contexto': contexto, 'resumen': res}
    json.dump(meta, open(out / 'resumen.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(json.dumps(meta, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
