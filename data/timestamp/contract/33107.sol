 




 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 


 


 
library SafeMathLib {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}

 


 
contract PricingStrategy {

   
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

   
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

   
  function isPresalePurchase(address purchaser) public constant returns (bool) {
    return false;
  }

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}

 


 
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

   
  function isSane() public constant returns (bool);

   
  function finalizeCrowdsale();

}

 






 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract FractionalERC20 is ERC20 {

  uint public decimals;

}

 


 




 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}







 
contract CrowdsaleBase is Haltable {

   
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMathLib for uint;

   
  FractionalERC20 public token;

   
  PricingStrategy public pricingStrategy;

   
  FinalizeAgent public finalizeAgent;

   
  address public multisigWallet;

   
  uint public minimumFundingGoal;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public presaleWeiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  uint public ownerTestValue;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Refund(address investor, uint weiAmount);

   
  event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

   
  event Whitelisted(address addr, bool status);

   
  event EndsAtChanged(uint newEndsAt);

  State public testState;

  function CrowdsaleBase(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {

    owner = msg.sender;

    token = FractionalERC20(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;

     
    if(startsAt >= endsAt) {
        throw;
    }

     
    minimumFundingGoal = _minimumFundingGoal;
  }

   
  function() payable {
    throw;
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency internal returns(uint tokensBought) {

     
    if(getState() == State.PreFunding) {
       
      if(!earlyParticipantWhitelist[receiver]) {
        throw;
      }
    } else if(getState() == State.Funding) {
       
       
    } else {
       
      throw;
    }

    uint weiAmount = msg.value;

     
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

     
    require(tokenAmount != 0);

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

     
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    if(pricingStrategy.isPresalePurchase(receiver)) {
        presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
    }

     
    require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

    assignTokens(receiver, tokenAmount);

     
    if(!multisigWallet.send(weiAmount)) throw;

     
    Invested(receiver, weiAmount, tokenAmount, customerId);

    return tokenAmount;
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

     
    if(finalized) {
      throw;
    }

     
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

   
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;

     
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

   
  function setEndsAt(uint time) onlyOwner {

    if(now > time) {
      throw;  
    }

    if(startsAt > time) {
      throw;  
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

     
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }

   
  function setMultisig(address addr) public onlyOwner {

     
    if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      throw;
    }

    multisigWallet = addr;
  }

   
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) throw;
    loadedRefund = loadedRefund.plus(msg.value);
  }

   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.plus(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }

   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

   
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

   
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

   
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }

   
  function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }


   
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }


   
   
   

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);

   
  function isCrowdsaleFull() public constant returns (bool);

   
  function assignTokens(address receiver, uint tokenAmount) internal;
}



 
contract Crowdsale is CrowdsaleBase {

   
  bool public requireCustomerId;

   
  bool public requiredSignedAddress;

   
  address public signerAddress;

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) CrowdsaleBase(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal) {
  }

   
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10**token.decimals();
    uint weiAmount = weiPrice * fullTokens;  

    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

    assignTokens(receiver, tokenAmount);

     
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

   
  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress) throw;
     if(customerId == 0) throw;   
     investInternal(addr, customerId);
  }

   
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if(requiredSignedAddress) throw;  
    if(customerId == 0) throw;   
    investInternal(addr, customerId);
  }

   
  function invest(address addr) public payable {
    if(requireCustomerId) throw;  
    if(requiredSignedAddress) throw;  
    investInternal(addr, 0);
  }

   
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    investWithSignedAddress(msg.sender, customerId, v, r, s);
  }

   
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

   
  function buy() public payable {
    invest(msg.sender);
  }

   
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
    requiredSignedAddress = value;
    signerAddress = _signerAddress;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

}



 
contract PreICOProxyBuyer is Ownable, Haltable {
  using SafeMath for uint;

   
  uint public investorCount;

   
  uint public weiRaised;

   
  address[] public investors;

   
  mapping(address => uint) public balances;

   
  mapping(address => uint) public claimed;

   
  uint public freezeEndsAt;

   
  uint public weiMinimumLimit;

   
  uint public weiMaximumLimit;

   
  uint public weiCap;

   
  uint public tokensBought;

    
  uint public claimCount;

  uint public totalClaimed;

   
  uint public timeLock;

   
  bool public forcedRefund;

   
  Crowdsale public crowdsale;

   
  enum State{Unknown, Funding, Distributing, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Refunded(address investor, uint value);

   
  event TokensBoughts(uint count);

   
  event Distributed(address investor, uint count);

   
  function PreICOProxyBuyer(address _owner, uint _freezeEndsAt, uint _weiMinimumLimit, uint _weiMaximumLimit, uint _weiCap) {

    owner = _owner;

     
    if(_freezeEndsAt == 0) {
      throw;
    }

     
    if(_weiMinimumLimit == 0) {
      throw;
    }

    if(_weiMaximumLimit == 0) {
      throw;
    }

    weiMinimumLimit = _weiMinimumLimit;
    weiMaximumLimit = _weiMaximumLimit;
    weiCap = _weiCap;
    freezeEndsAt = _freezeEndsAt;
  }

   
  function getToken() public constant returns(FractionalERC20) {
    if(address(crowdsale) == 0)  {
      throw;
    }

    return crowdsale.token();
  }

   
  function invest(uint128 customerId) private {

     
    if(getState() != State.Funding) throw;

    if(msg.value == 0) throw;  

    address investor = msg.sender;

    bool existing = balances[investor] > 0;

    balances[investor] = balances[investor].add(msg.value);

     
    if(balances[investor] < weiMinimumLimit || balances[investor] > weiMaximumLimit) {
      throw;
    }

     
    if(!existing) {
      investors.push(investor);
      investorCount++;
    }

    weiRaised = weiRaised.add(msg.value);
    if(weiRaised > weiCap) {
      throw;
    }

     
     
    Invested(investor, msg.value, 0, customerId);
  }

  function buyWithCustomerId(uint128 customerId) public stopInEmergency payable {
    invest(customerId);
  }

  function buy() public stopInEmergency payable {
    invest(0x0);
  }


   
  function buyForEverybody() stopNonOwnersInEmergency public {

    if(getState() != State.Funding) {
       
      throw;
    }

     
    if(address(crowdsale) == 0) throw;

     
    crowdsale.invest.value(weiRaised)(address(this));

     
    tokensBought = getToken().balanceOf(address(this));

    if(tokensBought == 0) {
       
      throw;
    }

    TokensBoughts(tokensBought);
  }

   
  function getClaimAmount(address investor) public constant returns (uint) {

     
    if(getState() != State.Distributing) {
      throw;
    }
    return balances[investor].mul(tokensBought) / weiRaised;
  }

   
  function getClaimLeft(address investor) public constant returns (uint) {
    return getClaimAmount(investor).sub(claimed[investor]);
  }

   
  function claimAll() {
    claim(getClaimLeft(msg.sender));
  }

   
  function claim(uint amount) stopInEmergency {
    require (now > timeLock);

    address investor = msg.sender;

    if(amount == 0) {
      throw;
    }

    if(getClaimLeft(investor) < amount) {
       
      throw;
    }

     
    if(claimed[investor] == 0) {
      claimCount++;
    }

    claimed[investor] = claimed[investor].add(amount);
    totalClaimed = totalClaimed.add(amount);
    getToken().transfer(investor, amount);

    Distributed(investor, amount);
  }

   
  function refund() stopInEmergency {

     
    if(getState() != State.Refunding) throw;

    address investor = msg.sender;
    if(balances[investor] == 0) throw;
    uint amount = balances[investor];
    delete balances[investor];
    if(!(investor.call.value(amount)())) throw;
    Refunded(investor, amount);
  }

   
  function setCrowdsale(Crowdsale _crowdsale) public onlyOwner {
    crowdsale = _crowdsale;

     
    if(!crowdsale.isCrowdsale()) true;
  }

   
   
  function setTimeLock(uint _timeLock) public onlyOwner {
    timeLock = _timeLock;
  }

   
   
  function forceRefund() public onlyOwner {
    forcedRefund = true;
  }

   
   
   
  function loadRefund() public payable {
    if(getState() != State.Refunding) throw;
  }

   
  function getState() public returns(State) {
    if (forcedRefund)
      return State.Refunding;

    if(tokensBought == 0) {
      if(now >= freezeEndsAt) {
         return State.Refunding;
      } else {
        return State.Funding;
      }
    } else {
      return State.Distributing;
    }
  }

   
  function isPresale() public constant returns (bool) {
    return true;
  }

   
  function() payable {
    throw;
  }
}