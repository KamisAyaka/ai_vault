"use client";

import React, { useMemo, useRef } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { hardhat } from "viem/chains";
import { Bars3Icon } from "@heroicons/react/24/outline";
import { LocaleSwitcher } from "~~/components/i18n/LocaleSwitcher";
import { FaucetButton, RainbowKitCustomConnectButton } from "~~/components/scaffold-eth";
import { useOutsideClick, useTargetNetwork } from "~~/hooks/scaffold-eth";
import { useUserRole } from "~~/hooks/useUserRole";
import { useTranslations } from "~~/services/i18n/I18nProvider";

type HeaderMenuLink = {
  labelKey: string;
  href: string;
  icon?: React.ReactNode;
  ownerOnly?: boolean;
};

export const menuLinks: HeaderMenuLink[] = [
  { labelKey: "menu.vaults", href: "/vaults" },
  { labelKey: "menu.analytics", href: "/analytics" },
  { labelKey: "menu.portfolio", href: "/portfolio" },
  { labelKey: "menu.admin", href: "/admin/vaults", ownerOnly: true },
  { labelKey: "menu.strategies", href: "/admin/strategies", ownerOnly: true },
  { labelKey: "menu.adapters", href: "/admin/adapters", ownerOnly: true },
  { labelKey: "menu.batch", href: "/admin/vaults/batch", ownerOnly: true },
  { labelKey: "menu.debug", href: "/debug" },
];

export const HeaderMenuLinks = () => {
  const pathname = usePathname();
  const { role } = useUserRole();
  const t = useTranslations();

  const filteredLinks = useMemo(
    () =>
      menuLinks.filter(link => {
        if (link.ownerOnly && role !== "owner") {
          return false;
        }
        return true;
      }),
    [role],
  );

  return (
    <>
      {filteredLinks.map(({ labelKey, href, icon }) => {
        const isActive = pathname === href;
        const label = t(labelKey, labelKey);
        return (
          <li key={href}>
            <Link
              href={href}
              className={`${
                isActive ? "bg-[#803100] text-white shadow-md" : "text-[#fbe6dc]"
              } hover:bg-[#803100]/80 hover:text-white hover:shadow-md focus:!bg-[#803100] focus:!text-white active:!text-white py-1.5 px-3 text-sm rounded-full gap-2 grid grid-flow-col`}
            >
              {icon}
              <span>{label}</span>
            </Link>
          </li>
        );
      })}
    </>
  );
};

export const Header = () => {
  const { targetNetwork } = useTargetNetwork();
  const isLocalNetwork = targetNetwork.id === hardhat.id;

  const burgerMenuRef = useRef<HTMLDetailsElement>(null);
  useOutsideClick(burgerMenuRef, () => {
    burgerMenuRef?.current?.removeAttribute("open");
  });

  return (
    <div className="sticky lg:static top-0 navbar bg-transparent backdrop-blur-md min-h-0 shrink-0 justify-between z-20 border-b border-[#803100]/20 px-0 sm:px-2">
      <div className="navbar-start w-auto lg:w-1/2">
        <details className="dropdown" ref={burgerMenuRef}>
          <summary className="ml-1 btn btn-ghost lg:hidden hover:bg-[#803100]/20 text-[#fbe6dc]">
            <Bars3Icon className="h-1/2" />
          </summary>
          <ul
            className="menu menu-compact dropdown-content mt-3 p-2 shadow-sm bg-black/90 backdrop-blur-md border border-[#803100]/30 rounded-box w-52"
            onClick={() => {
              burgerMenuRef?.current?.removeAttribute("open");
            }}
          >
            <HeaderMenuLinks />
          </ul>
        </details>
        <Link href="/" className="hidden lg:flex items-center gap-2 ml-4 mr-6 shrink-0">
          <div className="flex flex-col">
            <span className="text-2xl font-bold leading-tight text-white tracking-wide">AI Vault Protocol</span>
            <span className="text-xs uppercase tracking-[0.25em] text-[#fbe6dc]/80">Automated DeFi Management</span>
          </div>
        </Link>
        <ul className="hidden lg:flex lg:flex-nowrap menu menu-horizontal px-1 gap-2">
          <HeaderMenuLinks />
        </ul>
      </div>
      <div className="navbar-end grow mr-4 flex items-center gap-2">
        <RainbowKitCustomConnectButton />
        {isLocalNetwork && <FaucetButton />}
        <div className="hidden sm:block">
          <LocaleSwitcher />
        </div>
      </div>
    </div>
  );
};
