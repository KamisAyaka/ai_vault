"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import enMessages from "~~/i18n/messages/en.json";
import zhCnMessages from "~~/i18n/messages/zh-CN.json";
import { defaultLocale, localeLabels, locales, type Locale } from "~~/i18n/config";

type Messages = typeof enMessages;

type MessageDictionary = Record<Locale, Messages>;

const messagesMap: MessageDictionary = {
  en: enMessages,
  "zh-CN": zhCnMessages,
};

type I18nContextValue = {
  locale: Locale;
  setLocale: (nextLocale: Locale) => void;
  t: (key: string, defaultMessage?: string) => string;
  messages: Messages;
  locales: readonly Locale[];
  labels: typeof localeLabels;
};

const I18nContext = createContext<I18nContextValue | null>(null);

const STORAGE_KEY = "ai-vault.locale";

const traverse = (dictionary: Record<string, any>, key: string) => {
  return key.split(".").reduce((acc, segment) => {
    if (acc && typeof acc === "object" && segment in acc) {
      return acc[segment];
    }
    return undefined;
  }, dictionary as unknown as Record<string, any>);
};

export const I18nProvider = ({ children }: { children: React.ReactNode }) => {
  const [locale, setLocale] = useState<Locale>(defaultLocale);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const storedLocale = window.localStorage.getItem(STORAGE_KEY) as Locale | null;
    if (storedLocale && locales.includes(storedLocale)) {
      setLocale(storedLocale);
    }
  }, []);

  useEffect(() => {
    if (typeof window === "undefined") return;
    window.localStorage.setItem(STORAGE_KEY, locale);
    window.document.documentElement.lang = locale;
  }, [locale]);

  const messages = useMemo(() => messagesMap[locale] ?? messagesMap[defaultLocale], [locale]);

  const translate = useCallback(
    (key: string, defaultMessage?: string) => {
      const result = traverse(messages, key);
      if (typeof result === "string") {
        return result;
      }
      return defaultMessage ?? key;
    },
    [messages],
  );

  const value = useMemo<I18nContextValue>(
    () => ({
      locale,
      setLocale: nextLocale => {
        if (locales.includes(nextLocale)) {
          setLocale(nextLocale);
        }
      },
      t: translate,
      messages,
      locales,
      labels: localeLabels,
    }),
    [locale, messages, translate],
  );

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
};

export const useI18n = () => {
  const ctx = useContext(I18nContext);
  if (!ctx) {
    throw new Error("useI18n must be used within I18nProvider");
  }
  return ctx;
};

export const useTranslations = (prefix?: string) => {
  const { t } = useI18n();
  return useCallback(
    (key: string, defaultMessage?: string) => t(prefix ? `${prefix}.${key}` : key, defaultMessage),
    [prefix, t],
  );
};
