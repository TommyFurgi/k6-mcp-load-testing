#!/usr/bin/env bash

set -euo pipefail

FORCE_PULL=0
SKIP_MONITORING="${SKIP_MONITORING:-0}"
[[ "$SKIP_MONITORING" == "true" ]] && SKIP_MONITORING=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force-pull) FORCE_PULL=1 ;;
    --skip-monitoring) SKIP_MONITORING=1 ;;
    -h|--help)
      echo "Użycie: $0 [--force-pull] [--skip-monitoring]"
      exit 0
      ;;
    *) echo "Nieznany argument: $1 (użyj --help)"; exit 1 ;;
  esac
  shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

# Kolory (opcjonalnie)
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; YEL=$'\033[33m'; RST=$'\033[0m'
else
  BOLD=; DIM=; GRN=; YEL=; RST=
fi

info()  { echo "${GRN}▶${RST} $*"; }
warn()  { echo "${YEL}!${RST} $*"; }
step()  { echo ""; echo "${BOLD}━━ $* ━━${RST}"; }

die() { echo "Błąd: $*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Brak polecenia „$1” w PATH."
}

docker_image_present() {
  docker image inspect "$1" >/dev/null 2>&1
}

ensure_docker_image() {
  local name="$1"
  local pull_ref="${2:-$1}"
  if [[ "$FORCE_PULL" -eq 1 ]] || ! docker_image_present "$name"; then
    info "Pobieranie obrazu: $pull_ref"
    docker pull "$pull_ref"
  else
    info "Pomijam pull — obraz jest już lokalnie: $name"
  fi
}

minikube_quickpizza_loaded() {
  # Format wyjścia zależy od wersji minikube; szukamy nazwy obrazu + tagu latest.
  if minikube image ls 2>/dev/null | grep -qiE 'quickpizza.*latest'; then
    return 0
  fi
  return 1
}

wait_deploy() {
  local ns_flag=()
  [[ -n "${2:-}" ]] && ns_flag=(-n "$2")
  info "Czekam na deployment/$1 ${ns_flag[*]:+w namespace ${2}}"
  kubectl wait --for=condition=available --timeout=180s deployment/"$1" "${ns_flag[@]}" >/dev/null
}

# --- Weryfikacja narzędzi ----------------------------------------------------
step "Wymagania (docker, minikube, kubectl)"
need_cmd docker
need_cmd minikube
need_cmd kubectl

# --- Obrazy Docker ------------------------------------------------------------
step "Obrazy Docker (warunkowy pull)"
QUICKPIZZA_SRC="ghcr.io/grafana/quickpizza-local:latest"
QUICKPIZZA_LOCAL="quickpizza:latest"
MCP_K6="grafana/mcp-k6:latest"

if [[ "$FORCE_PULL" -eq 1 ]] || ! docker_image_present "$QUICKPIZZA_LOCAL"; then
  ensure_docker_image "$QUICKPIZZA_SRC" "$QUICKPIZZA_SRC"
  info "Tagowanie: $QUICKPIZZA_SRC → $QUICKPIZZA_LOCAL"
  docker tag "$QUICKPIZZA_SRC" "$QUICKPIZZA_LOCAL"
else
  info "Pomijam pull/tagi — $QUICKPIZZA_LOCAL jest już lokalnie"
  if ! docker_image_present "$QUICKPIZZA_SRC" && docker_image_present "$QUICKPIZZA_LOCAL"; then
    warn "Masz tylko tag $QUICKPIZZA_LOCAL (bez $QUICKPIZZA_SRC) — to wystarczy do minikube load."
  fi
fi

ensure_docker_image "$MCP_K6" "$MCP_K6"

# --- Minikube -----------------------------------------------------------------
step "Minikube (start jeśli wyłączony)"
if minikube status >/dev/null 2>&1; then
  info "Minikube już działa — pomijam minikube start"
else
  info "Uruchamianie: minikube start --driver=docker"
  minikube start --driver=docker
fi

# Upewnij się, że kubectl wskazuje na minikube
kubectl config use-context minikube >/dev/null 2>&1 || true

step "Ładowanie obrazu QuickPizza do Minikube"
if minikube_quickpizza_loaded && [[ "$FORCE_PULL" -eq 0 ]]; then
  info "Obraz quickpizza:latest jest już w Minikube — pomijam minikube image load"
else
  info "minikube image load $QUICKPIZZA_LOCAL"
  minikube image load "$QUICKPIZZA_LOCAL"
