import { useEffect, useState } from 'react';

interface CinematicBackgroundProps {
  backdropUrl: string | null;
}

export function CinematicBackground({ backdropUrl }: CinematicBackgroundProps) {
  const [scrollY, setScrollY] = useState(0);
  const prefersReducedMotion = typeof window !== 'undefined'
    && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  useEffect(() => {
    if (prefersReducedMotion) return;

    let ticking = false;
    const handleScroll = () => {
      if (!ticking) {
        requestAnimationFrame(() => {
          setScrollY(window.scrollY);
          ticking = false;
        });
        ticking = true;
      }
    };
    window.addEventListener('scroll', handleScroll, { passive: true });
    return () => window.removeEventListener('scroll', handleScroll);
  }, [prefersReducedMotion]);

  if (!backdropUrl) {
    return <div className="fixed inset-0 pointer-events-none bg-[#080808]" />;
  }

  const parallaxY = prefersReducedMotion ? 0 : scrollY * 0.15;
  const opacity = Math.max(0, 1 - scrollY / 600);

  return (
    <div className="fixed inset-0 pointer-events-none z-0">
      {/* Dark base */}
      <div className="absolute inset-0 bg-[#080808]" />

      {/* Blurred backdrop */}
      <div
        className="absolute inset-0 opacity-90"
        style={{
          transform: `translateY(${parallaxY}px) scale(1.1)`,
          opacity,
        }}
      >
        <img
          src={backdropUrl}
          alt=""
          className="absolute inset-0 w-full h-[72vh] object-cover object-[center_20%]"
          style={{
            filter: 'blur(30px) saturate(0.28) brightness(0.14)',
          }}
        />
        {/* Mask: visible at top, fades to bg at 72% */}
        <div className="absolute inset-0 bg-gradient-to-b from-transparent via-transparent to-[#080808]"
          style={{
            maskImage: 'linear-gradient(to bottom, black 0%, black 50%, transparent 72%)',
            WebkitMaskImage: 'linear-gradient(to bottom, black 0%, black 50%, transparent 72%)',
          }}
        />
      </div>
    </div>
  );
}
