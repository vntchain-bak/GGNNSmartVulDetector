pragma solidity ^0.4.14;


 


contract ERC20Token {
     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
     
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

     
    function totalSupply() constant returns (uint256 supply);

     
    function balanceOf(address _owner) constant returns (uint256 balance);

     
    function transfer(address _to, uint256 _value) returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

     
     
    function approve(address _spender, uint256 _value) returns (bool success);

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}


contract DeepCoinToken is ERC20Token {
    address public initialOwner;

    uint256 public supply = 100000000 * 60 * 10 ** 18;   
    string  public name = "Deepfin Coin";

    uint8   public decimals = 18;

    string  public symbol = 'DFC';

    string  public version = 'v0.1';

    bool    public transfersEnabled = true;

    uint    public creationBlock;

    uint    public creationTime;

    mapping (address => uint256) balance;

    mapping (address => mapping (address => uint256)) m_allowance;

    mapping (address => uint) jail;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function DeepCoinToken() {
        initialOwner = msg.sender;
        balance[msg.sender] = supply;
        creationBlock = block.number;
        creationTime = block.timestamp;
    }

    function balanceOf(address _account) constant returns (uint) {
        return balance[_account];
    }

    function totalSupply() constant returns (uint) {
        return supply;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (!transfersEnabled) revert();
        if (jail[msg.sender] >= block.timestamp) revert();

        return doTransfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        if (!transfersEnabled) revert();
        if (jail[msg.sender] >= block.timestamp || jail[_to] >= block.timestamp || jail[_from] >= block.timestamp) revert();

        if (allowance(_from, msg.sender) < _value) return false;

        m_allowance[_from][msg.sender] -= _value;

        if (!(doTransfer(_from, _to, _value))) {
            m_allowance[_from][msg.sender] += _value;
            return false;
        }
        else {
            return true;
        }
    }

    function doTransfer(address _from, address _to, uint _value) internal returns (bool success) {
        if (balance[_from] >= _value && balance[_to] + _value >= balance[_to]) {
            balance[_from] -= _value;
            balance[_to] += _value;
            Transfer(_from, _to, _value);
            return true;
        }
        else {
            return false;
        }
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        if (!transfersEnabled) revert();
        if (jail[msg.sender] >= block.timestamp || jail[_spender] >= block.timestamp) revert();

         
        if ((_value != 0) && (allowance(msg.sender, _spender) != 0)) revert();

        m_allowance[msg.sender][_spender] = _value;

        Approval(msg.sender, _spender, _value);

        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256) {
        if (!transfersEnabled) revert();

        return m_allowance[_owner][_spender];
    }

    function enableTransfers(bool _transfersEnabled) returns (bool) {
        if (msg.sender != initialOwner) revert();
        transfersEnabled = _transfersEnabled;
        return transfersEnabled;
    }

    function catchYou(address _target, uint _timestamp) returns (uint) {
        if (msg.sender != initialOwner) revert();
        if (!transfersEnabled) revert();

        jail[_target] = _timestamp;

        return jail[_target];
    }
}