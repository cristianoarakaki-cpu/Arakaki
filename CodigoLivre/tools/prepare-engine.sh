#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Revisão fixa do motor; nenhuma atualização automática.
pin=$(cat ENGINE_REVISION)
mkdir -p third_party
if [ ! -d third_party/llama.cpp/.git ]; then
  git clone --no-checkout --filter=blob:none https://github.com/ggml-org/llama.cpp.git third_party/llama.cpp
fi
git -C third_party/llama.cpp checkout --detach "$pin"
test "$(git -C third_party/llama.cpp rev-parse HEAD)" = "$pin"
