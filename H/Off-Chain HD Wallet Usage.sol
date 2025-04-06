const bip39 = require('bip39');
const hdkey = require('ethereumjs-wallet/hdkey');

// 1. Generate mnemonic
const mnemonic = bip39.generateMnemonic();

// 2. Create seed
const seed = bip39.mnemonicToSeedSync(mnemonic);

// 3. Create HD wallet
const hdWallet = hdkey.fromMasterSeed(seed);

// 4. Derive Ethereum address from path
const path = "m/44'/60'/0'/0/0";
const wallet = hdWallet.derivePath(path).getWallet();
const address = wallet.getAddressString();
