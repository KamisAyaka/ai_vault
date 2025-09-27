"use client";

import { useEffect, useState } from "react";
import { GetVaultsDocument, execute } from "~~/.graphclient";
import { Address } from "~~/components/scaffold-eth";

const VaultsTable = () => {
  const [vaultsData, setVaultsData] = useState<any>(null);
  const [error, setError] = useState<any>(null);

  useEffect(() => {
    const fetchData = async () => {
      if (!execute || !GetVaultsDocument) {
        return;
      }
      try {
        const { data: result } = await execute(GetVaultsDocument, {});
        setVaultsData(result);
        console.log(result);
      } catch (err) {
        setError(err);
      } finally {
      }
    };

    fetchData();
  }, []);

  if (error) {
    return null;
  }

  return (
    <div className="flex justify-center items-center mt-10">
      <div className="overflow-x-auto shadow-2xl rounded-xl">
        <table className="table bg-base-100 table-zebra">
          <thead>
            <tr className="rounded-xl">
              <th className="bg-primary"></th>
              <th className="bg-primary">Vault Address</th>
              <th className="bg-primary">Name</th>
              <th className="bg-primary">Manager</th>
              <th className="bg-primary">Total Assets</th>
              <th className="bg-primary">Total Supply</th>
              <th className="bg-primary">Active</th>
            </tr>
          </thead>
          <tbody>
            {vaultsData?.vaults?.map((vault: any, index: number) => (
              <tr key={vault.id}>
                <th>{index + 1}</th>
                <td>
                  <Address address={vault?.address} />
                </td>
                <td>{vault.name}</td>
                <td>
                  <Address address={vault?.manager?.address} />
                </td>
                <td>{vault.totalAssets?.toString()}</td>
                <td>{vault.totalSupply?.toString()}</td>
                <td>{vault.isActive ? "Yes" : "No"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default VaultsTable;
