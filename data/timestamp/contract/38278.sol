pragma solidity ^0.4.12;

contract Altruism { 
    address owner = msg.sender;

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	bool public purchasingAllowed = false;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply = 100000000 ether;

    function name() constant returns (string) { return "Altruism Token"; }
    function symbol() constant returns (string) { return "ALTR"; }
    function decimals() constant returns (uint8) { return 18; }
    
    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }
    
    event AltruismMode(address indexed _from, uint256 _value, uint _timestamp);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function Altruism() {
        balances[owner] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) returns (bool success) {
        return transferring(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _amount) returns (bool success) {
        require(allowed[_from][msg.sender] > _amount);
        if (transferring(_from, _to, _amount)) {
            allowed[_from][msg.sender] -= _amount;
            return true;
        }
        return false;
    }
    
    function transferring(address _from, address _to, uint256 _amount) private returns (bool success){
        require(msg.data.length >= (2 * 32) + 4);
        require(_to != 0x0);                                 
        require(_amount > 0);
        require(balances[_from] >= _amount);            
        require(balances[_to] + _amount >= balances[_to]);  
        balances[_from] -= _amount;                     
        balances[_to] += _amount;                            
        Transfer(_from, _to, _amount);                   
        return true;
    }

     
     
    function approve(address _spender, uint256 _amount) returns (bool success) {
        if ((_amount != 0) && (allowed[msg.sender][_spender] != 0)) revert();
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function enablePurchasing() onlyOwner {
        purchasingAllowed = true;
    }
    function disablePurchasing() onlyOwner {
        purchasingAllowed = false;
    }

    function() payable {
        require(purchasingAllowed);
        
         
        var amount = msg.value;
        if (amount < 10 finney) { revert(); }

        var tokensIssued = amount * 1000;

         
        if (amount == 40 finney) {
            tokensIssued = 800 ether;
        }
 
        if (balances[owner] < tokensIssued) { revert(); }
        if (balances[msg.sender] + tokensIssued <= balances[msg.sender]) { revert(); }

        owner.transfer(amount);
        balances[owner] -= tokensIssued;
        balances[msg.sender] += tokensIssued;

        Transfer(owner, msg.sender, tokensIssued);
        if (amount >= 30 finney) {
             
            AltruismMode(msg.sender, amount, block.timestamp);
        }
    }
}