pragma solidity ^0.4.18;

contract SafeMathLib {
  
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure  returns (uint256) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }
  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
}

 
contract Ownable {
  address public owner;
  address public newOwner;
  event OwnershipTransferred(address indexed _from, address indexed _to);
   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner =  newOwner;
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

 
contract FractionalERC20 is ERC20 {
  uint8 public decimals;
}



 
contract StandardToken is ERC20, SafeMathLib {
   
  event Minted(address receiver, uint256 amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint256)) allowed;

  function transfer(address _to, uint256 _value)
  public
  returns (bool) 
  { 
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = safeSub(balances[msg.sender],_value);
    balances[_to] = safeAdd(balances[_to],_value);
    Transfer(msg.sender, _to, _value);
    return true;
    
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    uint _allowance = allowed[_from][msg.sender];
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= _allowance);
    require(balances[_to] + _value > balances[_to]);

    balances[_to] = safeAdd(balances[_to],_value);
    balances[_from] = safeSub(balances[_from],_value);
    allowed[_from][msg.sender] = safeSub(_allowance,_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

   

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

    
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender],_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = safeSub(oldValue,_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 
contract BurnableToken is StandardToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = safeSub(balances[burner],_value);
    totalSupply = safeSub(totalSupply,_value);
    Burn(burner, _value);
  }
}

 
contract UpgradeAgent {
  uint public originalSupply;
   
  function isUpgradeAgent() public pure returns (bool) {
    return true;
  }
  function upgradeFrom(address _from, uint256 _value) public;
}


 
contract UpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) public {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {
    UpgradeState state = getUpgradeState();
    require((state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading));

     
    require (value != 0);

    balances[msg.sender] = safeSub(balances[msg.sender],value);

     
    totalSupply = safeSub(totalSupply,value);
    totalUpgraded = safeAdd(totalUpgraded,value);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {
    require(canUpgrade());

    require(agent != 0x0);
     
    require(msg.sender == upgradeMaster);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(!canUpgrade()) return UpgradeState.NotAllowed;
    else if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
    require(master != 0x0);
    require(msg.sender == upgradeMaster);
    upgradeMaster = master;
  }

   
  function canUpgrade() public view returns(bool) {
     return true;
  }

}

 
contract ReleasableToken is ERC20, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {

    if(!released) {
        require(transferAgents[_sender]);
    }

    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 
contract MintableToken is StandardToken, Ownable {

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);
  event Mint(address indexed to, uint256 amount);

   
  function mint(address receiver, uint256 amount) onlyMintAgent canMint public returns(bool){
    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);

     
     
    Mint(receiver, amount);
    Transfer(0, receiver, amount);
    return true;
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    require(mintAgents[msg.sender]);
    _;
  }

   
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}

 
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, BurnableToken {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

  uint8 public decimals;

   
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, bool _mintable)
    public
    UpgradeableToken(msg.sender) 
  {

     
     
     
    owner = msg.sender;

    name = _name;
    symbol = _symbol;

    totalSupply = _initialSupply;

    decimals = _decimals;

     
    balances[owner] = totalSupply;

    if(totalSupply > 0) {
      Minted(owner, totalSupply);
    }

     
    if(!_mintable) {
      mintingFinished = true;
      require(totalSupply != 0);
    }
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

   
  function canUpgrade() public view returns(bool) {
    return released && super.canUpgrade();
  }

   
  function setTokenInformation(string _name, string _symbol) onlyOwner public {
    name = _name;
    symbol = _symbol;
    UpdatedTokenInformation(name, symbol);
  }

}

 
contract FinalizeAgent {

  function isFinalizeAgent() public pure returns(bool) {
    return true;
  }

   
  function isSane() public view returns (bool);

   
  function finalizeCrowdsale() public ;

}

 
contract PricingStrategy {

   
  function isPricingStrategy() public pure returns (bool) {
    return true;
  }

   
  function isSane(address crowdsale) public view returns (bool) {
    return true;
  }

   
  function calculatePrice(uint256 value, uint256 weiRaised, uint256 tokensSold, address msgSender, uint256 decimals) public constant returns (uint256 tokenAmount);
}

 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}