fi

# --- QuickPizza ---------------------------------------------------------------
step "Deploy QuickPizza (k8s/quickpizza.yaml)"
kubectl apply -f "${REPO_ROOT}/k8s/quickpizza.yaml"
wait_deploy quickpizza

# --- Monitoring ---------------------------------------------------------------
if [[ "${SKIP_MONITORING}" -eq 1 ]]; then
  warn "SKIP_MONITORING=1 — pomijam Prometheus/Grafana"
else
  step "Deploy monitoring (k8s/monitoring.yaml)"
  kubectl apply -f "${REPO_ROOT}/k8s/monitoring.yaml"

  step "ConfigMapy Grafany (datasource, provisioning, dashboard JSON)"
  kubectl create configmap grafana-datasource-config -n monitoring \
    --from-file=datasource.yaml="${REPO_ROOT}/k8s/grafana/provisioning/datasource.yaml" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl create configmap grafana-dashboard-provisioning -n monitoring \
    --from-file=dashboards.yaml="${REPO_ROOT}/k8s/grafana/provisioning/dashboards.yaml" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl create configmap grafana-dashboards -n monitoring \
    --from-file="${REPO_ROOT}/k8s/grafana/dashboards/" \
    --dry-run=client -o yaml | kubectl apply -f -

  step "Restart Grafany (wczytanie ConfigMap)"
  kubectl rollout restart deployment/grafana -n monitoring
  kubectl rollout status deployment/grafana -n monitoring --timeout=180s
  wait_deploy prometheus monitoring
fi

# --- Podsumowanie: URL-e i dane -----------------------------------------------
step "Podsumowanie — przydatne adresy i zmienne"
echo ""
QP_IP="$(minikube ip 2>/dev/null || echo '')"
QP_PORT="$(kubectl get svc quickpizza -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '')"
if [[ -n "$QP_IP" && -n "$QP_PORT" ]]; then
  QP_URL="http://${QP_IP}:${QP_PORT}"
else
  QP_URL=""
fi

if [[ -z "$QP_URL" ]]; then
  warn "Nie udało się odczytać URL przez minikube ip. Sprawdź: minikube status"
else
  echo "  ${BOLD}QuickPizza (BASE_URL dla k6 / LLM):${RST} $QP_URL"
fi

echo "  ${BOLD}Przykładowy prompt (Cursor):${RST}"
echo "    „Uruchom smoke przez k6 MCP: 1 VU, 30s, BASE_URL=$QP_URL — GET / i POST /api/pizza jak w k6-tests/smoke.js.”"
echo ""

if [[ "${SKIP_MONITORING}" -eq 0 ]]; then
  echo "  ${BOLD}Grafana:${RST}        http://$(minikube ip):$(kubectl get svc grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '?')"
  echo "  ${BOLD}Prometheus:${RST}     http://$(minikube ip):$(kubectl get svc prometheus -n monitoring -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo '?')"
  echo "  ${BOLD}Login Grafana:${RST}  admin / admin"
  echo "  ${BOLD}Dashboard:${RST}      Dashboards → folder QuickPizza → „QuickPizza - Load Testing Overview”"
  echo ""
fi

echo "  ${BOLD}MCP k6 (Cursor):${RST}  konfiguracja w ${REPO_ROOT}/.cursor/mcp.json"
echo "                      (docker run … --network=minikube grafana/mcp-k6)"
echo ""

kubectl get pods -l app=quickpizza -o wide 2>/dev/null || true
if [[ "${SKIP_MONITORING}" -eq 0 ]]; then
  kubectl get pods -n monitoring -o wide 2>/dev/null || true
fi

step "Do uruchomienia w OSOBNYCH terminalach (nie blokuje skryptu)"
echo "  ${DIM}Te polecenia otwierają tunele / UI i muszą działać w tle:${RST}"
echo "    minikube service quickpizza"
if [[ "${SKIP_MONITORING}" -eq 0 ]]; then
  echo "    minikube service prometheus -n monitoring"
  echo "    minikube service grafana -n monitoring"
fi
echo ""
echo "  ${DIM}Cursor (LLM + testy k6):${RST} otwórz folder repo w Cursorze; upewnij się, że serwer MCP „k6” jest aktywny, Docker działa."
echo ""

step "Gotowe"
info "Skrypt zakończony. Użyj BASE_URL powyżej do testów k6 (CLI: BASE_URL=... k6 run k6-tests/smoke.js) lub w prompcie do LLM."
