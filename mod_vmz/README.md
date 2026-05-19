# VMZ Quick Test Workflow

1. Build package:

```bash
python scripts/build_vmz.py
```

2. Output file will be created locally at:

- `dist/r2v_nutrition_overhaul.vmz`

3. Drop that `.vmz` into your Road to Vostok mod folder and launch the game for testing.

> Note: `.vmz` is intentionally not committed (Codex branch updates do not support binary files). Build locally before testing.

## Package contents

The `.vmz` includes:

- `manifest.json`
- `payload/` (all files from `mod/`)

## Custom output

```bash
python scripts/build_vmz.py --output dist/my_test_build.vmz --version 0.1.1
```
