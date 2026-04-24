// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SecureTRC20 {
    string public name = "Secure USDT";
    string public symbol = "SUSDT";
    uint8 public decimals = 6;
    uint256 public totalSupply;

    address public owner;
    bool public paused = false;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event Paused();
    event Unpaused();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract paused");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply * (10 ** decimals);
        balances[msg.sender] = totalSupply;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ================= 基础功能 =================

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "Invalid address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // ================= 授权优化 =================

    function approve(address spender, uint256 amount) public whenNotPaused returns (bool) {
        require(spender != address(0), "Invalid spender");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // 防止授权漏洞（先归零再修改）
    function safeApprove(address spender, uint256 amount) public returns (bool) {
        require(allowances[msg.sender][spender] == 0, "Must reset to 0 first");
        return approve(spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        allowances[msg.sender][spender] += addedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Below zero");

        allowances[msg.sender][spender] = currentAllowance - subtractedValue;

        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowances[owner_][spender];
    }

    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
        require(recipient != address(0), "Invalid address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // ================= 管理功能 =================

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "Invalid address");

        uint256 mintAmount = amount * (10 ** decimals);
        totalSupply += mintAmount;
        balances[to] += mintAmount;

        emit Transfer(address(0), to, mintAmount);
    }

    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Not enough");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function pause() public onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() public onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address");

        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}