pragma solidity ^0.4.21;

 



contract Memes{
    address owner;
    address helper=0x690F34053ddC11bdFF95D44bdfEb6B0b83CBAb58;

    uint256 public TimeFinish = 0;
    uint256 TimerResetTime = 7200;  
    uint256 TimerStartTime = 360000; 
    uint256 public Pot = 0;
     
    uint16 PIncr = 10000;  
     
    uint16 DIVP = 10000;  
     
    uint16 POTP = 0;  
     
    uint16 WPOTPART = 9000;  
    
     
    uint16 public DEVP = 500;
     
    uint16 public HVAL = 5000;
    uint256 BasicPrice = .00666 ether;
    struct Item{
        address owner;
        uint256 CPrice;
        bool reset;
    }
    uint8 constant SIZE = 17;
    Item[SIZE] public ItemList;
    
    address public PotOwner;
    
    
    event ItemBought(address owner, uint256 newPrice, string says, uint8 id);
     
    event GameWon(address owner, uint256 paid, uint256 npot);
    
    modifier OnlyOwner(){
        if (msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }
    
    function SetDevFee(uint16 tfee) public OnlyOwner{
        require(tfee <= 500);
        DEVP = tfee;
    }
    
     
    function SetHFee(uint16 hfee) public OnlyOwner {
        require(hfee <= 10000);
        require(hfee >= 1000);
        HVAL = hfee;
    
    }
    
    
     
    function Memes() public {
         
        
         
        var ITM = Item(msg.sender, BasicPrice, true );
        ItemList[0] = ITM;  
        ItemList[1] = ITM;  
        ItemList[2] = ITM;  
        ItemList[3] = ITM;  
        ItemList[4] = ITM;  
        ItemList[5] = ITM;  
        ItemList[6] = ITM;
        ItemList[7] = ITM;
        ItemList[8] = ITM;
        ItemList[9] = ITM;
        ItemList[10] = ITM;
        ItemList[11] = ITM;
        ItemList[12] = ITM;
        ItemList[13] = ITM;
        ItemList[14] = ITM;
        ItemList[15] = ITM;
        ItemList[16] = ITM;
        owner=msg.sender;
    }
    
    
    
    function Buy(uint8 ID, string says) public payable {
        require(ID < SIZE);
        var ITM = ItemList[ID];
        if (TimeFinish == 0){
             
            TimeFinish = block.timestamp; 
        }
        else if (TimeFinish == 1){
            TimeFinish =block.timestamp + TimerResetTime;
        }
            
        uint256 price = ITM.CPrice;
        
        if (ITM.reset){
            price = BasicPrice;
            
        }
        
        if (msg.value >= price){
            if (!ITM.reset){
                require(msg.sender != ITM.owner);  
            }
            if ((msg.value - price) > 0){
                 
                msg.sender.transfer(msg.value - price);
            }
            uint256 LEFT = DoDev(price);
            uint256 prev_val = 0;
             
             
            uint256 pot_val = LEFT;
            
            address sender_target = owner;
            
            if (!ITM.reset){
                prev_val = (DIVP * LEFT)  / 10000;
                pot_val = (POTP * LEFT) / 10000;
                sender_target = ITM.owner;  
            }
            else{
                 
                 
                prev_val = LEFT;
                pot_val = 0;  
                 
            }
            
            Pot = Pot + pot_val;
            sender_target.transfer(prev_val);  
            ITM.owner = msg.sender;
            uint256 incr = PIncr;  
            ITM.CPrice = (price * (10000 + incr)) / 10000;

             
            uint256 TimeLeft = TimeFinish - block.timestamp;
            
            if (TimeLeft< TimerStartTime){
                
                TimeFinish = block.timestamp + TimerStartTime;
            }
            if (ITM.reset){
                ITM.reset=false;
            }
            PotOwner = msg.sender;
             
            emit ItemBought(msg.sender, ITM.CPrice, says, ID);
        }  
        else{
            revert();  
        }
    }
    
    
    function DoDev(uint256 val) internal returns (uint256){
        uint256 tval = (val * DEVP / 10000);
        uint256 hval = (tval * HVAL) / 10000;
        uint256 dval = tval - hval; 
        
        owner.transfer(dval);
        helper.transfer(hval);
        return (val-tval);
    }
    
}