"""Análisis estático de los APK release (sin y con --obfuscate).

Uso: python -I tool/analisis_apk.py <dir> <android-sdk/build-tools/36.0.0> <salida.txt>
<dir> lleva sin_ofuscar.apk, ofuscado.apk y mapping.txt (fuera del repo: mapping.txt
nunca se versiona). Ver docs/evidencias/estatico-2026-10-21/ANALISIS_ESTATICO.md.
Solo lee los APK; no ejecuta nada de ellos.
"""
import pathlib
import re
import struct
import subprocess
import sys
import zipfile

D, BT, SALIDA = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]), pathlib.Path(sys.argv[3])
SIN, CON = D / 'sin_ofuscar.apk', D / 'ofuscado.apk'
lineas = []


def p(*a):
    lineas.append(' '.join(str(x) for x in a))


def run(*args):
    r = subprocess.run([str(a) for a in args], capture_output=True, text=True, encoding='utf-8', errors='replace')
    return r.returncode, (r.stdout + r.stderr)


# 1. Identidad, SDK y permisos
p('## 1. Paquete, SDK y permisos (aapt2 dump badging, APK ofuscado)')
_, out = run(BT / 'aapt2.exe', 'dump', 'badging', CON)
for l in out.splitlines():
    if l.startswith(('package:', 'minSdkVersion', 'sdkVersion', 'targetSdkVersion', 'uses-permission', 'application-label:', 'native-code')):
        p(l)

# 2. Manifiesto
p('\n## 2. Manifiesto (aapt2 dump xmltree)')
_, xml = run(BT / 'aapt2.exe', 'dump', 'xmltree', '--file', 'AndroidManifest.xml', CON)
for clave in ('android:debuggable', 'android:allowBackup', 'android:usesCleartextTraffic', 'android:networkSecurityConfig'):
    m = re.search(re.escape(clave) + r'\([^)]*\)=([^\s]+)', xml)
    p(f'{clave}: {m.group(1) if m else "(no declarado)"}')
bloques = re.split(r'\n\s+E: (?=activity|service|receiver|provider)', xml)
for b in bloques[1:]:
    tipo = b.split(' ', 1)[0]
    nombre = re.search(r'android:name\([^)]*\)="([^"]+)"', b)
    exp = re.search(r'android:exported\([^)]*\)=(\S+)', b)
    p(f'{tipo}: {nombre.group(1) if nombre else "?"} exported={exp.group(1) if exp else "(implícito)"}')

# 3. Firma
p('\n## 3. Firma (apksigner verify --print-certs)')
_, out = run(BT / 'apksigner.bat', 'verify', '--verbose', '--print-certs', CON)
for l in out.splitlines():
    if re.search(r'Verifies|Verified using v[1-4]|Signer #1 certificate DN|SHA-256 digest', l):
        p(l.strip())

# 4. 16 KB
p('\n## 4. Páginas de 16 KB')
code, out = run(BT / 'zipalign.exe', '-c', '-P', '16', '-v', '4', CON)
p('zipalign -c -P 16 -v 4:', 'OK' if code == 0 else f'FALLA ({code})')
p(out.strip().splitlines()[-1] if out.strip() else '')
with zipfile.ZipFile(CON) as z:
    for n in sorted(z.namelist()):
        if n.startswith('lib/') and n.endswith('.so'):
            elf = z.read(n)
            clase = elf[4]  # 1=32 bits, 2=64 bits
            if clase == 2:
                phoff, = struct.unpack_from('<Q', elf, 0x20)
                phentsize, phnum = struct.unpack_from('<HH', elf, 0x36)
                aligns = [struct.unpack_from('<Q', elf, phoff + i * phentsize + 0x30)[0]
                          for i in range(phnum) if struct.unpack_from('<I', elf, phoff + i * phentsize)[0] == 1]
            else:
                phoff, = struct.unpack_from('<I', elf, 0x1C)
                phentsize, phnum = struct.unpack_from('<HH', elf, 0x2A)
                aligns = [struct.unpack_from('<I', elf, phoff + i * phentsize + 0x1C)[0]
                          for i in range(phnum) if struct.unpack_from('<I', elf, phoff + i * phentsize)[0] == 1]
            minimo = min(aligns)
            p(f'{n}: alineación LOAD mínima {minimo} ({minimo // 1024} KB) -> {"OK" if minimo >= 16384 else "MENOR A 16 KB"}')