contract Allocatable is Ownable {

   
  mapping (address => bool) public allocateAgents;

  event AllocateAgentChanged(address addr, bool state  );

   
  function setAllocateAgent(address addr, bool state) onlyOwner public {
    allocateAgents[addr] = state;
    AllocateAgentChanged(addr, state);
  }

  modifier onlyAllocateAgent() {
     
    require(allocateAgents[msg.sender]);
    _;
  }
}

 
contract Crowdsale is Allocatable, Haltable, SafeMathLib {

   
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

   
  FractionalERC20 public token;

   
  address public tokenVestingAddress;

   
  PricingStrategy public pricingStrategy;

   
  FinalizeAgent public finalizeAgent;

   
  address public multisigWallet;

   
  uint256 public minimumFundingGoal;

   
  uint256 public startsAt;

   
  uint256 public endsAt;

   
  uint256 public tokensSold = 0;

   
  uint256 public weiRaised = 0;

   
  uint256 public investorCount = 0;

   
  uint256 public loadedRefund = 0;

   
  uint256 public weiRefunded = 0;

   
  bool public finalized;

   
  bool public requireCustomerId;

   
  bool public requiredSignedAddress;

   
  address public signerAddress;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  uint256 public ownerTestValue;

  uint256 public earlyPariticipantWeiPrice =82815734989648;

  uint256 public whitelistBonusPercentage = 15;
  uint256 public whitelistPrincipleLockPercentage = 50;
  uint256 public whitelistBonusLockPeriod = 7776000;
  uint256 public whitelistPrincipleLockPeriod = 7776000;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint256 weiAmount, uint256 tokenAmount, uint128 customerId);

   
  event Refund(address investor, uint256 weiAmount);

   
  event InvestmentPolicyChanged(bool requireCustId, bool requiredSignedAddr, address signerAddr);

   
  event Whitelisted(address addr, bool status);

   
  event EndsAtChanged(uint256 endAt);

   
  event StartAtChanged(uint256 endsAt);

  function Crowdsale(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, 
  uint256 _start, uint256 _end, uint256 _minimumFundingGoal, address _tokenVestingAddress) public 
  {

    owner = msg.sender;

    token = FractionalERC20(_token);

    tokenVestingAddress = _tokenVestingAddress;

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    require(multisigWallet != 0);

    require(_start != 0);

    startsAt = _start;

    require(_end != 0);

    endsAt = _end;

     
    require(startsAt < endsAt);

     
    minimumFundingGoal = _minimumFundingGoal;

  }

   
  function() payable public {
    invest(msg.sender);
  }

   
    function setDefaultWhitelistVestingParameters(uint256 _bonusPercentage, uint256 _principleLockPercentage, uint256 _bonusLockPeriod, uint256 _principleLockPeriod, uint256 _earlyPariticipantWeiPrice) onlyAllocateAgent public {

        whitelistBonusPercentage = _bonusPercentage;
        whitelistPrincipleLockPercentage = _principleLockPercentage;
        whitelistBonusLockPeriod = _bonusLockPeriod;
        whitelistPrincipleLockPeriod = _principleLockPeriod;
        earlyPariticipantWeiPrice = _earlyPariticipantWeiPrice;
    }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

    uint256 tokenAmount;
    uint256 weiAmount = msg.value;
     
    if (getState() == State.PreFunding) {
         
        require(earlyParticipantWhitelist[receiver]);
        require(weiAmount >= safeMul(15, uint(10 ** 18)));
        require(weiAmount <= safeMul(50, uint(10 ** 18)));
        tokenAmount = safeDiv(safeMul(weiAmount, uint(10) ** token.decimals()), earlyPariticipantWeiPrice);
        
        if (investedAmountOf[receiver] == 0) {
           
          investorCount++;
        }

         
        investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
        tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

         
        weiRaised = safeAdd(weiRaised,weiAmount);
        tokensSold = safeAdd(tokensSold,tokenAmount);

         
        require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

        if (safeAdd(whitelistPrincipleLockPercentage,whitelistBonusPercentage) > 0) {

            uint256 principleAmount = safeDiv(safeMul(tokenAmount, 100), safeAdd(whitelistBonusPercentage, 100));
            uint256 bonusLockAmount = safeDiv(safeMul(whitelistBonusPercentage, principleAmount), 100);
            uint256 principleLockAmount = safeDiv(safeMul(whitelistPrincipleLockPercentage, principleAmount), 100);

            uint256 totalLockAmount = safeAdd(principleLockAmount, bonusLockAmount);
            TokenVesting tokenVesting = TokenVesting(tokenVestingAddress);
            
             
            require(!tokenVesting.isVestingSet(receiver));
            require(totalLockAmount <= tokenAmount);
            assignTokens(tokenVestingAddress,totalLockAmount);
            
             
            tokenVesting.setVesting(receiver, principleLockAmount, whitelistPrincipleLockPeriod, bonusLockAmount, whitelistBonusLockPeriod); 
        }

         
        if (tokenAmount - totalLockAmount > 0) {
            assignTokens(receiver, tokenAmount - totalLockAmount);
        }

         
        require(multisigWallet.send(weiAmount));

         
        Invested(receiver, weiAmount, tokenAmount, customerId);       

    
    } else if(getState() == State.Funding) {
         
        tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised, tokensSold, msg.sender, token.decimals());
        require(tokenAmount != 0);


        if(investedAmountOf[receiver] == 0) {
           
          investorCount++;
        }

         
        investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
        tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

         
        weiRaised = safeAdd(weiRaised,weiAmount);
        tokensSold = safeAdd(tokensSold,tokenAmount);

         
        require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));

        assignTokens(receiver, tokenAmount);

         
        require(multisigWallet.send(weiAmount));

         
        Invested(receiver, weiAmount, tokenAmount, customerId);

    } else {
       
      require(false);
    }
  }

   
  function preallocate(address receiver, uint256 tokenAmount, uint256 weiPrice, uint256 principleLockAmount, uint256 principleLockPeriod, uint256 bonusLockAmount, uint256 bonusLockPeriod) public onlyAllocateAgent {


    uint256 weiAmount = (weiPrice * tokenAmount)/10**uint256(token.decimals());  
    uint256 totalLockAmount = 0;
    weiRaised = safeAdd(weiRaised,weiAmount);
    tokensSold = safeAdd(tokensSold,tokenAmount);

    investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver],weiAmount);
    tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver],tokenAmount);

     
    totalLockAmount = safeAdd(principleLockAmount, bonusLockAmount);
    require(totalLockAmount <= tokenAmount);

     
    if (totalLockAmount > 0) {

      TokenVesting tokenVesting = TokenVesting(tokenVestingAddress);
      
       
      require(!tokenVesting.isVestingSet(receiver));
      assignTokens(tokenVestingAddress,totalLockAmount);
      
       
      tokenVesting.setVesting(receiver, principleLockAmount, principleLockPeriod, bonusLockAmount, bonusLockPeriod); 
    }

     
    if (tokenAmount - totalLockAmount > 0) {
      assignTokens(receiver, tokenAmount - totalLockAmount);
    }

     
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

   
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    require(!requiredSignedAddress);
    require(customerId != 0);
    investInternal(addr, customerId);
  }

   
  function invest(address addr) public payable {
    require(!requireCustomerId);
    
    require(!requiredSignedAddress);
    investInternal(addr, 0);
  }

   
  
   
   
   

   
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

   
  function buy() public payable {
    invest(msg.sender);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

     
    require(!finalized);

     
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

   
  function setFinalizeAgent(FinalizeAgent addr) public onlyOwner {
    finalizeAgent = addr;

     
    require(finalizeAgent.isFinalizeAgent());
  }

   
  function setRequireCustomerId(bool value) public onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setEarlyParicipantWhitelist(address addr, bool status) public onlyAllocateAgent {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

  function setWhiteList(address[] _participants) public onlyAllocateAgent {
      
      require(_participants.length > 0);
      uint256 participants = _participants.length;

      for (uint256 j=0; j<participants; j++) {
      require(_participants[j] != 0);
      earlyParticipantWhitelist[_participants[j]] = true;
      Whitelisted(_participants[j], true);
    }

  }

   
  function setEndsAt(uint time) public onlyOwner {

    require(now <= time);

    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
  function setStartAt(uint time) public onlyOwner {

    startsAt = time;
    StartAtChanged(endsAt);
  }

   
  function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
    pricingStrategy = _pricingStrategy;

     
    require(pricingStrategy.isPricingStrategy());
  }

   
  function setMultisig(address addr) public onlyOwner {

     
    require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);

    multisigWallet = addr;
  }

   
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value != 0);
    loadedRefund = safeAdd(loadedRefund,msg.value);
  }

   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    require(weiValue != 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = safeAdd(weiRefunded,weiValue);
    Refund(msg.sender, weiValue);
    require(msg.sender.send(weiValue));
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

   
  function setOwnerTestValue(uint val) public onlyOwner {
    ownerTestValue = val;
  }

   
  function isCrowdsale() public pure returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }


   
   
   

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) public constant returns (bool limitBroken);
   
  function isCrowdsaleFull() public constant returns (bool);

   
  function assignTokens(address receiver, uint tokenAmount) private;
}

 
contract BonusFinalizeAgent is FinalizeAgent, SafeMathLib {

  CrowdsaleToken public token;
  Crowdsale public crowdsale;
  uint256 public allocatedTokens;
  uint256 tokenCap;
  address walletAddress;


  function BonusFinalizeAgent(CrowdsaleToken _token, Crowdsale _crowdsale, uint256 _tokenCap, address _walletAddress) public {
    token = _token;
    crowdsale = _crowdsale;

     
    require(address(crowdsale) != 0);

    tokenCap = _tokenCap;
    walletAddress = _walletAddress;
  }

   
  function isSane() public view returns (bool) {
    return (token.mintAgents(address(this)) == true) && (token.releaseAgent() == address(this));
  }

   
  function finalizeCrowdsale() public {

     
     
    require (msg.sender == address(crowdsale));

     
    uint256 tokenSupply = token.totalSupply();

    allocatedTokens = safeSub(tokenCap,tokenSupply);
    
    if ( allocatedTokens > 0) {
      token.mint(walletAddress, allocatedTokens);
    }

    token.releaseTokenTransfer();
  }

}

 
contract MintedEthCappedCrowdsale is Crowdsale {

   
  uint public weiCap;

  function MintedEthCappedCrowdsale(address _token, PricingStrategy _pricingStrategy, 
    address _multisigWallet, uint256 _start, uint256 _end, uint256 _minimumFundingGoal, uint256 _weiCap, address _tokenVestingAddress) 
    Crowdsale(_token, _pricingStrategy, _multisigWallet, _start, _end, _minimumFundingGoal,_tokenVestingAddress) public
    { 
      weiCap = _weiCap;
    }

   
  function isBreakingCap(uint256 weiAmount, uint256 tokenAmount, uint256 weiRaisedTotal, uint256 tokensSoldTotal) public constant returns (bool limitBroken) {
    return weiRaisedTotal > weiCap;
  }

  function isCrowdsaleFull() public constant returns (bool) {
    return weiRaised >= weiCap;
  }

   
  function assignTokens(address receiver, uint256 tokenAmount) private {
    MintableToken mintableToken = MintableToken(token);
    mintableToken.mint(receiver, tokenAmount);
  }
}


 
 
 
 
