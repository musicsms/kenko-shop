#!/bin/sh
set -eu

schema_file="${1:-supabase/migrations/001_kenko_schema.sql}"
sql="$(tr '\n' ' ' < "$schema_file" | tr '[:upper:]' '[:lower:]')"

require_contains() {
  needle="$1"
  description="$2"

  case "$sql" in
    *"$needle"*) ;;
    *)
      echo "missing: $description" >&2
      exit 1
      ;;
  esac
}

require_not_matching() {
  pattern="$1"
  description="$2"

  if printf '%s\n' "$sql" | grep -Eq "$pattern"; then
    echo "forbidden: $description" >&2
    exit 1
  fi
}

require_contains \
  "revoke all on table public.products, public.product_nutrition_tags, public.product_bundles, public.orders, public.order_items from anon, public;" \
  "explicit table revoke from anon and public"

require_contains \
  "grant select on table public.products, public.product_nutrition_tags, public.product_bundles to anon;" \
  "anon select grants limited to product-facing tables"

require_not_matching \
  "grant (select|insert|update|delete)[^;]* on table [^;]*(public\.orders|public\.order_items)[^;]* to [^;]*anon" \
  "anon direct table grants on orders or order_items"

require_contains "grant execute on function public.create_guest_order" "anon RPC execute grant"
require_contains "gen_random_bytes(8)" "order_code uses at least 8 random bytes"
require_contains "jsonb_array_length(items) > 30" "anonymous checkout item-count cap"
require_contains "too_many_items" "too_many_items exception"