# 5. R8 (Java/Kotlin)
p('\n## 5. R8 sobre Java/Kotlin (mapping.txt; el archivo no se versiona)')
clases = renombradas = 0
paquetes = {}
for l in (D / 'mapping.txt').read_text(encoding='utf-8', errors='replace').splitlines():
    m = re.match(r'^(\S+) -> (\S+):$', l)
    if m:
        clases += 1
        orig, nuevo = m.groups()
        if orig != nuevo:
            renombradas += 1
        raiz = '.'.join(orig.split('.')[:2])
        paquetes.setdefault(raiz, [0, 0])
        paquetes[raiz][0] += 1
        paquetes[raiz][1] += orig != nuevo
p(f'clases en mapping.txt: {clases}; renombradas: {renombradas} ({100 * renombradas / max(clases, 1):.0f} %)')
for raiz, (t, r) in sorted(paquetes.items(), key=lambda x: -x[1][0])[:8]:
    p(f'  {raiz}.*: {t} clases, {r} renombradas')
with zipfile.ZipFile(CON) as z:
    dex = [n for n in z.namelist() if re.fullmatch(r'classes\d*\.dex', n)]
p('archivos dex:', dex)

# 6. Dart (libapp.so)
p('\n## 6. Código Dart en libapp.so (arm64), antes y después de --obfuscate')
IDENT = ['AuthViewModel', 'ApiClient', 'SecureTokenStorage', 'PrivacidadRepository', 'EditarPerfilViewModel',
         'SecretariaHoyViewModel', 'CitasRepository', 'TiendaViewModel', 'loadPerfil', 'guardarPreferencias',
         'loadMisCitas', 'completeLogin', 'restoreSession', 'verify2fa']
def libapp(apk):
    with zipfile.ZipFile(apk) as z:
        return z.read('lib/arm64-v8a/libapp.so')
a, b = libapp(SIN), libapp(CON)
p(f'tamaño libapp.so: sin ofuscar {len(a) / 1e6:.2f} MB, ofuscado {len(b) / 1e6:.2f} MB')
p(f'{"identificador":28} sin ofuscar  ofuscado')
for i in IDENT:
    p(f'{i:28} {a.count(i.encode()):11} {b.count(i.encode()):9}')

# 7. Cadenas que siguen en claro (esperado) y búsqueda de secretos
p('\n## 7. Cadenas en claro y búsqueda de secretos (libapp.so ofuscado)')
for s in ['/privacidad/preferencias/', '/auth/token/refresh/', 'backendstylobarberconect-lo71.onrender.com', 'BEGIN CERTIFICATE']:
    p(f'"{s}": {"presente" if s.encode() in b else "ausente"}')
patrones = {
    'clave privada PEM': rb'BEGIN (?:RSA |EC )?PRIVATE KEY',
    'AWS access key': rb'AKIA[0-9A-Z]{16}',
    'token tipo sk_/pk_ live': rb'(?:sk|pk)_live_[0-9a-zA-Z]{10,}',
    'Google API key': rb'AIza[0-9A-Za-z_\-]{35}',
    'JWT': rb'eyJ[A-Za-z0-9_\-]{10,}\.eyJ[A-Za-z0-9_\-]{10,}',
    'Brevo/Sendinblue key': rb'xkeysib-[0-9a-f]{20,}',
}
with zipfile.ZipFile(CON) as z:
    for nombre, pat in patrones.items():
        hallados = []
        for n in z.namelist():
            datos = z.read(n)
            if re.search(pat, datos):
                hallados.append(n)
        p(f'{nombre}: {"NINGUNO" if not hallados else hallados}')

SALIDA.write_text('\n'.join(lineas) + '\n', encoding='utf-8')
print('\n'.join(lineas))
