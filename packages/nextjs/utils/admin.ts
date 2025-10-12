const splitAddressesRaw = (value?: string | null) => {
  if (!value) return [];

  return value
    .split(/[,\s]+/)
    .map(address => address.trim())
    .filter(Boolean);
};

const NORMALIZE = (address: string) => address.toLowerCase();

const defaultAdminAddressesRaw = splitAddressesRaw(process.env.NEXT_PUBLIC_DEFAULT_ADMIN_ADDRESS);
const extraAdminAddressesRaw = splitAddressesRaw(process.env.NEXT_PUBLIC_ADMIN_ADDRESSES);

const normalizedDefaultAdmins = defaultAdminAddressesRaw.map(NORMALIZE);
const normalizedExtraAdmins = extraAdminAddressesRaw.map(NORMALIZE);

const adminAddressSet = new Set<string>([...normalizedDefaultAdmins, ...normalizedExtraAdmins]);

export const ADMIN_ADDRESSES = Array.from(adminAddressSet);

export const PRIMARY_ADMIN_ADDRESS = defaultAdminAddressesRaw[0] ?? extraAdminAddressesRaw[0] ?? "";
