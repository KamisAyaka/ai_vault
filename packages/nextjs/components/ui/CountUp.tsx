"use client";

import { useEffect, useRef } from "react";
import gsap from "gsap";

type CountUpProps = {
  value: number;
  format?: (value: number) => string;
  duration?: number;
  className?: string;
};

export const CountUp = ({ value, format, duration = 1.2, className }: CountUpProps) => {
  const spanRef = useRef<HTMLSpanElement | null>(null);
  const previousValue = useRef<number>(value);

  useEffect(() => {
    if (!spanRef.current) return;

    const counter = { current: previousValue.current };
    const ctx = gsap.context(() => {
      gsap.to(counter, {
        current: value,
        duration,
        ease: "power2.out",
        onUpdate: () => {
          if (!spanRef.current) return;
          const formatted = format ? format(counter.current) : Math.round(counter.current).toString();
          spanRef.current.textContent = formatted;
        },
      });
    }, spanRef);

    previousValue.current = value;

    return () => ctx.revert();
  }, [value, duration, format]);

  return (
    <span ref={spanRef} className={className}>
      {format ? format(value) : Math.round(value)}
    </span>
  );
};

export default CountUp;
