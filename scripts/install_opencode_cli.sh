#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
bin_dir="${root}/.local/bin"

mkdir -p "$bin_dir"

cat > "${bin_dir}/opencode" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "${root}/scripts/opencode_mock_request.py" "\$@"
EOF

chmod +x "${bin_dir}/opencode"

echo "$bin_dir"
