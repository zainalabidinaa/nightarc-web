#!/usr/bin/env python3
"""
Import Nuvio collections JSON into Supabase.
Wipes all existing collections (CASCADE deletes folders, folder_catalogs, folder_sources)
then re-inserts from the provided JSON file.
"""

import json
import sys
import uuid
import urllib.request
import urllib.error

SUPABASE_URL = "https://hvfsntdyowapjxobtyli.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh2ZnNudGR5b3dhcGp4b2J0eWxpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDE3ODQ5NSwiZXhwIjoyMDk1NzU0NDk1fQ.sB0HwWmcM8c5JQoqNnjvWoM0_Yd7IkXeNcweaGq-CuU"

HEADERS = {
    "apikey": SERVICE_KEY,
    "Authorization": f"Bearer {SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}


def req(method, path, body=None):
    url = f"{SUPABASE_URL}/rest/v1/{path}"
    data = json.dumps(body).encode() if body is not None else None
    r = urllib.request.Request(url, data=data, headers=HEADERS, method=method)
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as e:
        print(f"HTTP {e.code} on {method} {path}: {e.read().decode()}")
        sys.exit(1)


def batch_insert(table, rows, chunk=100):
    for i in range(0, len(rows), chunk):
        req("POST", table, rows[i:i+chunk])


def main(json_path):
    with open(json_path) as f:
        data = json.load(f)

    print(f"Loaded {len(data)} collections from {json_path}")

    # 1. Wipe existing collections (CASCADE handles the rest)
    print("Deleting existing collections…")
    req("DELETE", "collections?id=neq.00000000-0000-0000-0000-000000000000")
    print("  Done.")

    all_folders = []
    all_catalogs = []
    all_sources = []

    for col_idx, col in enumerate(data):
        col_id = str(uuid.uuid4())

        col_row = {
            "id": col_id,
            "name": col["title"],
            "sort_order": col_idx,
            "pin_to_top": col.get("pinToTop", False),
            "view_mode": col.get("viewMode", "FOLLOW_LAYOUT"),
            "show_all_tab": col.get("showAllTab", False),
            "focus_glow_enabled": col.get("focusGlowEnabled", False),
            "backdrop_image": col.get("backdropImageUrl"),
        }
        req("POST", "collections", col_row)
        print(f"[{col_idx+1}/{len(data)}] Collection: {col['title']}")

        for folder_idx, folder in enumerate(col.get("folders", [])):
            folder_id = str(uuid.uuid4())

            folder_row = {
                "id": folder_id,
                "collection_id": col_id,
                "name": folder["title"],
                "sort_order": folder_idx,
                "tile_shape": folder.get("tileShape", "LANDSCAPE"),
                "hide_title": folder.get("hideTitle", False),
                "focus_gif_enabled": folder.get("focusGifEnabled", False),
                "cover_image": folder.get("coverImageUrl") or folder.get("heroBackdropUrl"),
                "hero_backdrop": folder.get("heroBackdropUrl"),
                "focus_gif": folder.get("focusGifUrl"),
                "hero_video_url": folder.get("heroVideoUrl"),
                "title_logo": folder.get("titleLogoUrl"),
            }
            all_folders.append(folder_row)

            # Use catalogSources if present, else fall back to sources-with-addonId
            catalog_sources = folder.get("catalogSources") or [
                s for s in folder.get("sources", []) if s.get("addonId")
            ]
            for s in catalog_sources:
                genre = s.get("genre")
                if genre == "None":
                    genre = None
                all_catalogs.append({
                    "folder_id": folder_id,
                    "catalog_id": s["catalogId"],
                    "media_type": s.get("type", "movie"),
                    "genre": genre,
                })

            # TMDB / Trakt sources (no addonId)
            for s_idx, s in enumerate(folder.get("sources", [])):
                if s.get("addonId"):
                    continue
                filters = s.get("filters")
                all_sources.append({
                    "folder_id": folder_id,
                    "provider": s.get("provider", "tmdb"),
                    "title": s.get("title"),
                    "tmdb_id": str(s["tmdbId"]) if s.get("tmdbId") else None,
                    "media_type": s.get("mediaType") or s.get("type"),
                    "tmdb_source_type": s.get("tmdbSourceType"),
                    "sort_by": s.get("sortBy"),
                    "filters_json": json.dumps(filters) if filters else None,
                    "raw_json": json.dumps(s),
                    "sort_order": s_idx,
                })

    # Batch insert folders first, then child rows
    print(f"Inserting {len(all_folders)} folders…")
    batch_insert("folders", all_folders, chunk=50)

    print(f"Inserting {len(all_catalogs)} folder_catalogs…")
    batch_insert("folder_catalogs", all_catalogs, chunk=100)

    print(f"Inserting {len(all_sources)} folder_sources…")
    batch_insert("folder_sources", all_sources, chunk=100)

    print(f"\nDone! {len(data)} collections, {len(all_folders)} folders, "
          f"{len(all_catalogs)} catalog sources, {len(all_sources)} TMDB sources.")


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else (
        "/Users/zain/Downloads/aiometadata and nuevio collections/"
        "nuvio-collections-profile-2-2026-06-14.json"
    )
    main(path)
