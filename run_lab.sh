#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  ./run_lab.sh [1|2|3|4]

Prerequisites:
  - PostgreSQL server is running
  - psql is installed and can connect to your DB

Env (optional):
  DATABASE_URL   Connection string for psql (e.g. postgres://user:pass@localhost:5432/dbname)
  LAB_DB         Database name/connstring passed as last arg to psql (if DATABASE_URL is not set)

Examples:
  ./run_lab.sh 1
  ./run_lab.sh 2
  DATABASE_URL="postgres://postgres:postgres@localhost:5432/db_course" ./run_lab.sh
  LAB_DB=db_course ./run_lab.sh 3
EOF
}

print_connection_help() {
  cat <<'EOF'

Не удалось подключиться к PostgreSQL.

1) Убедись, что сервер PostgreSQL запущен.
   - Homebrew (macOS): `brew services start postgresql@14` (или `brew services start postgresql`)
   - Проверка: `pg_isready` или `psql -d postgres -c "SELECT 1;"`

2) Укажи, куда подключаться:
   - через URL:
       `DATABASE_URL="postgres://user:pass@localhost:5432/db_course" ./run_lab.sh 2`
   - или через переменные окружения:
       `export PGHOST=localhost PGPORT=5432 PGUSER=postgres PGDATABASE=db_course`
       `./run_lab.sh 2`
   - или просто передай имя базы:
       `LAB_DB=db_course ./run_lab.sh 2`

3) Если базы ещё нет — создай её:
   `createdb db_course`
   или
   `psql -d postgres -c "CREATE DATABASE db_course;"`
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "psql не найден в PATH. Установи PostgreSQL client tools и попробуй снова." >&2
  exit 127
fi

lab="${1:-}"
if [[ -z "${lab}" ]]; then
  read -r -p "Какую лабу запустить? (1/2/3/4): " lab
fi

declare -a files=()
case "${lab}" in
  1)
    files=(
      "lab-01/service_centers.sql"
    )
    ;;
  2)
    files=(
      "lab-02/schema.sql"
      "lab-02/seed.sql"
      "lab-02/views.sql"
      "lab-02/dml_examples.sql"
      "lab-02/queries.sql"
    )
    ;;
  3)
    files=(
      "lab-02/schema.sql"
      "lab-02/seed.sql"
      "lab-03/procedures_functions_triggers.sql"
      "lab-03/demo.sql"
    )
    ;;
  4)
    files=(
      "lab-02/schema.sql"
      "lab-02/seed.sql"
      "lab-04/indexes_explain.sql"
      "lab-04/transactions.sql"
    )
    ;;
  *)
    echo "Нужно указать номер лабы: 1, 2, 3 или 4." >&2
    usage
    exit 2
    ;;
esac

declare -a psql_db_arg=()
if [[ -n "${DATABASE_URL:-}" ]]; then
  psql_db_arg=("${DATABASE_URL}")
elif [[ -n "${LAB_DB:-}" ]]; then
  psql_db_arg=("${LAB_DB}")
elif [[ -z "${PGDATABASE:-}" ]]; then
  if [[ -t 0 ]]; then
    _db=""
    read -r -p "В какую базу подключаться? (Enter = postgres): " _db || _db=""
    psql_db_arg=("${_db:-postgres}")
  else
    psql_db_arg=("postgres")
  fi
fi

probe_connection() {
  local -a cmd=(psql -X -v ON_ERROR_STOP=1 -Atqc "SELECT 1;")
  if ((${#psql_db_arg[@]})); then
    cmd+=("${psql_db_arg[@]}")
  fi
  "${cmd[@]}" >/dev/null
}

if ! probe_connection; then
  print_connection_help >&2
  exit 3
fi

run_file() {
  local rel_path="$1"
  local abs_path="${script_dir}/${rel_path}"

  if [[ ! -f "${abs_path}" ]]; then
    echo "Файл не найден: ${rel_path}" >&2
    exit 1
  fi

  echo
  echo "==> ${rel_path}"
  local -a cmd=(psql -v ON_ERROR_STOP=1 -f "${abs_path}")
  if ((${#psql_db_arg[@]})); then
    cmd+=("${psql_db_arg[@]}")
  fi
  "${cmd[@]}"
}

for f in "${files[@]}"; do
  run_file "${f}"
done

if [[ "${lab}" == "4" ]]; then
  cat <<'EOF'

Примечание по ЛР4 (транзакции):
  Скрипт lab-04/transactions.sql создаёт таблицу tx_demo и наполняет её.
  Для воспроизведения аномалий открой 2 сессии psql (T1/T2) и выполняй команды из комментариев.
EOF
fi
