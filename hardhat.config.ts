import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import * as dotenv from "dotenv";

dotenv.config();
const PRIVATE_KEY = process.env.PRIVATE_KEY!;

const config: HardhatUserConfig = {
  defaultNetwork: "arbSepolia",
  paths: {
    sources: "./contracts",
    tests: "./test",
    artifacts: "./build/artifacts",
    cache: "./build/cache",
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 0,
          },
        },
      },
      {
        version: "0.8.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 0,
          },
        },
      },
    ],
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      accounts: [
        {
          privateKey:
            "36f1ea3519a6949576c242d927dd0c74650554cdfaedbcd03fb3a80c558c03de",

          balance: "100000000000000000000000000000",
        },
        {
          privateKey:
            "37235af6356e58fd30610f5b5b3979041e029fccdfce7bf05ee868d3f7c114ec",

          balance: "100000000000000000000000000000",
        },
        {
          privateKey:
            "ddc0dbf76bd1652473690e3e67cad62a42407fa3068a0710b80481be4ef2f3bb",

          balance: "100000000000000000000000000000",
        },
      ],
      gasPrice: 5000000000,
      // gas: 25e6,
    },
    bscTestnet: {
      url: "https://bsc-testnet.publicnode.com",
      chainId: 97,
      gasPrice: 4e9,
      gas: 2e7,
      accounts: [
        `0x${PRIVATE_KEY}`,
      ]
    },
    bscMainnet: {
      url: "https://bsc.publicnode.com",
      chainId: 56,
      gasPrice: 3e9,
      accounts: [
        `0x${PRIVATE_KEY}`,
      ],
    },
    ethMainnet: {
      url: "https://ethereum.publicnode.com",
      chainId: 1,
      gasPrice: 35e9,
      gas: 1e7,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    arbSepolia: {
      url: "https://arbitrum-sepolia.blockpi.network/v1/rpc/public",
      chainId: 421614,
      gas: 2e7,
      gasPrice: 3e8,
      accounts: [
        `0x${PRIVATE_KEY}`,
      ],
    },
    arbMainnet:{
      url: `https://arbitrum-mainnet.infura.io/v3/${process.env.INFURA_KEY!}`,
      chainId: 42161,
      gas: 2e7,
      gasPrice: 2e8,
      accounts: [
        `0x${PRIVATE_KEY}`,
      ],
    }
  },
};

export default config;