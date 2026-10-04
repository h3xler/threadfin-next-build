# Threadfin (upstream: Threadfin/Threadfin) — minimal runtime imajı
# SADECE GitHub Actions'ta build edilir; sunucuda asla build yapılmaz.
# Bu dosya h3xler/threadfin-next-build repo kökünde durur; upstream kaynak
# build sırasında pinli commit'ten klonlanır (fork gerektirmez).
#
# KAYNAK KARARI (2026-10-04, Faz 1): joshua-ivy/threadfin_next silinmiş/private
# yapılmış (GitHub'da yok). Yerine MIT lisanslı upstream Threadfin/Threadfin
# kullanılıyor. Multiplexing (kanal başına 1 upstream) T01 ile ampirik
# doğrulanacak — zane33 fork'unun "1 Request per Tuner" opsiyonu, varsayılan
# davranışın paylaşımlı olduğunu gösteriyor.
#
# İNCELEME NOTU: Threadfin'in dokümante edilmiş env-tabanlı app config'i YOKTUR.
# Config yolu -config flag'i ile verilir (kod-kanıtlı: threadfin.go satır 172,
# flag.String("config", ...)). Bu yüzden CMD'de -config açıkça geçilir.
# Multiplexing kanıtı: upstream README "Proxies a stream to multiple clients"
# (lawrenceeaden fork README, Streaming bölümü) — T01 ile ampirik doğrulanacak.

ARG UPSTREAM_REPO=Threadfin/Threadfin
ARG UPSTREAM_REF=6b9c0ccf16164eb362af0a44660228267734c5aa

# ---- builder: Go 1.25 ile pinli kaynaktan derleme ----
FROM --platform=$BUILDPLATFORM golang:1.25-bookworm AS builder
ARG TARGETARCH
ARG UPSTREAM_REPO
ARG UPSTREAM_REF
RUN apt-get update \
 && apt-get install -y --no-install-recommends git ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone "https://github.com/${UPSTREAM_REPO}.git" . \
 && git checkout "${UPSTREAM_REF}" \
 && git log -1 --format='%H %ad %s' --date=short
# Upstream'in kendi build komutu (README: "go build threadfin.go")
RUN GOOS=linux GOARCH=${TARGETARCH} CGO_ENABLED=0 \
    go build -trimpath -ldflags="-s -w" -o /out/threadfin threadfin.go
# Mimari doğrulama: arm64 beklenir
RUN file /out/threadfin | grep -i "aarch64\|arm64"

# ---- runtime: debian-slim + ffmpeg + threadfin ----
FROM debian:bookworm-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg ca-certificates tzdata procps \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -r -u 1000 -d /home/threadfin -m threadfin
COPY --from=builder /out/threadfin /app/threadfin
RUN mkdir -p /home/threadfin/conf /tmp/threadfin \
 && chown -R threadfin:threadfin /app /home/threadfin /tmp/threadfin
USER threadfin
VOLUME ["/home/threadfin/conf"]
EXPOSE 34400
ENTRYPOINT ["/app/threadfin"]
# -config açıkça verilir (upstream convention: /home/threadfin/conf).
CMD ["-port", "34400", "-bind", "0.0.0.0", "-config", "/home/threadfin/conf"]

# NOT: Container içi otomatik güncelleme, ilk kurulumda Web UI'dan KAPATILIR
# (Settings → Automatic update). Sürüm GH Actions pin'i ile yönetilir.
