"use client";

import { RefObject, useEffect } from "react";
import gsap from "gsap";

type StaggerOptions = {
  selector: string;
  from?: gsap.TweenVars;
  to?: gsap.TweenVars;
  deps?: any[];
};

export const useGsapHeroIntro = (containerRef: RefObject<HTMLElement | null>, deps: any[] = []) => {
  useEffect(() => {
    if (!containerRef.current) return;

    const ctx = gsap.context(() => {
      gsap.from(".hero-heading", { y: 60, opacity: 0, duration: 0.8, ease: "power3.out" });
      gsap.from(".hero-subheading", {
        y: 40,
        opacity: 0,
        duration: 0.8,
        ease: "power3.out",
        stagger: 0.15,
        delay: 0.15,
      });
      gsap.from(".hero-cta", {
        opacity: 0,
        y: 30,
        duration: 0.6,
        ease: "power2.out",
        delay: 0.35,
        stagger: 0.1,
      });
    }, containerRef);

    return () => ctx.revert();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [containerRef, ...deps]);
};

export const useGsapStaggerReveal = (
  containerRef: RefObject<HTMLElement | null>,
  { selector, from, to, deps = [] }: StaggerOptions,
) => {
  useEffect(() => {
    if (!containerRef.current) return;
    const ctx = gsap.context(() => {
      gsap.fromTo(
        selector,
        { y: 32, opacity: 0, ...from },
        {
          y: 0,
          opacity: 1,
          duration: 0.6,
          ease: "power2.out",
          stagger: 0.1,
          ...to,
        },
      );
    }, containerRef);

    return () => ctx.revert();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
};

export const useGsapFadeReveal = (
  containerRef: RefObject<HTMLElement | null>,
  selector: string,
  deps: any[] = [],
  vars: gsap.TweenVars = {},
) => {
  useEffect(() => {
    if (!containerRef.current) return;
    const ctx = gsap.context(() => {
      gsap.from(selector, {
        opacity: 0,
        y: 24,
        duration: 0.6,
        ease: "power2.out",
        stagger: 0.08,
        ...vars,
      });
    }, containerRef);

    return () => ctx.revert();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, deps);
};
