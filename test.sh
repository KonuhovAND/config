#!/usr/bin/env bash

# ==============================================================================
# Comprehensive CS/ML Availability, Latency & 100MB Speed Test Tool
# ==============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

TIMEOUT=4
PROXY="${1:-}"

# Configure proxy flags for curl
CURL_PROXY_ARGS=()
if [ -n "$PROXY" ]; then
    CURL_PROXY_ARGS+=("--proxy" "$PROXY")
    PROXY_LABEL="Proxy ($PROXY)"
else
    PROXY_LABEL="Direct Connection (No Proxy)"
fi

echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}${CYAN}  CS & ML SERVICES AVAILABILITY, LATENCY & SPEED TEST${NC}"
echo -e "  Mode: ${YELLOW}${PROXY_LABEL}${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}\n"

# ------------------------------------------------------------------------------
# 1. AVAILABILITY & LATENCY CHECK (30+ SERVICES)
# ------------------------------------------------------------------------------
SERVICES=(
    # AI & Machine Learning
    "Hugging Face Hub|https://huggingface.co"
    "OpenAI API|https://api.openai.com"
    "Anthropic (Claude API)|https://api.anthropic.com"
    "DeepSeek API|https://api.deepseek.com"
    "Kaggle|https://www.kaggle.com"
    "Weights & Biases (wandb)|https://wandb.ai"
    "Google Colab|https://colab.research.google.com"
    "Replicate|https://replicate.com"

    # Python & Developer Package Indexes (Fast Install Sources)
    "PyPI (pip index)|https://pypi.org"
    "PyTorch Wheels Index|https://download.pytorch.org"
    "TensorFlow Domain|https://www.tensorflow.org"
    "Anaconda Repositories|https://repo.anaconda.com"
    "npm Registry (Node.js)|https://registry.npmjs.org"
    "Crates.io (Rust Cargo)|https://crates.io"
    "Maven Central (Java/Kotlin)|https://repo1.maven.org"
    "NVIDIA CUDA Repositories|https://developer.download.nvidia.com"

    # Code Hosting & Container Registries
    "GitHub|https://github.com"
    "GitLab|https://gitlab.com"
    "Docker Hub|https://hub.docker.com"

    # CS University & Academic Tools
    "Overleaf (LaTeX)|https://www.overleaf.com"
    "ArXiv Papers|https://arxiv.org"
    "Stack Overflow|https://stackoverflow.com"
    "Notion|https://www.notion.so"
    "LeetCode|https://leetcode.com"
    "Google Drive / Colab Storage|https://drive.google.com"

    # Infrastructure & Messaging
    "Discord|https://discord.com"
    "Telegram API|https://api.telegram.org"
    "Cloudflare DNS/CDN|https://1.1.1.1"
    "AWS Management Console|https://aws.amazon.com"
)

echo -e "${BOLD}${BLUE}--- [1/3] SERVICE AVAILABILITY & LATENCY CHECK ---${NC}"
printf "%-34s | %-14s | %-10s | %s\n" "Service Name" "Status" "Latency" "HTTP"
echo "----------------------------------------------------------------------"

for item in "${SERVICES[@]}"; do
    NAME="${item%%|*}"
    URL="${item##*|}"

    # Curl return format: HTTP_CODE|TOTAL_TIME
    RESPONSE=$(curl "${CURL_PROXY_ARGS[@]}" -s -o /dev/null -w "%{http_code}|%{time_total}" --connect-timeout "$TIMEOUT" -L "$URL" 2>/dev/null)
    
    HTTP_CODE=$(echo "$RESPONSE" | cut -d'|' -f1)
    TIME_TOTAL=$(echo "$RESPONSE" | cut -d'|' -f2)

    if [ -n "$TIME_TOTAL" ] && [ "$TIME_TOTAL" != "0.000000" ]; then
        LATENCY_MS=$(awk -v t="$TIME_TOTAL" 'BEGIN {printf "%.0f ms", t*1000}')
    else
        LATENCY_MS="---"
    fi

    if [[ "$HTTP_CODE" =~ ^[23] ]]; then
        printf "%-34s | ${GREEN}%-14s${NC} | %-10s | %s\n" "$NAME" "[ AVAILABLE ]" "$LATENCY_MS" "$HTTP_CODE"
    elif [[ "$HTTP_CODE" =~ ^[45] ]]; then
        printf "%-34s | ${YELLOW}%-14s${NC} | %-10s | %s\n" "$NAME" "[ BLOCKED/ERR ]" "$LATENCY_MS" "$HTTP_CODE"
    else
        printf "%-34s | ${RED}%-14s${NC} | %-10s | %s\n" "$NAME" "[ UNREACHABLE ]" "$LATENCY_MS" "Timeout"
    fi
