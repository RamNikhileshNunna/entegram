#!/usr/bin/env python3
"""Prepare a private keystore and verify the pinned v0.0.2 release identity."""
import argparse
import base64
import hashlib
import os
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parent.parent


def expected_signer():
    value = (ROOT / 'android/release-certificate.sha256').read_text().strip()
    if not re.fullmatch('[0-9a-f]{64}', value):
        raise SystemExit('Invalid release certificate pin')
    return value


def checked(command):
    result = subprocess.run(command, capture_output=True)
    if result.returncode:
        raise SystemExit('Signing verification failed; check the keystore, alias and password.')
    return result.stdout


def prepare():
    password = os.environ.get('ENTEGRAM_KEYSTORE_PASSWORD')
    if not password:
        raise SystemExit('Missing ENTEGRAM_KEYSTORE_PASSWORD; release signing cannot use a random key.')
    encoded = os.environ.get('ENTEGRAM_KEYSTORE_BASE64')
    if encoded:
        temporary = os.environ.get('RUNNER_TEMP')
        if not temporary:
            raise SystemExit('RUNNER_TEMP is required for an ephemeral CI keystore')
        directory = Path(temporary) / 'entegram-signing'
        directory.mkdir(mode=0o700, parents=True, exist_ok=True)
        path = directory / 'release.p12'
        try:
            path.write_bytes(base64.b64decode(''.join(encoded.split()), validate=True))
        except ValueError:
            raise SystemExit('Invalid encoded keystore') from None
        path.chmod(0o600)
    else:
        value = os.environ.get('ENTEGRAM_KEYSTORE_PATH')
        if not value:
            raise SystemExit('Missing ENTEGRAM_KEYSTORE_PATH or ENTEGRAM_KEYSTORE_BASE64')
        path = Path(value).resolve()
    if not path.is_file():
        raise SystemExit('Signing keystore is missing')
    alias = os.environ.get('ENTEGRAM_KEY_ALIAS', 'androiddebugkey')
    certificate = checked(['keytool', '-exportcert', '-keystore', str(path),
                           '-alias', alias, '-storepass:env', 'ENTEGRAM_KEYSTORE_PASSWORD'])
    if hashlib.sha256(certificate).hexdigest() != expected_signer():
        raise SystemExit('Signing key differs from v0.0.2; refusing to build an incompatible release.')
    environment_file = os.environ.get('GITHUB_ENV')
    if environment_file and encoded:
        with open(environment_file, 'a') as stream:
            stream.write(f'ENTEGRAM_KEYSTORE_PATH={path}\n')
    print('Verified original v0.0.2 signing identity.')


def android_tool(name):
    sdk = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
    if not sdk:
        raise SystemExit('ANDROID_HOME is required for APK verification')
    folders = sorted((Path(sdk) / 'build-tools').glob('*'),
                     key=lambda p: tuple(int(n) for n in re.findall(r'\d+', p.name)), reverse=True)
    for folder in folders:
        candidate = folder / name
        if candidate.is_file():
            return str(candidate)
    raise SystemExit(f'Android tool unavailable: {name}')


def apk_identity(path):
    certificate = checked([android_tool('apksigner'), 'verify', '--print-certs', str(path)]).decode()
    signers = re.findall(r'Signer #\d+ certificate SHA-256 digest: ([0-9a-f]+)', certificate)
    if signers != [expected_signer()]:
        raise SystemExit('APK signer differs from v0.0.2; refusing to publish.')
    badging = checked([android_tool('aapt'), 'dump', 'badging', str(path)]).decode()
    package = re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'", badging)
    if not package or package[1] != 'com.entegram.entegram':
        raise SystemExit('APK package does not match Entegram')
    return package[1], int(package[2]), package[3]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('prepare')
    verify = commands.add_parser('verify-apk')
    verify.add_argument('apk', type=Path)
    verify.add_argument('--upgrade-from', type=Path)
    args = parser.parse_args()
    if args.command == 'prepare':
        prepare()
    else:
        package, code, version = apk_identity(args.apk)
        if args.upgrade_from:
            old_package, old_code, _ = apk_identity(args.upgrade_from)
            if package != old_package or code <= old_code:
                raise SystemExit('Update version must increase and retain its package name')
        print(f'Verified APK {version} ({code}): same package and original v0.0.2 signer.')


if __name__ == '__main__':
    main()
