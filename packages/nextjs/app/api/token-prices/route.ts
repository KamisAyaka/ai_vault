import { NextResponse } from "next/server";

type TokenDefinition = {
  id: string;
  symbol: string;
};

const UNISWAP_V3_SUBGRAPH_URL =
  "https://gateway.thegraph.com/api/subgraphs/id/5zvR82QoaXYFyDEKLZ9t6v9adgnptxYpKpSbxtgVENFV";

const TOKENS: TokenDefinition[] = [
  {
    // WETH mainnet
    id: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2".toLowerCase(),
    symbol: "WETH",
  },
  {
    // WBTC mainnet
    id: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599".toLowerCase(),
    symbol: "WBTC",
  },
];

const PRICE_QUERY = `
  query TokenPrices($tokenIds: [Bytes!]!) {
    bundles(first: 1) {
      ethPriceUSD
    }
    tokens(where: { id_in: $tokenIds }) {
      id
      symbol
      derivedETH
    }
  }
`;

export async function GET() {
  const apiKey = process.env.THE_GRAPH_API_KEY ?? process.env.NEXT_PUBLIC_THE_GRAPH_API_KEY;

  try {
    if (!apiKey) {
      console.warn("/api/token-prices called without THE_GRAPH_API_KEY configured");
      return NextResponse.json({ prices: {}, updatedAt: Date.now() }, { status: 200 });
    }

    const response = await fetch(UNISWAP_V3_SUBGRAPH_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        query: PRICE_QUERY,
        variables: {
          tokenIds: TOKENS.map(token => token.id),
        },
      }),
      next: { revalidate: 60 },
    });

    if (!response.ok) {
      const errorText = await response.text();
      return NextResponse.json({ error: errorText || "Failed to fetch token prices" }, { status: 502 });
    }

    const { data, errors } = (await response.json()) as {
      data?: {
        bundles: Array<{ ethPriceUSD: string }>;
        tokens: Array<{ id: string; symbol: string; derivedETH: string }>;
      };
      errors?: Array<{ message: string }>;
    };

    if (errors?.length) {
      return NextResponse.json({ error: errors.map(e => e.message).join("; ") }, { status: 502 });
    }

    const ethPriceUSD = Number(data?.bundles?.[0]?.ethPriceUSD ?? 0);
    const priceMap: Record<string, number> = {};

    if (Number.isFinite(ethPriceUSD) && ethPriceUSD > 0) {
      TOKENS.forEach(token => {
        if (token.symbol === "WETH") {
          priceMap[token.symbol] = ethPriceUSD;
        }
      });
    }

    data?.tokens?.forEach(token => {
      const derivedETH = Number(token.derivedETH ?? 0);
      if (!Number.isFinite(derivedETH) || derivedETH <= 0) return;

      const usdPrice = derivedETH * ethPriceUSD;
      if (Number.isFinite(usdPrice) && usdPrice > 0) {
        priceMap[token.symbol.toUpperCase()] = usdPrice;
      }
    });

    return NextResponse.json({
      prices: priceMap,
      updatedAt: Date.now(),
    });
  } catch (error) {
    console.error("Failed to fetch token prices", error);
    return NextResponse.json({ error: "Failed to fetch token prices" }, { status: 500 });
  }
}