done

# ------------------------------------------------------------------------------
# 2. FAST INSTALL / PACKAGE MIRROR SPEED TESTS (10MB Downloads)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}--- [2/3] PACKAGE REPO DOWNLOAD SPEED TESTS (Fast Install Check) ---${NC}"
printf "%-34s | %s\n" "Registry / CDN Source" "Download Speed"
echo "----------------------------------------------------------------------"

# Test endpoints for real package/asset downloads
PKG_TESTS=(
    "PyPI Package Download (pip)|https://files.pythonhosted.org/packages/70/8e/0e2d8470a3bcc12ef4927f874d19f85253ea1a128e708fa0803264223f03/numpy-1.26.4.tar.gz"
    "Hugging Face Model File|https://huggingface.co/bert-base-uncased/resolve/main/tokenizer.json"
    "PyTorch Wheel Index|https://download.pytorch.org/whl/cpu/torch-2.0.0%2Bcpu-cp310-cp310-linux_x86_64.whl"
    "npm Package Archive|https://registry.npmjs.org/express/-/express-4.18.2.tgz"
    "GitHub Raw Asset|https://raw.githubusercontent.com/torvalds/linux/master/README"
)

test_download_speed() {
    local label="$1"
    local url="$2"
    
    # Download payload for up to 6 seconds and report speed
    SPEED_BYTES=$(curl "${CURL_PROXY_ARGS[@]}" -s -o /dev/null -w "%{speed_download}" --max-time 6 -L "$url" 2>/dev/null)
    
    if [ -n "$SPEED_BYTES" ] && [ "$SPEED_BYTES" != "0" ]; then
        SPEED_MB=$(awk -v b="$SPEED_BYTES" 'BEGIN {printf "%.2f MB/s (%.1f Mbit/s)", b/1048576, (b*8)/1000000}')
        printf "%-34s | ${GREEN}%s${NC}\n" "$label" "$SPEED_MB"
    else
        printf "%-34s | ${RED}%s${NC}\n" "$label" "Download Failed / Blocked"
    fi
}

for pkg in "${PKG_TESTS[@]}"; do
    NAME="${pkg%%|*}"
    URL="${pkg##*|}"
    test_download_speed "$NAME" "$URL"
done

# ------------------------------------------------------------------------------
# 3. FULL 100MB BANDWIDTH BENCHMARK (Download & Upload)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${BLUE}--- [3/3] FULL 100MB TUNNEL BANDWIDTH BENCHMARK ---${NC}"

# 100MB Download Test
echo -n "Running 100MB Fast Download Test... "
DOWN_BYTES=$(curl "${CURL_PROXY_ARGS[@]}" -s -o /dev/null -w "%{speed_download}" --max-time 35 -L "https://speed.cloudflare.com/__down?bytes=100000000" 2>/dev/null)

if [ -n "$DOWN_BYTES" ] && [ "$DOWN_BYTES" != "0" ]; then
    DOWN_MB=$(awk -v b="$DOWN_BYTES" 'BEGIN {printf "%.2f MB/s (%.2f Mbit/s)", b/1048576, (b*8)/1000000}')
    echo -e "${GREEN}${DOWN_MB}${NC}"
else
    echo -e "${RED}Failed${NC}"
fi

# 100MB Upload Test
echo -n "Running 100MB Fast Upload Test...   "
UPLOAD_BYTES=$(dd if=/dev/zero bs=1M count=100 2>/dev/null | curl "${CURL_PROXY_ARGS[@]}" -s -o /dev/null -w "%{speed_upload}" --max-time 35 -X POST -H "Content-Type: application/octet-stream" --data-binary @- "https://speed.cloudflare.com/__up" 2>/dev/null)

if [ -n "$UPLOAD_BYTES" ] && [ "$UPLOAD_BYTES" != "0" ]; then
    UP_MB=$(awk -v b="$UPLOAD_BYTES" 'BEGIN {printf "%.2f MB/s (%.2f Mbit/s)", b/1048576, (b*8)/1000000}')
    echo -e "${GREEN}${UP_MB}${NC}"
else
    echo -e "${RED}Failed${NC}"
fi

echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
echo -e "  Test Completed successfully!"
echo -e "${BOLD}${CYAN}======================================================================${NC}\n"
