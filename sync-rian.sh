#!/bin/bash
set -e

echo "=== 1. Mengambil update dari repo Rian Yuliawan (upstream) ==="
cd /var/www/html/SIMRS-Maxy-AI-Claim-Intelligence
git fetch upstream main

echo "=== 2. Menggabungkan update Rian ke branch lokal ==="
git merge upstream/main --no-edit -m "merge: pull latest updates from upstream Rian Yuliawan" || {
    echo ""
    echo "[PERHATIAN] Terjadi konflik merge pada file landingPage.html."
    echo "Silakan buka file landingPage.html untuk menyelesaikan baris yang bentrok,"
    echo "lalu jalankan: git commit -am 'resolve merge conflict'"
    exit 1
}

echo "=== 3. Memastikan Clean URLs tetap aktif ==="
python3 -c "
p = '/var/www/html/SIMRS-Maxy-AI-Claim-Intelligence/landingPage.html'
with open(p, 'r', encoding='utf-8') as f:
    c = f.read()
c = c.replace('href=\"claim-intelligence.html', 'href=\"/hospitalclaim/claim-intelligence')
c = c.replace('href=\"simrs-intelligence.html', 'href=\"/hospitalclaim/simrs-intelligence')
c = c.replace('claim-intelligence.html', 'claim-intelligence')
c = c.replace('simrs-intelligence.html', 'simrs-intelligence')
with open(p, 'w', encoding='utf-8') as f:
    f.write(c)
"

if ! git diff --quiet; then
    git commit -am "chore: re-apply clean URLs after upstream merge" || true
fi

echo "=== 4. Push ke repo maxy-hospitalclaim ==="
git push origin main

echo "=== 5. Sinkronkan ke repo maxy.asia (maxy-digital) ==="
TARGET_DIR="/var/www/html/maxy-digital/public/hospitalclaim"
mkdir -p "$TARGET_DIR/simrs-intelligence" "$TARGET_DIR/claim-intelligence"

cp "landingPage.html" "$TARGET_DIR/index.html"
cp "landingPage.html" "$TARGET_DIR/landingPage.html"
cp "Dashboard MAXY AI SIMRS Health Intelligence.html" "$TARGET_DIR/simrs-intelligence.html"
cp "Dashboard MAXY AI SIMRS Health Intelligence.html" "$TARGET_DIR/simrs-intelligence/index.html"
cp "Dashboard MAXY AI Claim Intelligence.html" "$TARGET_DIR/claim-intelligence.html"
cp "Dashboard MAXY AI Claim Intelligence.html" "$TARGET_DIR/claim-intelligence/index.html"

cd /var/www/html/maxy-digital
git add public/hospitalclaim/
if ! git diff --staged --quiet; then
    git commit -m "feat: sync latest hospitalclaim updates from upstream"
    git push origin main
    echo ""
    echo ">>> BERHASIL! Update terbaru sudah dikirim ke Vercel maxy.asia <<<"
    echo ">>> Website akan terupdate otomatis dalam ~30 detik di https://maxy.asia/hospitalclaim/ <<<"
else
    echo ">>> Tidak ada perubahan baru dari repo Rian. Semuanya sudah up-to-date! <<<"
fi
