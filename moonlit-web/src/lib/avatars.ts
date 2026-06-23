// Profile avatar URLs — ported verbatim from the iOS app
// (Apps/MoonlitApp/Sources/Components/ProfileAvatarView.swift).
//
// Indices 0-4 are existing entries — must never be reordered (profiles store
// avatar_id as an index into this array). New avatars are appended at index 5+.
export const moonlitAvatarURLs: string[] = [
  // ── Existing (indices 0-4) ──────────────────────────────────────────────
  'https://media1.tenor.com/m/BbkxgHGg-EEAAAAC/butcher-billy-butcher.gif',          // 0  Billy Butcher
  'https://i.pinimg.com/originals/29/bd/26/29bd261d201e956588ee777d37d26800.gif',   // 1  Fan Fav
  'https://i.postimg.cc/cLnhTxnr/Rick-Grimes-v2.png',                               // 2  Rick Grimes
  'https://media1.giphy.com/media/v1.Y2lkPTZjMDliOTUycDg5cGFzNm1ydWo2aGZ2Njl4NnZiOHpvdjdsbHdzaTBmcTk2bGZnYyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/1qErVv5GVUac8uqBJU/giphy.gif', // 3 Spider-Man
  'https://media1.tenor.com/m/ZNyte-qzI8QAAAAC/spider-man-drink.gif',               // 4  Spider-Man
  // ── New (indices 5-21) ─────────────────────────────────────────────────
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Walter_White2.webp',               // 5  Walter White
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/dexter-morgan.gif',                // 6  Dexter Morgan
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/doakes-dexter.gif',                // 7  Doakes
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/joker.jpeg',                       // 8  Joker
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/360_dark_knight_0708.jpg',         // 9  Dark Knight
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/butcher.gif',                      // 10 Billy Butcher
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Spider_Man.gif',                   // 11 Spider-Man
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Spider-man_Avatar.gif',            // 12 Spider-Man
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/i-am-groot.webp',                  // 13 Groot
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/grogu-star-wars-profile-avatar.png',  // 14 Grogu
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/mando-star-wars-profile-avatar.png',  // 15 Mando
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/rick_and_morty.gif',               // 16 Rick & Morty
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Leo.gif',                          // 17 Leo
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Profile.gif',                      // 18
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/Scott_No.gif',                     // 19 Scott Pilgrim
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/B6SyssSlTgPXq.webp',               // 20
  'https://hvfsntdyowapjxobtyli.supabase.co/storage/v1/object/public/avatars/375473.jpeg',                      // 21
];

/** Resolve a profile's avatar_id to its image URL, or null when unset/out of range. */
export function avatarUrlForId(id?: number | null): string | null {
  if (id === undefined || id === null) return null;
  if (id < 0 || id >= moonlitAvatarURLs.length) return null;
  return moonlitAvatarURLs[id];
}