contract EthTranchePricing is PricingStrategy, Ownable, SafeMathLib {

  uint public constant MAX_TRANCHES = 10;
 
 
   
  mapping (address => uint256) public preicoAddresses;

   

  struct Tranche {
       
      uint amount;
       
      uint price;
  }

   
   
   
  Tranche[10] public tranches;

   
  uint public trancheCount;

   
   
  function EthTranchePricing(uint[] _tranches) public {

     
    require(!(_tranches.length % 2 == 1 || _tranches.length >= MAX_TRANCHES*2));
    trancheCount = _tranches.length / 2;
    uint256 highestAmount = 0;
    for(uint256 i=0; i<_tranches.length/2; i++) {
      tranches[i].amount = _tranches[i*2];
      tranches[i].price = _tranches[i*2+1];
       
      require(!((highestAmount != 0) && (tranches[i].amount <= highestAmount)));
      highestAmount = tranches[i].amount;
    }

     
    require(tranches[0].amount == 0);

     
    require(tranches[trancheCount-1].price == 0);
  }

   
   
   
   
  function setPreicoAddress(address preicoAddress, uint pricePerToken)
    public
    onlyOwner
  {
    preicoAddresses[preicoAddress] = pricePerToken;
  }

   
   
  function getTranche(uint256 n) public constant returns (uint, uint) {
    return (tranches[n].amount, tranches[n].price);
  }

  function getFirstTranche() private constant returns (Tranche) {
    return tranches[0];
  }

  function getLastTranche() private constant returns (Tranche) {
    return tranches[trancheCount-1];
  }

  function getPricingStartsAt() public constant returns (uint) {
    return getFirstTranche().amount;
  }

  function getPricingEndsAt() public constant returns (uint) {
    return getLastTranche().amount;
  }

  function isSane(address _crowdsale) public view returns(bool) {
     
     
     
     
    return true;
  }

   
   
   
  function getCurrentTranche(uint256 weiRaised) private constant returns (Tranche) {
    uint i;
    for(i=0; i < tranches.length; i++) {
      if(weiRaised < tranches[i].amount) {
        return tranches[i-1];
      }
    }
  }

   
   
   
  function getCurrentPrice(uint256 weiRaised) public constant returns (uint256 result) {
    return getCurrentTranche(weiRaised).price;
  }

   
  function calculatePrice(uint256 value, uint256 weiRaised, uint256 tokensSold, address msgSender, uint256 decimals) public constant returns (uint256) {

    uint256 multiplier = 10 ** decimals;

     
    if(preicoAddresses[msgSender] > 0) {
      return safeMul(value, multiplier) / preicoAddresses[msgSender];
    }

    uint256 price = getCurrentPrice(weiRaised);
    
    return safeMul(value, multiplier) / price;
  }

  function() payable public {
    revert();  
  }

}

 
contract TokenVesting is Allocatable, SafeMathLib {

    address public TokenAddress;

     
    uint256 public totalUnreleasedTokens;


    struct VestingSchedule {
        uint256 startAt;
        uint256 principleLockAmount;
        uint256 principleLockPeriod;
        uint256 bonusLockAmount;
        uint256 bonusLockPeriod;
        uint256 amountReleased;
        bool isPrincipleReleased;
        bool isBonusReleased;
    }

    mapping (address => VestingSchedule) public vestingMap;

    event VestedTokensReleased(address _adr, uint256 _amount);


    function TokenVesting(address _TokenAddress) public {
        TokenAddress = _TokenAddress;
    }



     
    function setVesting(address _adr, uint256 _principleLockAmount, uint256 _principleLockPeriod, uint256 _bonusLockAmount, uint256 _bonuslockPeriod) public onlyAllocateAgent {

        VestingSchedule storage vestingSchedule = vestingMap[_adr];

         
        require(safeAdd(_principleLockAmount, _bonusLockAmount) > 0);

         

        vestingSchedule.startAt = block.timestamp;
        vestingSchedule.bonusLockPeriod = safeAdd(block.timestamp,_bonuslockPeriod);
        vestingSchedule.principleLockPeriod = safeAdd(block.timestamp,_principleLockPeriod);

         
        ERC20 token = ERC20(TokenAddress);
        uint256 _totalAmount = safeAdd(_principleLockAmount, _bonusLockAmount);
        require(token.balanceOf(this) >= safeAdd(totalUnreleasedTokens, _totalAmount));
        vestingSchedule.principleLockAmount = _principleLockAmount;
        vestingSchedule.bonusLockAmount = _bonusLockAmount;
        vestingSchedule.isPrincipleReleased = false;
        vestingSchedule.isBonusReleased = false;
        totalUnreleasedTokens = safeAdd(totalUnreleasedTokens, _totalAmount);
        vestingSchedule.amountReleased = 0;
    }

    function isVestingSet(address adr) public constant returns (bool isSet) {
        return vestingMap[adr].principleLockAmount != 0 || vestingMap[adr].bonusLockAmount != 0;
    }


     
    function releaseMyVestedTokens() public {
        releaseVestedTokens(msg.sender);
    }

     
    function releaseVestedTokens(address _adr) public {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
        uint256 _totalTokens = safeAdd(vestingSchedule.principleLockAmount, vestingSchedule.bonusLockAmount);
         
        require(safeSub(_totalTokens, vestingSchedule.amountReleased) > 0);
        
         
        uint256 amountToRelease = 0;

        if (block.timestamp >= vestingSchedule.principleLockPeriod && !vestingSchedule.isPrincipleReleased) {
            amountToRelease = safeAdd(amountToRelease,vestingSchedule.principleLockAmount);
            vestingSchedule.amountReleased = safeAdd(vestingSchedule.amountReleased, amountToRelease);
            vestingSchedule.isPrincipleReleased = true;
        }
        if (block.timestamp >= vestingSchedule.bonusLockPeriod && !vestingSchedule.isBonusReleased) {
            amountToRelease = safeAdd(amountToRelease,vestingSchedule.bonusLockAmount);
            vestingSchedule.amountReleased = safeAdd(vestingSchedule.amountReleased, amountToRelease);
            vestingSchedule.isBonusReleased = true;
        }

         
        require(amountToRelease > 0);
        ERC20 token = ERC20(TokenAddress);
        token.transfer(_adr, amountToRelease);
         
        totalUnreleasedTokens = safeSub(totalUnreleasedTokens, amountToRelease);
        VestedTokensReleased(_adr, amountToRelease);
    }

}