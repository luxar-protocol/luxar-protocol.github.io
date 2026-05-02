/**
 *Submitted for verification at polygonscan.com on 2026-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/*
    GENESIS: 15/Feb/2026
    "LUXAR: Absolute scarcity is born. 50,000 units. No master, no servant."
    
    LXR - Scarcity Protocol
    Fixed Supply: 50,000
    Security: No Tax, No Mint, Renounceable Limits.
*/

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return 18; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from zero");
        require(to != address(0), "ERC20: transfer to zero");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer exceeds balance");
        unchecked { _balances[from] = fromBalance - amount; }
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to zero");
        _totalSupply += amount;
        unchecked { _balances[account] += amount; }
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from zero");
        require(spender != address(0), "ERC20: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked { _approve(owner, spender, currentAllowance - amount); }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _transferOwnership(_msgSender()); }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }
    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Luxar is ERC20, Ownable {
    uint256 public constant TOTAL_SUPPLY = 50_000 * 1e18;
    address public lpPair;
    bool public limitsActive = true;
    uint256 public immutable maxBuyAmount;
    uint256 public immutable maxWalletAmount;

    event LpPairSet(address indexed lpPair);
    event LimitsDisabledForever();

    constructor(
        address owner_,
        uint256 _maxBuyAmount,
        uint256 _maxWalletAmount
    ) ERC20("LUXAR", "LXR") {
        require(owner_ != address(0), "Invalid address");
        require(_maxBuyAmount > 0, "Invalid limit");
        require(_maxWalletAmount >= _maxBuyAmount, "Invalid ratio");

        _transferOwnership(owner_);
        _mint(owner_, TOTAL_SUPPLY);

        maxBuyAmount = _maxBuyAmount;
        maxWalletAmount = _maxWalletAmount;
    }

    function setLpPair(address _lpPair) external onlyOwner {
        require(lpPair == address(0), "Pair fixed");
        require(_lpPair != address(0), "Invalid address");
        lpPair = _lpPair;
        emit LpPairSet(_lpPair);
    }

    function disableLimitsForever() external onlyOwner {
        require(limitsActive, "Already unrestricted");
        limitsActive = false;
        emit LimitsDisabledForever();
    }

    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if (limitsActive && from == lpPair && to != address(0)) {
            require(amount <= maxBuyAmount, "Exceeds limit");
            require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds wallet capacity");
        }
        super._transfer(from, to, amount);
    }
}
