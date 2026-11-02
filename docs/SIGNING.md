# Persistent Android signing

Official releases from v0.0.4 onward reuse the original v0.0.2 certificate:

```text
380d0a178c1688109913d433e4ed36b5bfbfc920f6146b848ba9f240855e2f08
```

The public fingerprint is pinned in `android/release-certificate.sha256`.
The private key is never committed or included in release downloads. A higher
version code, the same package name and the same signer allow an update over
v0.0.2 while retaining local app data. The original v0.0.1 and the CI-built
v0.0.3 used different ephemeral keys and do not match this certificate.

## Local release builds

Provide the original private keystore outside the repository:

```sh
export ENTEGRAM_KEYSTORE_PATH=/private/path/to/release.p12
read -rs -p 'Keystore password: ' ENTEGRAM_KEYSTORE_PASSWORD
export ENTEGRAM_KEYSTORE_PASSWORD
python3 tool/signing.py prepare
flutter build apk --release
python3 tool/signing.py verify-apk build/app/outputs/flutter-apk/app-release.apk
unset ENTEGRAM_KEYSTORE_PASSWORD
```

The legacy alias defaults to `androiddebugkey`; `ENTEGRAM_KEY_ALIAS` can override
it. `ENTEGRAM_KEY_PASSWORD` is optional and defaults to the store password.
Gradle rejects release builds without explicit signing settings. It does not
fall back to the runner's debug key or publish an unsigned APK. Debug development
builds do not require release credentials.

To check a specific update, add `--upgrade-from /path/to/entegram-v0.0.2.apk`
to the verification command. This verifies both certificates, the package name
and increasing version code. APK verification also rejects multiple signers or
any certificate that differs from the pinned identity.

## GitHub Actions

The release workflow expects two encrypted repository Actions secrets:

| Secret | Value |
| --- | --- |
| `ENTEGRAM_ANDROID_KEYSTORE_BASE64` | Base64 of the original private keystore, preferably re-encrypted with a strong store password |
| `ENTEGRAM_ANDROID_KEYSTORE_PASSWORD` | Its store and private-key password |

Keep the alias `androiddebugkey` when preparing the CI keystore. Re-encrypting
its storage does not change the private key or signing certificate. Configuring
these secrets requires repository **Secrets: Read and write** permission.
Do not paste a keystore or its password into source, logs or public release assets.

The workflow decodes the secret only into a private runner-temporary directory,
checks its certificate before building, verifies the signed APK before upload,
and removes the temporary keystore even when a build fails. Missing secrets skip automatic APK building/publication while still running analysis and tests. An unexpected signer fails the build and stops publication. Existing release assets cannot be
overwritten by the workflow.

Maintain an independent secure backup of the original keystore. The certificate
inside an APK is public and cannot be used to reconstruct a lost private key.
