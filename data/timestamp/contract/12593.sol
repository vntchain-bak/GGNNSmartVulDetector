pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

 

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(this.balance);
  }
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract ChartToken is StandardToken, BurnableToken, Ownable, HasNoEther {
    string public constant name = "BetOnChart token";
    string public constant symbol = "CHART";
    uint8 public constant decimals = 18;  
    bool public saleFinished;
    address public saleAgent;
    address private wallet;

    
    event SaleAgent(address);

    
    constructor(address _wallet) public {
        require(_wallet != address(0));

        totalSupply_ = 50*1e6*(1 ether);
        saleFinished = false;
        balances[_wallet] = totalSupply_;
        wallet = _wallet;
        saleAgent = address(0);
    }

    
    modifier onlyOwnerOrSaleAgent() {
        require(msg.sender == owner || msg.sender == saleAgent);
        _;
    }

    
    modifier whenSaleFinished() {
        require(saleFinished || msg.sender == saleAgent || msg.sender == wallet );
        _;
    }

    
    modifier whenSaleNotFinished() {
        require(!saleFinished);
        _;
    }

    
    function setSaleAgent(address _agent) public whenSaleNotFinished onlyOwner {
        saleAgent = _agent;
        emit SaleAgent(_agent);
    }

    
    function finishSale() public onlyOwnerOrSaleAgent {
        saleAgent = address(0);
        emit SaleAgent(saleAgent);
        saleFinished = true;
    }

    
    function transfer(address _to, uint256 _value) public whenSaleFinished returns (bool) {
        return super.transfer(_to, _value);
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public whenSaleFinished returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public openingTime;
    uint256 public closingTime;

     
    modifier onlyWhileOpen {
         
        require(block.timestamp >= openingTime && block.timestamp <= closingTime);
        _;
    }

     
    constructor(uint256 _openingTime, uint256 _closingTime) public {
        require(_closingTime >= _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
         
        return block.timestamp > closingTime;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    onlyWhileOpen
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

}

 

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    
    struct Contract
    {
        uint256 rate;    
        uint256 minInvestment;  
    }

    mapping(address => bool) public whitelist;
    mapping(address => Contract) public contracts;

     
    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }

     
    modifier isMinimalInvestment(address _beneficiary, uint256 _weiAmount) {
        require(_weiAmount >= contracts[_beneficiary].minInvestment);
        _;
    }

     
    function addToWhitelist(address _beneficiary, uint16 _bonus, uint256 _minInvestment) external onlyOwner {
        require(_bonus <= 300);

        whitelist[_beneficiary] = true;
        Contract storage beneficiaryContract = contracts[_beneficiary];
        beneficiaryContract.rate = rate.add(rate.mul(_bonus).div(100));
        beneficiaryContract.minInvestment = _minInvestment.mul(1 ether);
    }

     
    function addManyToWhitelist(address[] _beneficiaries, uint16 _bonus, uint256 _minInvestment) external onlyOwner {
        require(_bonus <= 300);

        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
            Contract storage beneficiaryContract = contracts[_beneficiaries[i]];
            beneficiaryContract.rate = rate.add(rate.mul(_bonus).div(100));
            beneficiaryContract.minInvestment = _minInvestment.mul(1 ether);
        }
    }

     
    function removeFromWhitelist(address _beneficiary) external onlyOwner {
        whitelist[_beneficiary] = false;
    }

     
    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount
    )
    internal
    isWhitelisted(_beneficiary)
    isMinimalInvestment(_beneficiary, _weiAmount)
    {
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256)
    {
        return _weiAmount.mul(contracts[msg.sender].rate);
    }
}

 

 
contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

   
  constructor(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

   
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

 

contract ChartPresale is WhitelistedCrowdsale, AllowanceCrowdsale, TimedCrowdsale, CappedCrowdsale {
    using SafeMath for uint256;

    string public constant name = "BetOnChart token presale";

    constructor(uint256 _rate, address _tokenWallet, address _ethWallet, ChartToken _token, uint256 _cap, uint256 _openingTime, uint256 _closingTime) public
    Crowdsale(_rate, _ethWallet, _token)
    AllowanceCrowdsale(_tokenWallet)
    TimedCrowdsale(_openingTime, _closingTime)
    CappedCrowdsale(_cap) {}
}