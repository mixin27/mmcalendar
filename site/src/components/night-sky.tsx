import { cn } from "@/lib/utils";

/** Deterministic star positions, so server and client render the same sky. */
function stars(count: number, seed: number) {
  let state = seed;
  const next = () => {
    state = (state * 1103515245 + 12345) % 2147483648;
    return state / 2147483648;
  };
  return Array.from({ length: count }, () => ({
    left: `${(next() * 100).toFixed(1)}%`,
    top: `${(next() * 100).toFixed(1)}%`,
    size: next() > 0.7 ? 3 : 2,
    delay: `${(next() * 4).toFixed(1)}s`,
  }));
}

export function Stars({ count = 20, seed = 7 }: { count?: number; seed?: number }) {
  return (
    <div aria-hidden="true" className="pointer-events-none absolute inset-0">
      {stars(count, seed).map((star, index) => (
        <span
          key={index}
          className="star absolute rounded-full bg-gold"
          style={{
            left: star.left,
            top: star.top,
            width: star.size,
            height: star.size,
            animationDelay: star.delay,
          }}
        />
      ))}
    </div>
  );
}

export function Moon({ className }: { className?: string }) {
  return <div aria-hidden="true" className={cn("moon", className)} />;
}
