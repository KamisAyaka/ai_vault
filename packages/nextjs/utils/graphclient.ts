const DEFAULT_SUBGRAPH_URL =
  process.env.NEXT_PUBLIC_SUBGRAPH_URL ?? "http://localhost:8000/subgraphs/name/scaffold-eth/ai-vault";

export const GetVaultsDocument = `
  query GetVaults($first: Int = 10, $skip: Int = 0, $orderBy: Vault_orderBy, $orderDirection: OrderDirection) {
    vaults(first: $first, skip: $skip, orderBy: $orderBy, orderDirection: $orderDirection) {
      id
      address
      name
      isActive
      asset {
        id
        address
        symbol
        name
        decimals
      }
      totalAssets
      totalSupply
      manager {
        id
        address
        owner
      }
      createdAt
      updatedAt
      deposits(first: 1000, orderBy: blockTimestamp, orderDirection: desc) {
        id
        user {
          id
          address
        }
        assets
        userShares
        blockTimestamp
        transactionHash
      }
      redeems(first: 1000, orderBy: blockTimestamp, orderDirection: desc) {
        id
        user {
          id
          address
        }
        assets
        shares
        blockTimestamp
        transactionHash
      }
      allocations {
        id
        adapterAddress
        adapterType
        allocation
      }
    }
  }
`;

export const GetUserPortfolioDocument = `
  query GetUserPortfolio($userId: ID!) {
    userStats(id: $userId) {
      id
      totalDeposited
      totalShares
      activeVaults
      lastUpdated
    }
    userVaultBalances(where: { user: $userId }, first: 1000) {
      id
      totalDeposited
      totalRedeemed
      currentShares
      currentValue
      lastUpdated
      user {
        id
        address
      }
      vault {
        id
        address
        name
        isActive
        totalAssets
        totalSupply
        asset {
          id
          address
          symbol
          name
          decimals
        }
      }
    }
  }
`;

type GraphClientOptions = {
  endpoint?: string;
  headers?: Record<string, string>;
};

type GraphQLResult<TData> = {
  data?: TData;
  errors?: Array<{ message: string }>;
};

export async function execute<TData = unknown, TVariables = Record<string, unknown>>(
  document: string,
  variables: TVariables = {} as TVariables,
  options: GraphClientOptions = {},
): Promise<GraphQLResult<TData>> {
  const endpoint = options.endpoint ?? DEFAULT_SUBGRAPH_URL;

  if (!endpoint) {
    throw new Error("Graph client endpoint is not configured. Set NEXT_PUBLIC_SUBGRAPH_URL.");
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(options.headers ?? {}),
    },
    body: JSON.stringify({ query: document, variables }),
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => response.statusText);
    throw new Error(`Graph client request failed: ${errorText}`);
  }

  const result = (await response.json()) as GraphQLResult<TData>;

  if (result.errors?.length) {
    const messages = result.errors.map(error => error.message).join("; ");
    throw new Error(messages);
  }

  return result;
}
