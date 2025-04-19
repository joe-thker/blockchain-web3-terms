// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract FeeOHMFork is IERC20, Ownable {
    using SafeMath for uint256;

    string public constant name     = "OHM Fork w/ Fee";
    string public constant symbol   = "OHMFF";
    uint8  public constant decimals = 9;

    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1_000_000 * 10**decimals;
    uint256 private constant TOTAL_GONS = ~uint256(0) - (~uint256(0) % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    // Fee in basis points (parts per 10,000)
    uint16 public feeBasisPoints;
    address public treasury;

    event Rebase(uint256 indexed epoch, uint256 prevSupply, uint256 newSupply);
    event FeeUpdated(uint16 oldBP, uint16 newBP);
    event TreasuryChanged(address oldT, address newT);

    constructor(
        uint16 _feeBasisPoints,
        address _treasury
    ) Ownable(msg.sender) {
        require(_feeBasisPoints <= 1000, "Max fee 10%");
        require(_treasury != address(0), "No zero treasury");
        feeBasisPoints = _feeBasisPoints;
        treasury       = _treasury;

        _totalSupply     = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _gonBalances[msg.sender] = TOTAL_GONS;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function setFeeBP(uint16 newBP) external onlyOwner {
        require(newBP <= 1000, "Max 10%");
        emit FeeUpdated(feeBasisPoints, newBP);
        feeBasisPoints = newBP;
    }

    function setTreasury(address newT) external onlyOwner {
        require(newT != address(0), "No zero treasury");
        emit TreasuryChanged(treasury, newT);
        treasury = newT;
    }

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
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender]
            .sub(amount, "FeeOHMFork: allowance exceeded");
        _transfer(from, to, amount);
        emit Approval(from, msg.sender, _allowedFragments[from][msg.sender]);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 feeAmt    = amount.mul(feeBasisPoints).div(10000);
        uint256 sendAmt   = amount.sub(feeAmt);
        uint256 gonValue  = amount.mul(_gonsPerFragment);
        uint256 gonSend   = sendAmt.mul(_gonsPerFragment);
        uint256 gonFeeVal = feeAmt.mul(_gonsPerFragment);

        _gonBalances[from] = _gonBalances[from].sub(gonValue, "FeeOHMFork: balance exceeded");
        _gonBalances[treasury] = _gonBalances[treasury].add(gonFeeVal);
        _gonBalances[to]       = _gonBalances[to].add(gonSend);

        if (feeAmt > 0) emit Transfer(from, treasury, feeAmt);
        emit Transfer(from, to, sendAmt);
    }

    function rebase(uint256 epoch, int256 supplyDelta) external onlyOwner returns (uint256) {
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
