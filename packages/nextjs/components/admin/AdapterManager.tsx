"use client";

import { useEffect, useMemo, useState } from "react";
import { usePublicClient } from "wagmi";
import { useScaffoldReadContract, useScaffoldWriteContract } from "~~/hooks/scaffold-eth";
import { useDeployedContractInfo } from "~~/hooks/scaffold-eth";
import { notification } from "~~/utils/scaffold-eth";
import { useTranslations } from "~~/services/i18n/I18nProvider";

const INITIAL_PARTIAL_STATE = {
  token: "",
  counterPartyToken: "",
  slippageTolerance: "",
  feeTier: "",
  tickLower: "",
  tickUpper: "",
  vaultAddress: "",
};

const isValidAddress = (value: string) => /^0x[a-fA-F0-9]{40}$/.test(value.trim());

const formatAddress = (address: string) => `${address.slice(0, 6)}…${address.slice(-4)}`;

export const AdapterManager = () => {
  const [newAdapterAddress, setNewAdapterAddress] = useState("");
  const [isAdding, setIsAdding] = useState(false);

  const [aaveConfig, setAaveConfig] = useState({ token: "", vault: "" });
  const [isSubmittingAave, setIsSubmittingAave] = useState(false);

  const [uniswapV2Config, setUniswapV2Config] = useState({
    token: "",
    counterPartyToken: "",
    slippageTolerance: "",
    vault: "",
  });
  const [isSubmittingV2, setIsSubmittingV2] = useState(false);

  const [uniswapV3Config, setUniswapV3Config] = useState(INITIAL_PARTIAL_STATE);
  const [isSubmittingV3, setIsSubmittingV3] = useState(false);
  const [adapterMeta, setAdapterMeta] = useState<Record<string, { name: string; approved: boolean }>>({});

  const { data: adapterAddressesData, refetch } = useScaffoldReadContract({
    contractName: "AIAgentVaultManager",
    functionName: "getAllAdapters",
    query: {
      enabled: true,
    },
  });

  const publicClient = usePublicClient();
  const { data: managerInfo } = useDeployedContractInfo({ contractName: "AIAgentVaultManager" });

  const { writeContractAsync: addAdapterAsync } = useScaffoldWriteContract({ contractName: "AIAgentVaultManager" });
  const { writeContractAsync: setTokenVaultAsync } = useScaffoldWriteContract({ contractName: "AaveAdapter" });
  const { writeContractAsync: setUniswapV2ConfigAsync } = useScaffoldWriteContract({
    contractName: "UniswapV2Adapter",
  });
  const { writeContractAsync: setUniswapV3ConfigAsync } = useScaffoldWriteContract({
    contractName: "UniswapV3Adapter",
  });

  const registeredAdapters = useMemo(() => {
    if (!Array.isArray(adapterAddressesData)) return [] as string[];
    return (adapterAddressesData as string[]).map(address => address.toLowerCase());
  }, [adapterAddressesData]);

  const t = useTranslations("admin.adapterManager");

  useEffect(() => {
    let cancelled = false;

    const fetchMetadata = async () => {
      if (!publicClient || !managerInfo || registeredAdapters.length === 0) {
        setAdapterMeta({});
        return;
      }

      try {
        const metadataEntries = await Promise.all(
          registeredAdapters.map(async adapter => {
            const approved = await publicClient
              .readContract({
                address: managerInfo.address as `0x${string}`,
                abi: managerInfo.abi as any,
                functionName: "isAdapterApproved",
                args: [adapter as `0x${string}`],
              })
              .catch(() => true);

            const name = await publicClient
              .readContract({
                address: adapter as `0x${string}`,
                abi: [
                  {
                    type: "function",
                    name: "getName",
                    stateMutability: "view",
                    inputs: [],
                    outputs: [{ type: "string" }],
                  },
                ] as const,
                functionName: "getName",
              })
              .catch(() => "Unknown Adapter");

            return [adapter, { approved: Boolean(approved), name: String(name) }] as const;
          }),
        );

        if (!cancelled) {
          setAdapterMeta(Object.fromEntries(metadataEntries));
        }
      } catch (err) {
        console.error("Failed to load adapter metadata", err);
      }
    };

    fetchMetadata();

    return () => {
      cancelled = true;
    };
  }, [publicClient, managerInfo, registeredAdapters]);

  const handleAddAdapter = async () => {
    if (!newAdapterAddress.trim()) {
      notification.error(t("notifications.addressRequired"));
      return;
    }

    if (!isValidAddress(newAdapterAddress)) {
      notification.error(t("notifications.addressInvalid"));
      return;
    }

    setIsAdding(true);
    try {
      await addAdapterAsync(
        {
          functionName: "addAdapter",
          args: [newAdapterAddress.trim() as `0x${string}`],
        },
        {
          onBlockConfirmation: () => {
            notification.success(t("notifications.addSuccess"));
            setNewAdapterAddress("");
            refetch();
          },
        },
      );
    } catch (error: any) {
      console.error("Add adapter failed:", error);
      notification.error(error?.message || t("notifications.addFailed"));
    } finally {
      setIsAdding(false);
    }
  };

  const handleSetTokenVault = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    if (!isValidAddress(aaveConfig.token) || !isValidAddress(aaveConfig.vault)) {
      notification.error(t("notifications.tokenVaultInvalid"));
      return;
    }

    setIsSubmittingAave(true);
    try {
      await setTokenVaultAsync(
        {
          functionName: "setTokenVault",
          args: [aaveConfig.token as `0x${string}`, aaveConfig.vault as `0x${string}`],
        },
        {
          onBlockConfirmation: () => {
            notification.success(t("notifications.aaveUpdated"));
            setAaveConfig({ token: "", vault: "" });
          },
        },
      );
    } catch (error: any) {
      console.error("Set token vault failed:", error);
      notification.error(error?.message || t("notifications.configFailed"));
    } finally {
      setIsSubmittingAave(false);
    }
  };

  const handleSetUniswapV2Config = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    const { token, counterPartyToken, slippageTolerance, vault } = uniswapV2Config;

    if (!isValidAddress(token) || !isValidAddress(counterPartyToken) || !isValidAddress(vault)) {
      notification.error(t("notifications.addressesInvalid"));
      return;
    }

    if (!slippageTolerance.trim()) {
      notification.error(t("notifications.slippageRequired"));
      return;
    }

    let slippageValue: bigint;
    const slippageNumber = Number(slippageTolerance);
    if (!Number.isFinite(slippageNumber) || slippageNumber < 0) {
      notification.error(t("notifications.slippageInvalid"));
      return;
    }
    try {
      slippageValue = BigInt(Math.floor(slippageNumber));
    } catch {
      notification.error(t("notifications.slippageInvalid"));
      return;
    }

    setIsSubmittingV2(true);
    try {
      await setUniswapV2ConfigAsync(
        {
          functionName: "setTokenConfig",
          args: [token as `0x${string}`, slippageValue, counterPartyToken as `0x${string}`, vault as `0x${string}`],
        },
        {
          onBlockConfirmation: () => {
            notification.success(t("notifications.uniswapV2Updated"));
            setUniswapV2Config({ token: "", counterPartyToken: "", slippageTolerance: "", vault: "" });
          },
        },
      );
    } catch (error: any) {
      console.error("Set Uniswap V2 config failed:", error);
      notification.error(error?.message || t("notifications.configFailed"));
    } finally {
      setIsSubmittingV2(false);
    }
  };

  const handleSetUniswapV3Config = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();

    const { token, counterPartyToken, slippageTolerance, feeTier, tickLower, tickUpper, vaultAddress } =
      uniswapV3Config;

    if (!isValidAddress(token) || !isValidAddress(counterPartyToken) || !isValidAddress(vaultAddress)) {
      notification.error(t("notifications.addressesInvalid"));
      return;
    }

    if (!slippageTolerance.trim()) {
      notification.error(t("notifications.slippageRequired"));
      return;
    }

    let slippageValue: bigint;
    let feeTierValue: number;
    let tickLowerValue: number;
    let tickUpperValue: number;

    const slippageNumberV3 = Number(slippageTolerance);
    if (!Number.isFinite(slippageNumberV3) || slippageNumberV3 < 0) {
      notification.error(t("notifications.slippageInvalid"));
      return;
    }

    try {
      slippageValue = BigInt(Math.floor(slippageNumberV3));
      feeTierValue = Number(feeTier || 0);
      tickLowerValue = Number(tickLower || 0);
      tickUpperValue = Number(tickUpper || 0);
    } catch {
      notification.error(t("notifications.numberInvalid"));
      return;
    }

    if (!Number.isFinite(feeTierValue) || !Number.isFinite(tickLowerValue) || !Number.isFinite(tickUpperValue)) {
      notification.error(t("notifications.numberInvalid"));
      return;
    }

    setIsSubmittingV3(true);
    try {
      await setUniswapV3ConfigAsync(
        {
          functionName: "setTokenConfig",
          args: [
            token as `0x${string}`,
            counterPartyToken as `0x${string}`,
            slippageValue,
            feeTierValue,
            tickLowerValue,
            tickUpperValue,
            vaultAddress as `0x${string}`,
          ],
        },
        {
          onBlockConfirmation: () => {
            notification.success(t("notifications.uniswapV3Updated"));
            setUniswapV3Config(INITIAL_PARTIAL_STATE);
          },
        },
      );
    } catch (error: any) {
      console.error("Set Uniswap V3 config failed:", error);
      notification.error(error?.message || t("notifications.configFailed"));
    } finally {
      setIsSubmittingV3(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">➕ {t("sections.add")}</h2>
          <div className="flex flex-col md:flex-row gap-2">
            <input
              type="text"
              placeholder="0x..."
              className="input input-bordered flex-1 font-mono text-sm"
              value={newAdapterAddress}
              onChange={e => setNewAdapterAddress(e.target.value)}
              disabled={isAdding}
            />
            <button
              onClick={handleAddAdapter}
              className="btn btn-primary"
              disabled={isAdding || !newAdapterAddress.trim()}
            >
              {isAdding ? (
                <>
                  <span className="loading loading-spinner loading-sm"></span>
                  {t("buttons.adding")}
                </>
              ) : (
                t("buttons.add")
              )}
            </button>
          </div>
        </div>
      </div>

      <div className="card bg-base-100 shadow-xl">
        <div className="card-body">
          <h2 className="card-title">
            🔧 {t("sections.registered")} ({registeredAdapters.length})
          </h2>

          {registeredAdapters.length === 0 ? (
            <div className="text-center py-16">
              <div className="text-6xl mb-4">🔌</div>
              <p className="text-lg opacity-70">{t("table.empty")}</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="table table-zebra">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>{t("labels.name")}</th>
                    <th>{t("labels.address")}</th>
                    <th>{t("labels.status")}</th>
                  </tr>
                </thead>
                <tbody>
                  {registeredAdapters.map((adapter, index) => (
                    <tr key={adapter}>
                      <td>{index + 1}</td>
                      <td className="font-semibold">
                        {adapterMeta[adapter]?.name ?? t("table.loading")}
                      </td>
                      <td>
                        <code className="text-sm">{formatAddress(adapter)}</code>
                      </td>
                      <td>
                        <span
                          className={`badge border-none ${
                            adapterMeta[adapter]?.approved ? "bg-[#803100]/80 text-white" : "bg-warning/60"
                          }`}
                        >
                          {adapterMeta[adapter]?.approved ? t("table.approved") : t("table.pending")}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      <div className="card bg-base-100 shadow-xl">
        <div className="card-body space-y-6">
          <h2 className="card-title">⚙️ {t("sections.config")}</h2>

          <div className="divider text-sm">{t("sections.aave")}</div>
          <form className="grid md:grid-cols-2 gap-4" onSubmit={handleSetTokenVault}>
            <div>
              <label className="label text-xs">{t("labels.token")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={aaveConfig.token}
                onChange={e => setAaveConfig(prev => ({ ...prev, token: e.target.value }))}
                placeholder="0xToken"
                disabled={isSubmittingAave}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.vault")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={aaveConfig.vault}
                onChange={e => setAaveConfig(prev => ({ ...prev, vault: e.target.value }))}
                placeholder="0xVault"
                disabled={isSubmittingAave}
              />
            </div>
            <div className="md:col-span-2 flex justify-end">
              <button className="btn btn-primary" type="submit" disabled={isSubmittingAave}>
                {isSubmittingAave ? (
                  <>
                    <span className="loading loading-spinner loading-sm"></span>
                    {t("buttons.updating")}
                  </>
                ) : (
                  t("buttons.updateAave")
                )}
              </button>
            </div>
          </form>

          <div className="divider text-sm">{t("sections.uniswapV2")}</div>
          <form className="grid md:grid-cols-2 gap-4" onSubmit={handleSetUniswapV2Config}>
            <div>
              <label className="label text-xs">{t("labels.token")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={uniswapV2Config.token}
                onChange={e => setUniswapV2Config(prev => ({ ...prev, token: e.target.value }))}
                placeholder="0xToken"
                disabled={isSubmittingV2}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.counterparty")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={uniswapV2Config.counterPartyToken}
                onChange={e => setUniswapV2Config(prev => ({ ...prev, counterPartyToken: e.target.value }))}
                placeholder="0xCounterToken"
                disabled={isSubmittingV2}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.slippage")}</label>
              <input
                type="number"
                className="input input-bordered w-full"
                value={uniswapV2Config.slippageTolerance}
                onChange={e => setUniswapV2Config(prev => ({ ...prev, slippageTolerance: e.target.value }))}
                placeholder="50 (0.5%)"
                disabled={isSubmittingV2}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.vault")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={uniswapV2Config.vault}
                onChange={e => setUniswapV2Config(prev => ({ ...prev, vault: e.target.value }))}
                placeholder="0xVault"
                disabled={isSubmittingV2}
              />
            </div>
            <div className="md:col-span-2 flex justify-end">
              <button className="btn btn-primary" type="submit" disabled={isSubmittingV2}>
                {isSubmittingV2 ? (
                  <>
                    <span className="loading loading-spinner loading-sm"></span>
                    {t("buttons.updating")}
                  </>
                ) : (
                  t("buttons.updateUniswapV2")
                )}
              </button>
            </div>
          </form>

          <div className="divider text-sm">{t("sections.uniswapV3")}</div>
          <form className="grid md:grid-cols-2 gap-4" onSubmit={handleSetUniswapV3Config}>
            <div>
              <label className="label text-xs">{t("labels.token")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={uniswapV3Config.token}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, token: e.target.value }))}
                placeholder="0xToken"
                disabled={isSubmittingV3}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.counterparty")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={uniswapV3Config.counterPartyToken}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, counterPartyToken: e.target.value }))}
                placeholder="0xCounterToken"
                disabled={isSubmittingV3}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.slippage")}</label>
              <input
                type="number"
                className="input input-bordered w-full"
                value={uniswapV3Config.slippageTolerance}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, slippageTolerance: e.target.value }))}
                placeholder="50 (0.5%)"
                disabled={isSubmittingV3}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.feeTier")}</label>
              <input
                type="number"
                className="input input-bordered w-full"
                value={uniswapV3Config.feeTier}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, feeTier: e.target.value }))}
                placeholder="500"
                disabled={isSubmittingV3}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.tickLower")}</label>
              <input
                type="number"
                className="input input-bordered w-full"
                value={uniswapV3Config.tickLower}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, tickLower: e.target.value }))}
                placeholder="-60000"
                disabled={isSubmittingV3}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.tickUpper")}</label>
              <input
                type="number"
                className="input input-bordered w-full"
                value={uniswapV3Config.tickUpper}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, tickUpper: e.target.value }))}
                placeholder="60000"
                disabled={isSubmittingV3}
              />
            </div>
            <div>
              <label className="label text-xs">{t("labels.vault")}</label>
              <input
                type="text"
                className="input input-bordered w-full"
                value={uniswapV3Config.vaultAddress}
                onChange={e => setUniswapV3Config(prev => ({ ...prev, vaultAddress: e.target.value }))}
                placeholder="0xVault"
                disabled={isSubmittingV3}
              />
            </div>
            <div className="md:col-span-2 flex justify-end">
              <button className="btn btn-primary" type="submit" disabled={isSubmittingV3}>
                {isSubmittingV3 ? (
                  <>
                    <span className="loading loading-spinner loading-sm"></span>
                    {t("buttons.updating")}
                  </>
                ) : (
                  t("buttons.updateUniswapV3")
                )}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default AdapterManager;
