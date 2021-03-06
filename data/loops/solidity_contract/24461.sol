pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

}
 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract GDR is MintableToken {

  string public constant name = "Golden Resource";

  string public constant symbol = "GDR";

  uint8 public constant decimals = 18;

}

contract ReentrancyGuard {

   
  bool private rentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!rentrancy_lock);
    rentrancy_lock = true;
    _;
    rentrancy_lock = false;
  }
}

contract PreICO is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

   
  GDR public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;  

  uint256 public priceUSD;  

  uint256 public centRaised;

  uint256 public hardCap;

  address oracle;  
  address manager;

   
  mapping(address => uint) public balances;
  mapping(address => uint) public balancesInCent;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function PreICO(
  uint256 _startTime,
  uint256 _period,
  address _wallet,
  address _token,
  uint256 _priceUSD) public
  {
    require(_period != 0);
    require(_priceUSD != 0);
    require(_wallet != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = startTime + _period * 1 days;
    priceUSD = _priceUSD;
    rate = 12500000000000000;  
    wallet = _wallet;
    token = GDR(_token);
    hardCap = 1000000000;  
  }

   
  modifier saleIsOn() {
    bool withinPeriod = now >= startTime && now <= endTime;
    require(withinPeriod);
    _;
  }

  modifier isUnderHardCap() {
    require(centRaised <= hardCap);
    _;
  }

  modifier onlyOracle(){
    require(msg.sender == oracle);
    _;
  }

  modifier onlyOwnerOrManager(){
    require(msg.sender == manager || msg.sender == owner);
    _;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

   
  function getTokenAmount(uint256 centValue) internal view returns(uint256) {
    return centValue.mul(rate);
  }

   
   
  function forwardFunds(uint256 value) internal {
    wallet.transfer(value);
  }

  function finishPreSale() public onlyOwner {
    token.transferOwnership(owner);
    forwardFunds(this.balance);
  }

   
  function setOracle(address _oracle) public  onlyOwner {
    require(_oracle != address(0));
    oracle = _oracle;
  }

   
  function setManager(address _manager) public  onlyOwner {
    require(_manager != address(0));
    manager = _manager;
  }

  function changePriceUSD(uint256 _priceUSD) public  onlyOracle {
    require(_priceUSD != 0);
    priceUSD = _priceUSD;
  }

   
  function manualTransfer(address _to, uint _valueUSD) public saleIsOn isUnderHardCap onlyOwnerOrManager {
    uint256 centValue = _valueUSD * 100;
    uint256 tokensAmount = getTokenAmount(centValue);
    centRaised = centRaised.add(centValue);
    token.mint(_to, tokensAmount);
    balancesInCent[_to] = balancesInCent[_to].add(centValue);
  }

   
  function buyTokens(address beneficiary) saleIsOn isUnderHardCap nonReentrant public payable {
    require(beneficiary != address(0) && msg.value != 0);
    uint256 weiAmount = msg.value;
    uint256 centValue = weiAmount.div(priceUSD);
    uint256 tokens = getTokenAmount(centValue);
    centRaised = centRaised.add(centValue);
    token.mint(beneficiary, tokens);
    balances[msg.sender] = balances[msg.sender].add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds(weiAmount);
  }

  function () external payable {
    buyTokens(msg.sender);
  }
}