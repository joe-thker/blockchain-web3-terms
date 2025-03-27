// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Vault contract holds a single user’s collateral to avoid commingling.
/// Each vault is deployed for an individual user and owned by the main stable coin contract.
contract Vault is Ownable {
    using SafeERC20 for IERC20;
    
    IERC20 public immutable collateralToken;
    
    /// @notice Constructor sets the collateral token and assigns ownership.
    /// @param _collateralToken The address of the collateral ERC20 token.
    /// @param owner_ The owner of the vault (set to the main contract).
    constructor(address _collateralToken, address owner_) Ownable(owner_) {
        require(_collateralToken != address(0), "Invalid token address");
        collateralToken = IERC20(_collateralToken);
    }
    
    /// @notice Withdraws a specified amount of collateral to a given address.
    /// Only callable by the vault owner (the main contract).
    function withdraw(address to, uint256 amount) external onlyOwner {
        collateralToken.safeTransfer(to, amount);
    }
    
    /// @notice Returns the vault’s current collateral balance.
    function balance() external view returns (uint256) {
        return collateralToken.balanceOf(address(this));
    }
}

/// @notice Interface for composable hooks. External modules can implement these
/// functions to respond to deposit, withdraw, mint, and burn events.
interface IComposableHook {
    function onDeposit(address user, uint256 amount) external;
    function onWithdraw(address user, uint256 amount) external;
    function onMint(address user, uint256 amount) external;
    function onBurn(address user, uint256 amount) external;
}

