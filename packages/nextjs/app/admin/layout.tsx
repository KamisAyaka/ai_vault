"use client";

import type { ReactNode } from "react";
import Link from "next/link";
import { OwnerOnly } from "~~/components/auth/PermissionGuard";
import { PRIMARY_ADMIN_ADDRESS } from "~~/utils/admin";

type AdminLayoutProps = {
  children: ReactNode;
};

const AdminLayout = ({ children }: AdminLayoutProps) => {
  const adminAddress = PRIMARY_ADMIN_ADDRESS;

  const fallback = (
    <div className="flex min-h-screen flex-1 items-center justify-center px-4">
      <div className="max-w-md rounded-lg border border-[#803100]/40 bg-black/70 p-8 text-center text-[#fbe6dc] shadow-lg backdrop-blur">
        <h2 className="text-2xl font-semibold text-white">需要管理员权限</h2>
        {adminAddress ? (
          <p className="mt-3 text-sm leading-relaxed opacity-80">
            当前连接的钱包没有访问管理后台的权限。请使用管理员钱包地址
            <span className="ml-1 font-mono text-xs text-white">{adminAddress}</span>
            重新连接。
          </p>
        ) : (
          <p className="mt-3 text-sm leading-relaxed opacity-80">
            当前连接的钱包没有访问管理后台的权限，且管理员地址尚未在环境变量中配置。请联系系统管理员。
          </p>
        )}
        <div className="mt-6 flex flex-col gap-2 text-sm">
          <Link href="/" className="btn btn-sm bg-[#803100] text-white hover:bg-[#803100]/80 border-none">
            返回首页
          </Link>
          <p className="opacity-60">或断开钱包后使用管理员地址登录。</p>
        </div>
      </div>
    </div>
  );

  return <OwnerOnly fallback={fallback}>{children}</OwnerOnly>;
};

export default AdminLayout;
