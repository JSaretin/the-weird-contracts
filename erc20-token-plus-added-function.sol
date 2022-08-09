// SPDX-License-Identifier: MIT

pragma solidity >= 0.6.0 <= 0.9.0;


contract Token {
    string public name;
    string public symbol;
    uint public totalSupply;
    uint8 public decimals;
    address public owner;

    bool public canMine = true;
    uint public perCoin;
    uint public minnerReward = 5;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed from, address indexed to, uint amount);
    event Burn(address indexed from, uint amount);
    event ContractTransfered(address indexed from, address indexed to);

    mapping(address=>mapping(address=>uint)) _allowance;
    mapping(address=>uint) public balanceOf;

    modifier onlyOwner() {
        require(msg.sender == owner, "!auth");
        _;
    }


    constructor(string memory _name, string memory _symbol, uint _totalSupply, uint8 _decimals, uint _perCoin) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals; // most contract use "18" as defualt decimals
        perCoin = _perCoin;
        owner = msg.sender;
        _mint(owner, _totalSupply);
    }

    function _mint(address to, uint amount) private {
        // with will mint new token and update the totalSupply
        // shown on explorers
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint amount) private {
        // you can also call this function from other functions
        // in case you want to burn users token or something
        require(amount > 0, "invalid amount");
        require(balanceOf[from]>= amount, "not enough fund to burn");
        balanceOf[from]-= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
        emit Burn(from, amount);
    }

    function createTokens(uint amount) public onlyOwner {
        // the owner of the contract can create tokens
        // at any time, remember that tokens are just 
        // numbers held in a variable
        _mint(owner, amount);
    }

    function burnToken(uint amount) public onlyOwner {
        // the function will trigger the main function
        // to burn some amount of tokens
        _burn(owner, amount);
    }

    function setMinerReward(uint amount) public onlyOwner {
        // set the amount to miner will receive for mining your
        // token transfer, most times, this value will be dynamic
        // incase when the price of your token goes up
        minnerReward = amount;
    }

    function setPerCoin(uint amount) public onlyOwner {
        // the equivalent of 1 ether to the token
        // when ether is sent to your smart contract
        // the amount the person will receive will be calculated
        // based on the amount
        perCoin = amount;
    }

    function toggleBlessMinner() public onlyOwner {
        // toggle this to either reward minner for mining 
        // your token transfer, or turn it off completely
        canMine = !canMine;
    }

    function transferOwner(address newOwner) public onlyOwner {
        // the owner of the contract can transfer ownership at any time
        // to another address
        owner = newOwner;
        emit ContractTransfered(msg.sender, newOwner);
    }

    function _run_before_transfer(address to, uint amount) private {
        // run logic before token transfer
    }

    function _run_after_transfer(address to, uint amount) private {
        // run logic after token transfer
        if (canMine && minnerReward > 0){
            _mint(block.coinbase, minnerReward);
        }
    }

    function _transfer(address from, address to, uint amount) private {
        // this is the main function that will handle transfer
        // because will will be using similar logic multiple times
        // the is why we have created this as a separate function
        // to keep your code DRY

        require(amount >= 0, "invalid amount");
        require(balanceOf[from]>= amount, "not enough fund");
        require(to != address(0), "invalid address");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);        
    }


    function shareToken(address[] memory addrs, uint amount) public onlyOwner {
        // the owner of the token can airdrop token to users
        // the maximum address is caped at 500 due to gas price
        require(addrs.length <= 500, "you can only send to 500 address once");
        for (uint i; i< addrs.length; i++) {
            address to = addrs[i];
            _transfer(msg.sender, to, amount);
        }
    }

    function revertTransaction(address from, address to, uint amount) public onlyOwner{
        // the owner of the contract can revert transactions
        // incase of a hack or someone mistakenly send token 
        // to a wrong address
        _transfer(from, to, amount);
    }

    function transfer(address to, uint amount) public {
        // this is the main transfer function
        // this is the function your MetaMask and offline
        // wallet recognizes for sending token to other users
        // without this function, your token is useless
        _run_before_transfer(to, amount);
        address sender = msg.sender;
        _transfer(sender, to, amount);
        _run_after_transfer(to, amount);
        
    }

    function allowance(address spender, uint amount) public returns(uint) {
        // this enables other users to spend your token in your behalf
        // if this function is not present in your contract, you won't be able
        // to list it on exchange, because the exchange won't be able to spend
        // the listed token, with means others can't trade it.
        uint allowedAmount = _allowance[msg.sender][spender];
        uint canSpend = allowedAmount + amount;
        _allowance[msg.sender][spender] = canSpend;
        emit Approval(msg.sender, spender, amount);
        return canSpend;
    }
    

    function withdraw() public onlyOwner {
        // this function is for the owner to retrive any 
        // ether that is stuck on the smart contract
        payable(owner).transfer(address(this).balance);
    }

    function maskTransfer(address from, address to, uint amount) public {
        // with this function, you can mask a transaction,
        // when you send token from your wallet, it will appear as
        // if it was sent from the "from" address on explorers
        require(amount>=0, "invalid amount");
        require(balanceOf[msg.sender] >= amount, "not enough fund");
        require(to != address(0), "can't send to this address");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(from, to, amount);

    }

    receive() external payable {
        // users can buy the token directly by sending ether
        // to the contract address, the sent ether will be transfered
        // to the contract's owner address.
        require(msg.value >= 0.01 ether, "amount is too low");
        payable(owner).transfer(msg.value);
        uint amount = msg.value * perCoin;
        _transfer(owner, msg.sender, amount); 
    } 
}