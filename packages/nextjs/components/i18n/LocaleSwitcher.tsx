"use client";

import { useMemo } from "react";
import { localeLabels, locales, type Locale } from "~~/i18n/config";
import { useI18n } from "~~/services/i18n/I18nProvider";

export const LocaleSwitcher = () => {
  const { locale, setLocale } = useI18n();

  const options = useMemo(() => locales.map(value => ({ value, label: localeLabels[value] })), []);

  const handleChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    const nextLocale = event.target.value as Locale;
    setLocale(nextLocale);
  };

  return (
    <select
      className="select select-bordered select-sm w-32"
      value={locale}
      onChange={handleChange}
      aria-label="Select language"
    >
      {options.map(({ value, label }) => (
        <option key={value} value={value}>
          {label}
        </option>
      ))}
    </select>
  );
};
