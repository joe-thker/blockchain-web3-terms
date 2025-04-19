// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract GovernedOHMFork is IERC20, Ownable, Pausable {
    using SafeMath for uint256;

    string public constant name     = "OHM Fork Governed";
    string public constant symbol   = "OHMFG";
    uint8  public constant decimals = 9;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000 * 10**decimals;
    uint256 private constant TOTAL_GONS = ~uint256(0) - (~uint256(0) % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    mapping(address => bool) public rebasers;
    event RebaserAdded(address indexed who);
    event RebaserRemoved(address indexed who);
    event Rebase(uint256 indexed epoch, uint256 prevSupply, uint256 newSupply);

    constructor() Ownable(msg.sender) {
        _totalSupply     = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _gonBalances[msg.sender] = TOTAL_GONS;
        rebasers[msg.sender] = true;
        emit RebaserAdded(msg.sender);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier onlyRebaser() {
        require(rebasers[msg.sender], "GovernedOHMFork: not rebaser");
        _;
    }

    function addRebaser(address who) external onlyOwner {
        rebasers[who] = true;
        emit RebaserAdded(who);
    }

    function removeRebaser(address who) external onlyOwner {
        rebasers[who] = false;
        emit RebaserRemoved(who);
    }

    function pause() external onlyOwner {
        _pause();
    }
    function unpause() external onlyOwner {
        _unpause();
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _gonBalances[account].div(_gonsPerFragment);
    }

    function transfer(address to, uint256 amount) external override whenNotPaused returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    function allowance(address owner_, address spender) external view override returns (uint256) {
        return _allowedFragments[owner_][spender];
    }
    function approve(address spender, uint256 amount) external override whenNotPaused returns (bool) {
        _allowedFragments[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external override whenNotPaused returns (bool) {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender]
            .sub(amount, "GovernedOHMFork: allowance exceeded");
        _transfer(from, to, amount);
        emit Approval(from, msg.sender, _allowedFragments[from][msg.sender]);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 gonValue = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from]
            .sub(gonValue, "GovernedOHMFork: balance exceeded");
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, amount);
    }

    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyRebaser
        whenNotPaused
        returns (uint256)
    {
        uint256 prev = _totalSupply;
        if (supplyDelta > 0) {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        } else if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        }
        uint256 max = INITIAL_FRAGMENTS_SUPPLY.mul(10**3);
        if (_totalSupply > max) _totalSupply = max;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        emit Rebase(epoch, prev, _totalSupply);
        return _totalSupply;
    }
}