/// @notice ComposableCollateralizedStableCoin is an ERC20 token representing the stable coin.
/// Users deposit collateral into their own vault (preventing commingling) and then mint stable coins
/// up to a safe collateralization ratio. In addition, this contract is designed to be composable:
/// external hook contracts can be registered to react to key actions (deposit, withdraw, mint, burn),
/// enabling integration with other protocols.
contract ComposableCollateralizedStableCoin is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    // The collateral token used to back the stable coin.
    IERC20 public immutable collateralToken;
    
    // Mapping to track each user’s collateral amount (as recorded by the main contract).
    mapping(address => uint256) public collateralBalance;
    // Mapping to track each user’s debt (stable coin minted).
    mapping(address => uint256) public debtBalance;
    // Mapping from user address to their personal vault.
    mapping(address => Vault) public vaults;
    
    // Required collateralization ratio in basis points.
    // For example, 15000 means the user’s collateral must be at least 150% of their debt.
    uint256 public collateralizationRatio;
    
    // --- Composability: Integration Hooks ---
    // These hooks allow external contracts to react to key actions.
    bytes32 public constant DEPOSIT_HOOK  = keccak256("DEPOSIT_HOOK");
    bytes32 public constant WITHDRAW_HOOK = keccak256("WITHDRAW_HOOK");
    bytes32 public constant MINT_HOOK     = keccak256("MINT_HOOK");
    bytes32 public constant BURN_HOOK     = keccak256("BURN_HOOK");
    
    // Mapping from hook identifier to integration hook contract address.
    mapping(bytes32 => address) public integrationHooks;
    
    // --- Events ---
    event CollateralDeposited(address indexed user, uint256 amount);
    event CollateralWithdrawn(address indexed user, uint256 amount);
    event StableCoinMinted(address indexed user, uint256 amount);
    event StableCoinBurned(address indexed user, uint256 amount);
    event IntegrationHookSet(bytes32 indexed hookId, address hookAddress);
    
    /// @notice Constructor sets the collateral token, initial collateralization ratio, and stable coin details.
    /// @param _collateralToken Address of the collateral ERC20 token.
    /// @param _collateralizationRatio Required collateralization ratio in basis points (>= 10000 = 100%).
    /// @param name Name of the stable coin.
    /// @param symbol Symbol of the stable coin.
    constructor(
        address _collateralToken,
        uint256 _collateralizationRatio, 
        string memory name, 
        string memory symbol
    )
        ERC20(name, symbol)
        Ownable(msg.sender)
    {
        require(_collateralToken != address(0), "Invalid collateral token address");
        require(_collateralizationRatio >= 10000, "Collateralization ratio must be at least 100%");
        collateralToken = IERC20(_collateralToken);
        collateralizationRatio = _collateralizationRatio;
    }
    
    /// @notice Set an integration hook contract for a given hook identifier.
    /// Only the contract owner can register integration hooks.
    /// @param hookId Identifier for the hook (e.g. DEPOSIT_HOOK).
    /// @param hookAddress Address of the integration hook contract.
    function setIntegrationHook(bytes32 hookId, address hookAddress) external onlyOwner {
        integrationHooks[hookId] = hookAddress;
        emit IntegrationHookSet(hookId, hookAddress);
    }
    
    /// @notice Internal helper to retrieve (or create) the vault for a user.
    function _getVault(address user) internal returns (Vault) {
        if (address(vaults[user]) == address(0)) {
            Vault newVault = new Vault(address(collateralToken), address(this));
            vaults[user] = newVault;
        }
        return vaults[user];
    }
    
    /// @notice Deposit collateral into your personal vault.
    /// The deposited amount is tracked and stored in a vault specific to you.
    function depositCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        Vault vault = _getVault(msg.sender);
        // Transfer collateral directly from user to their vault.
        collateralToken.safeTransferFrom(msg.sender, address(vault), amount);
        collateralBalance[msg.sender] += amount;
        emit CollateralDeposited(msg.sender, amount);
        
        // If a deposit hook is registered, call it.
        address hook = integrationHooks[DEPOSIT_HOOK];
        if (hook != address(0)) {
            IComposableHook(hook).onDeposit(msg.sender, amount);
        }
    }
    
    /// @notice Withdraw collateral from your vault.
    /// Allowed only if the remaining collateral keeps your position safely collateralized.
    function withdrawCollateral(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(collateralBalance[msg.sender] >= amount, "Insufficient collateral balance");
        
        uint256 newCollateral = collateralBalance[msg.sender] - amount;
        require(_isCollateralSufficient(msg.sender, newCollateral, debtBalance[msg.sender]), "Withdrawal would breach collateralization ratio");
        
        collateralBalance[msg.sender] = newCollateral;
        Vault vault = vaults[msg.sender];
        require(address(vault) != address(0), "No vault exists for user");
        vault.withdraw(msg.sender, amount);
        emit CollateralWithdrawn(msg.sender, amount);
        
        // If a withdraw hook is registered, call it.
        address hook = integrationHooks[WITHDRAW_HOOK];
        if (hook != address(0)) {
            IComposableHook(hook).onWithdraw(msg.sender, amount);
        }
    }
    
    /// @notice Mint stable coins against your deposited collateral.
    /// Your debt increases, and new stable coins are minted to your account.
    function mintStableCoin(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        uint256 newDebt = debtBalance[msg.sender] + amount;
        require(_isCollateralSufficient(msg.sender, collateralBalance[msg.sender], newDebt), "Insufficient collateral to mint that amount");
        
        debtBalance[msg.sender] = newDebt;
        _mint(msg.sender, amount);
        emit StableCoinMinted(msg.sender, amount);
        
        // If a mint hook is registered, call it.
        address hook = integrationHooks[MINT_HOOK];
        if (hook != address(0)) {
            IComposableHook(hook).onMint(msg.sender, amount);
        }
    }
    
    /// @notice Burn stable coins to repay debt.
    function burnStableCoin(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be > 0");
        require(debtBalance[msg.sender] >= amount, "Amount exceeds debt");
        
        debtBalance[msg.sender] -= amount;
        _burn(msg.sender, amount);
        emit StableCoinBurned(msg.sender, amount);
        
        // If a burn hook is registered, call it.
        address hook = integrationHooks[BURN_HOOK];
        if (hook != address(0)) {
            IComposableHook(hook).onBurn(msg.sender, amount);
        }
    }
    
    /// @notice Internal helper to verify that collateral and debt satisfy the collateralization ratio.
    /// Assumes a 1:1 price between collateral and stable coin.
    function _isCollateralSufficient(address user, uint256 collateralAmt, uint256 debtAmt) internal view returns (bool) {
        if (debtAmt == 0) {
            return true;
        }
        return (collateralAmt * 10000) >= (debtAmt * collateralizationRatio);
    }
    
    /// @notice Returns the current collateralization ratio for a user (in basis points).
    /// If the user has no debt, returns the maximum uint256.
    function getUserCollateralizationRatio(address user) external view returns (uint256) {
        uint256 debt = debtBalance[user];
        if (debt == 0) {
            return type(uint256).max;
        }
        return (collateralBalance[user] * 10000) / debt;
    }
    
    /// @notice Owner can update the required collateralization ratio.
    function updateCollateralizationRatio(uint256 newRatio) external onlyOwner {
        require(newRatio >= 10000, "Collateralization ratio must be at least 100%");
        collateralizationRatio = newRatio;
    }
}
