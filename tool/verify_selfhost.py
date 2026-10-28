#!/usr/bin/env python3
"""Run the opt-in Flutter account check without retaining private test output."""
import getpass
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import threading
import time


def main():
    if not sys.stdin.isatty():
        sys.exit('Run in a terminal so the password can be entered without echo.')
    endpoint = input('Ente endpoint (including http:// or https://): ').strip()
    email = input('Email: ').strip()
    password = getpass.getpass('Password: ')
    if not endpoint.startswith(('http://', 'https://')) or not email or not password:
        sys.exit('An endpoint, email and password are required.')

    root = Path(__file__).resolve().parent.parent
    checks = []
    with tempfile.TemporaryDirectory(prefix='entegram-live-') as temporary:
        folder = Path(temporary)
        report = folder / 'checks.jsonl'
        report.touch(mode=0o600)
        environment = os.environ.copy()
        environment.update(ENTE_TEST_EMAIL=email, ENTE_TEST_PASSWORD=password,
                           ENTE_TEST_URL=endpoint, ENTE_TEST_STORAGE=str(folder / 'data'),
                           ENTE_TEST_REPORT=str(report))
        process = subprocess.Popen(
            ['flutter', 'test', '--no-pub', '--reporter', 'expanded',
             'test/selfhost_live_check.dart'],
            cwd=root, env=environment, stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            start_new_session=True,
        )
        environment.pop('ENTE_TEST_EMAIL')
        environment.pop('ENTE_TEST_PASSWORD')
        del password

        def discard_output():
            # Framework failures can include private object values. Only the
            # explicit sanitized checkpoints below are suitable for display.
            while process.stdout.read(65536):
                pass

        reader = threading.Thread(target=discard_output, daemon=True)
        reader.start()
        position = 0

        def show_checks():
            nonlocal position
            with report.open() as stream:
                stream.seek(position)
                for line in stream:
                    try:
                        check = json.loads(line)['check']
                    except (ValueError, KeyError):
                        continue
                    checks.append(check)
                    print(check, flush=True)
                position = stream.tell()

        try:
            deadline = time.monotonic() + 21 * 60
            while process.poll() is None:
                show_checks()
                if time.monotonic() > deadline:
                    raise TimeoutError('Live check exceeded 21 minutes')
                time.sleep(0.25)
            show_checks()
        finally:
            # Stop child workers before deleting decrypted local test data.
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
        success = (process.returncode == 0 and
                   'LIVE_VERIFICATION_COMPLETE' in checks and
                   'LOCAL_CLIENTS_DISPOSED' in checks and
                   not any(check.startswith('FAILED') for check in checks))
    print('Private temporary test storage removed.')
    return 0 if success else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit('Live check interrupted; temporary test storage removed.')
