pragma solidity ^0.6.3;

import './Math.sol';


contract SarafanToken {
    using SafeMath for uint256;

    // contract owner address
    address public contractOwner;

    // reward for storage of 1Mb for a full month
    uint256 public megabyteMonthCost = 1;

    // content index contract address
    address public contentContract;

    // delivery network peering contract address
    address public peeringContract;

    // ERC-20 fields
    string public name = "Sarafan Token";
    string public symbol = "SRFN";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // ERC-20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Sarafan specific events
    event ContentContractChange(address addr);
    event PeeringContractChange(address addr);

    constructor() public {
        contractOwner = msg.sender;
        uint256 ownerAmount = 300000000;
        balanceOf[msg.sender] = ownerAmount;
        totalSupply = totalSupply.add(ownerAmount);
        emit Transfer(address(0), msg.sender, ownerAmount);
    }

    /* Exchange ether to tokens.
    */
    receive() external payable {
        // multiplier to 1 ether
        uint256 multiplier = 1000; // ico close price ~$0.2, trading should go though market

        if (totalSupply < 350000000) {  // 350M (50M sold)
            multiplier = 1000000; // ~$0.0002 first ICO stage
        } else if (totalSupply < 500000000) { // 500M (200M sold)
            multiplier = 100000; // ~$0.002 second ICO stage
        } else if (totalSupply < 700000000) { // 700M (400M sold)
            multiplier = 10000; // ~$0.02 third ICO stage
        }

        uint256 tokensCount = multiplier.mul(msg.value).div(10 ** 18);

        balanceOf[msg.sender] = balanceOf[msg.sender].add(tokensCount);
        totalSupply = totalSupply.add(tokensCount);
        emit Transfer(address(0), msg.sender, tokensCount);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value, "Not enough tokens on sender balance");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(value);
        balanceOf[to] = balanceOf[to].add(value);

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /* Approve spending of value from sender account by spender.

    ERC-20 method.
    */
    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from], "Not enough tokens on from account");
        require(value <= allowance[from][msg.sender], "Not enough token allowed");

        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    // Set content index contract address
    function setContentContract(address addr) public {
        require(msg.sender == contractOwner, "Only for contract owner");
        contentContract = addr;
        emit ContentContractChange(addr);
    }

    function getPeeringContract() public view returns (address addr) {
        return peeringContract;
    }

    // Set peering contract address
    function setPeeringContract(address addr) public {
        require(msg.sender == contractOwner, "Only for contract owner");
        if(addr == peeringContract) {
            return;
        }
        if (peeringContract != address(0)) {
            // transfer tokens from the old contract to the new one
            uint256 amount = balanceOf[peeringContract];
            require(amount > 0, "Balance of old peering contract is zero");
            balanceOf[peeringContract] = 0;
            balanceOf[addr] = amount;
            emit Transfer(peeringContract, addr, amount);
        } else {
            // Emit 20M SRFN to peering contract
            uint256 amount = 20000000;
            balanceOf[addr] = amount;
            emit Transfer(address(0), addr, amount);
            totalSupply = totalSupply.add(amount);
        }
        peeringContract = addr;
        emit PeeringContractChange(addr);
    }

    function getContentContract() public view returns (address addr) {
        return contentContract;
    }

    /* Payout to contract owner
    */
    function payout(address payable addr, uint256 amount) public {
        require(msg.sender == contractOwner, "Only for contract owner");
        addr.transfer(amount);
    }

    /* Burn tokens
    */
    function burn(uint256 amount) public {
        require(balanceOf[msg.sender] >= amount, "Insufficient funds");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        totalSupply = totalSupply.sub(amount);
    }

    // Update megabyte month cost
    function setMegabyteMonthCost(uint256 cost) public {
        require(msg.sender == contractOwner, "Only for contract owner");
        megabyteMonthCost = cost;
    }
}
