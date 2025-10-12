"use client";

import { useRef } from "react";
import Link from "next/link";
import { AdapterManager } from "~~/components/admin/AdapterManager";
import { useGsapFadeReveal, useGsapHeroIntro } from "~~/hooks/useGsapAnimations";
import { useTranslations } from "~~/services/i18n/I18nProvider";

const AdaptersPage = () => {
  const tPage = useTranslations("admin.adaptersPage");
  const tMenu = useTranslations("menu");

  const heroRef = useRef<HTMLDivElement | null>(null);
  const infoRef = useRef<HTMLDivElement | null>(null);
  const managerRef = useRef<HTMLDivElement | null>(null);

  useGsapHeroIntro(heroRef);
  useGsapFadeReveal(infoRef, ".adapters-info-line");
  useGsapFadeReveal(managerRef, ".adapters-manager-card");

  return (
    <div className="relative flex grow flex-col items-center">
      <div className="container mx-auto w-full px-4 py-8">
        {/* Header */}
        <div className="flex justify-between items-center mb-8" ref={heroRef}>
          <div>
            <h1 className="hero-heading text-4xl font-bold mb-2 text-white">{tPage("title")}</h1>
            <div className="hero-subheading text-sm breadcrumbs">
              <ul>
                <li>
                  <Link href="/" className="text-[#fbe6dc] hover:text-white">
                    {tPage("breadcrumb.home", tMenu("home"))}
                  </Link>
                </li>
                <li>
                  <Link href="/admin/vaults" className="text-[#fbe6dc] hover:text-white">
                    {tPage("breadcrumb.admin", tMenu("admin"))}
                  </Link>
                </li>
                <li className="text-white">{tPage("breadcrumb.current")}</li>
              </ul>
            </div>
          </div>
          <div className="hero-cta badge badge-lg bg-[#803100] hover:bg-[#803100]/80 border-[#803100]/30 text-white">
            {tPage("badge")}
          </div>
        </div>

        {/* Description */}
        <div className="bg-black/60 backdrop-blur-sm border border-[#803100]/30 rounded-lg p-4 mb-8" ref={infoRef}>
          <div className="flex gap-4 adapters-info-line">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              className="stroke-[#fbe6dc] shrink-0 w-6 h-6"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
              ></path>
            </svg>
            <div>
              <h3 className="font-bold text-white">{tPage("descriptionTitle")}</h3>
              <div className="text-sm text-[#fbe6dc]">{tPage("descriptionBody")}</div>
            </div>
          </div>
        </div>

        {/* Adapter Manager Component */}
        <div ref={managerRef}>
          <div className="adapters-manager-card">
            <AdapterManager />
          </div>
        </div>
      </div>
    </div>
  );
};

export default AdaptersPage;
