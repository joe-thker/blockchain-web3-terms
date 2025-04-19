// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title OHM Fork (Rebaseable ERC-20)
 * @notice A simplified fork of Olympus (OHM): a rebasing ERC‑20 token.
 *         - Owner can call `rebase(epoch, supplyDelta)` to expand or contract supply.
 *         - Balances adjust automatically via a “gons per fragment” scaling factor.
 */
contract OHMFork is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name     = "OHM Fork";
    string public constant symbol   = "OHMF";
    uint8  public constant decimals = 9;

    // Initial supply: 1,000,000 * 10^decimals
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000 * 10**decimals;
    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY
    uint256 private constant TOTAL_GONS = ~uint256(0) - (~uint256(0) % INITIAL_FRAGMENTS_SUPPLY);

    // Total number of fragments (visible supply)
    uint256 private _totalSupply;
    // How many gons correspond to one fragment
    uint256 private _gonsPerFragment;

    // balances are stored in gons
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    // Rebase event, as in Olympus
    event Rebase(uint256 indexed epoch, uint256 prevSupply, uint256 newSupply);

    /**
     * @dev Passes msg.sender to Ownable so deployer becomes the contract owner.
     *      Initializes supply and assigns all gons to deployer.
     */
    constructor() Ownable(msg.sender) {
        _totalSupply     = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _gonBalances[msg.sender] = TOTAL_GONS;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /** ERC‑20 interface **/

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowedFragments[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(
            amount,
            "OHMFork: transfer amount exceeds allowance"
        );
        _transfer(from, to, amount);
        emit Approval(from, msg.sender, _allowedFragments[from][msg.sender]);
        return true;
    }

    /** Internal transfer in gons **/
    function _transfer(address from, address to, uint256 amount) internal {
        uint256 gonValue = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(
            gonValue,
            "OHMFork: transfer amount exceeds balance"
        );
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, amount);
    }

    /** Rebase function **/
    function rebase(uint256 epoch, int256 supplyDelta) external onlyOwner returns (uint256) {
        uint256 prevSupply = _totalSupply;
        if (supplyDelta == 0) {
            emit Rebase(epoch, prevSupply, prevSupply);
            return _totalSupply;
        }
        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }
        // Prevent extreme supply growth
        uint256 maxSupply = INITIAL_FRAGMENTS_SUPPLY.mul(10**3);
        if (_totalSupply > maxSupply) {
            _totalSupply = maxSupply;
        }
        // Recalculate gons per fragment
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        emit Rebase(epoch, prevSupply, _totalSupply);
        return _totalSupply;
    }
}
