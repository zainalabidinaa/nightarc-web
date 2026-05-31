'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useAuth } from '@/app/AuthProvider';
import { ReactNode } from 'react';

const HomeIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
    <path fillRule="evenodd" d="M9.293 2.293a1 1 0 011.414 0l7 7A1 1 0 0117 11h-1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-3a1 1 0 00-1-1H9a1 1 0 00-1 1v3a1 1 0 01-1 1H5a1 1 0 01-1-1v-6H3a1 1 0 01-.707-1.707l7-7z" clipRule="evenodd" />
  </svg>
);

const SearchIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
    <path fillRule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clipRule="evenodd" />
  </svg>
);

const LibraryIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
    <path d="M7.5 2.75a.75.75 0 00-1.5 0v14.5a.75.75 0 001.5 0V2.75zM3 2.75A.75.75 0 002.25 2v16a.75.75 0 001.5 0V2A.75.75 0 003 2.75zm7 0a.75.75 0 00-1.5 0v14.5a.75.75 0 001.5 0V2.75zM14.5 7a.75.75 0 00-.75.75v8.5a.75.75 0 001.5 0v-8.5A.75.75 0 0014.5 7z" />
  </svg>
);

const SettingsIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
    <path fillRule="evenodd" d="M8.34 1.804A1 1 0 019.32 1h1.36a1 1 0 01.98.804l.295 1.473c.497.144.971.342 1.416.587l1.25-.834a1 1 0 011.262.125l.962.962a1 1 0 01.125 1.262l-.834 1.25c.245.445.443.919.587 1.416l1.473.294a1 1 0 01.804.98v1.361a1 1 0 01-.804.98l-1.473.295a6.95 6.95 0 01-.587 1.416l.834 1.25a1 1 0 01-.125 1.262l-.962.962a1 1 0 01-1.262.125l-1.25-.834a6.953 6.953 0 01-1.416.587l-.294 1.473a1 1 0 01-.98.804H9.32a1 1 0 01-.98-.804l-.295-1.473a6.957 6.957 0 01-1.416-.587l-1.25.834a1 1 0 01-1.262-.125l-.962-.962a1 1 0 01-.125-1.262l.834-1.25a6.957 6.957 0 01-.587-1.416l-1.473-.294A1 1 0 011 10.68V9.32a1 1 0 01.804-.98l1.473-.295c.144-.497.342-.971.587-1.416l-.834-1.25a1 1 0 01.125-1.262l.962-.962A1 1 0 015.38 3.03l1.25.834a6.957 6.957 0 011.416-.587l.294-1.473zM10 13a3 3 0 100-6 3 3 0 000 6z" clipRule="evenodd" />
  </svg>
);

const ShieldIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
    <path fillRule="evenodd" d="M9.661 2.237a.531.531 0 01.678 0 11.947 11.947 0 007.078 2.749.5.5 0 01.479.425c.069.52.104 1.05.104 1.589 0 5.162-3.26 9.563-7.834 11.256a.48.48 0 01-.332 0C5.26 16.563 2 12.162 2 7a11.77 11.77 0 01.104-1.589.5.5 0 01.48-.425 11.947 11.947 0 007.077-2.749zm4.196 5.954a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clipRule="evenodd" />
  </svg>
);

const MoonIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5">
    <path fillRule="evenodd" d="M7.455 2.004a.75.75 0 01.26.77 7 7 0 009.958 7.967.75.75 0 011.067.853A8.5 8.5 0 116.647 1.921a.75.75 0 01.808.083z" clipRule="evenodd" />
  </svg>
);

const navItems = [
  { href: '/home', label: 'Home', Icon: HomeIcon },
  { href: '/search', label: 'Search', Icon: SearchIcon },
  { href: '/library', label: 'Library', Icon: LibraryIcon },
  { href: '/settings', label: 'Settings', Icon: SettingsIcon },
];

const adminItems = [
  { href: '/admin', label: 'Admin', Icon: ShieldIcon },
];

export function Sidebar({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const { currentProfile, signOut, selectProfile } = useAuth();
  const router = useRouter();
  const isAdmin = currentProfile?.role === 'admin';

  return (
    <div className="relative min-h-screen">
      {/* Floating pill navbar */}
      <nav className="fixed top-4 left-4 right-4 z-50 flex items-center gap-2 px-3 py-2 glass-dark rounded-2xl">
        {/* Logo */}
        <Link href="/home" className="flex items-center gap-2 px-2 py-1 mr-2 shrink-0">
          <MoonIcon />
          <span className="text-sm font-semibold tracking-tight text-white">Luna</span>
        </Link>

        {/* Nav links */}
        <div className="flex items-center gap-1 flex-1">
          {navItems.map(({ href, label, Icon }) => (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-sm font-medium transition-all duration-200 ${
                pathname === href
                  ? 'bg-white/10 text-white'
                  : 'text-luna-muted hover:text-white hover:bg-white/5'
              }`}
            >
              <Icon />
              <span className="hidden sm:inline">{label}</span>
            </Link>
          ))}

          {isAdmin && adminItems.map(({ href, label, Icon }) => (
            <Link
              key={href}
              href={href}
              className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-sm font-medium transition-all duration-200 ${
                pathname === href
                  ? 'bg-white/10 text-luna-accent'
                  : 'text-luna-muted hover:text-luna-accent hover:bg-white/5'
              }`}
            >
              <Icon />
              <span className="hidden sm:inline">{label}</span>
            </Link>
          ))}
        </div>

        {/* Profile */}
        {currentProfile && (
          <button
            onClick={() => { selectProfile(null as any); router.push('/profiles'); }}
            className="flex items-center gap-2 pl-2 pr-3 py-1 rounded-xl hover:bg-white/5 transition-colors cursor-pointer shrink-0"
            aria-label="Switch profile"
          >
            <div
              className="w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold shrink-0"
              style={{ backgroundColor: currentProfile.avatar_color || '#c084fc' }}
            >
              {currentProfile.name[0].toUpperCase()}
            </div>
            <span className="text-sm text-luna-muted hidden md:inline">{currentProfile.name}</span>
          </button>
        )}
      </nav>

      {/* Page content */}
      <main className="min-h-screen">
        {children}
      </main>
    </div>
  );
}
