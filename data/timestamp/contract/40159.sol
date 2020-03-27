contract Etherization {
    
     
    uint public START_PRICE = 1000000000000000000;
     
    uint public CITY_PRICE = 800000000000000000;
     
    uint public BUILDING_PRICE = 500000000000000000;
     
    uint public UNIT_PRICE = 200000000000000000;
     
    uint public MAINT_PRICE = 20000000000000000;
     
    uint public MIN_WTH = 100000000000000000;
    
     
    uint public WAIT_TIME = 14400;
    uint MAP_ROWS = 34;
    uint MAP_COLS = 34;
    
    
    struct City {
        uint owner;
        string name;
         
        bool[5] buildings;
         
        uint[10] units;  
        uint[2] rowcol;
        int previousID;
        int nextID;
    }
    
    struct Player {
         
        address etherAddress;
         
        string name;
         
        uint treasury;
         
        uint capitol;
         
        uint numCities;
        uint numUnits;
         
        uint lastTimestamp;
    }
    
    Player player;
    Player[] public players;
    uint public numPlayers = 0;
    
    mapping(address => uint) playerIDs;
    mapping(uint => uint) public playerMsgs;
    
    City city;
    City[] public cities;
    uint public numCities = 0;
    
    uint[] public quarryCities;
    uint[] public farmCities;
    uint[] public woodworksCities;
    uint[] public metalworksCities;
    uint[] public stablesCities;
    
    uint[34][34] public map;

    address wizardAddress;
    
    address utilsAddress;
    address utilsAddress2;
    
     
    uint public totalBalances = 0;

     
    modifier onlywizard { if (msg.sender == wizardAddress) _ }
    
     
    modifier onlyutils { if (msg.sender == utilsAddress || msg.sender == utilsAddress2) _ }



     
    function Etherization() {
        wizardAddress = msg.sender;
    }

    function start(string playerName, string cityName, uint row, uint col, uint rowref, uint colref) {
        
        
         
        if (msg.value < START_PRICE) {
             
             
            return;
        }
         
        if (playerIDs[msg.sender] > 0) {
             
             
            return;
        }
        
        player.etherAddress = msg.sender;
        player.name = playerName;
        player.treasury = msg.value;
        totalBalances += msg.value;
        player.capitol = numCities;
        player.numCities = 1;
        player.numUnits = 1;

        players.push(player);
        
        city.owner = numPlayers;
        city.name = cityName;
         
        if(numCities <= 0) {
            city.buildings[0] = true;
            quarryCities.push(0);
            city.buildings[1] = true;
            farmCities.push(0);
            city.rowcol[0] = 10;
            city.rowcol[1] = 10;
            map[10][10] = numPlayers+1;
        } else {
            city.buildings[0] = false;
            city.buildings[1] = false;
            if(row>33 || col>33 || rowref>33 || colref>33 || int(row)-int(rowref) > int(1) || int(row)-int(rowref) < int(-1) || int(col)-int(colref) > int(1) || int(col)-int(colref) < int(-1) || map[row][col]>0 || map[rowref][colref]<=0) {
                throw;
            }
            city.rowcol[0] = row;
            city.rowcol[1] = col;
            map[row][col] = numPlayers+1;
            
            players[numPlayers].treasury -= START_PRICE;
             
            uint productionCut;
            uint i;
            productionCut = START_PRICE / quarryCities.length;
            for(i=0; i < quarryCities.length; i++) {
                players[cities[quarryCities[i]].owner].treasury += productionCut;
            }
        }
        city.units[0] = 1;   
        city.previousID = -1;
        city.nextID = -1;
        
        cities.push(city);
        
        playerIDs[msg.sender] = numPlayers+1;  
        numPlayers++;
        numCities++;
        
        playerMsgs[playerIDs[msg.sender]-1] = 1 + row*100 + col*10000;
        players[numPlayers-1].lastTimestamp = now;
    }
    
    function deposit() {
        players[playerIDs[msg.sender]-1].treasury += msg.value;
        totalBalances += msg.value;
    }
    
    function withdraw(uint amount) {
        if(int(playerIDs[msg.sender])-1 < 0) {
            throw;
        }
        uint playerID = playerIDs[msg.sender]-1;
        if(timePassed(playerID) < WAIT_TIME) {
            playerMsgs[playerIDs[msg.sender]-1] = 2;
            return;        
        }
        if(amount < players[playerID].treasury && amount > MIN_WTH) {
            players[playerID].treasury -= amount;
            totalBalances -= amount;
            players[playerID].etherAddress.send((amount*99)/100);  
        }
    }
    
    
    
    function getMyPlayerID() constant returns (int ID) {
        return int(playerIDs[msg.sender])-1;
    }
    
    function getMyMsg() constant returns (uint s) {
        return playerMsgs[playerIDs[msg.sender]-1];
    }
    
    function getCity(uint cityID) constant returns (uint owner, string cityName, bool[5] buildings, uint[10] units, uint[2] rowcol, int previousID, int nextID) {
        return (cities[cityID].owner, cities[cityID].name, cities[cityID].buildings, cities[cityID].units, cities[cityID].rowcol, cities[cityID].previousID, cities[cityID].nextID);
    }
    
    
    function timePassed(uint playerID) constant returns (uint tp) {
        return (now - players[playerID].lastTimestamp);
    }


     
    function getCommission() onlywizard constant returns (uint com) {
        return this.balance-totalBalances;
    }

     
    function sweepCommission(uint amount) onlywizard {
        if(amount < this.balance-totalBalances) {
            wizardAddress.send(amount);
        }
    }
    
    
    
    function setUtils(address a) onlywizard {
        utilsAddress = a;
    }
    
    function setUtils2(address a) onlywizard {
        utilsAddress2 = a;
    }
    
    function getPlayerID(address sender) onlyutils constant returns (uint playerID) {
        if(int(playerIDs[sender])-1 < 0) {
            throw;
        }
        return playerIDs[sender]-1;
    }
    
    function getWwLength() constant returns (uint length) {
        return woodworksCities.length;
    }
    
    function getMwLength() constant returns (uint length) {
        return metalworksCities.length;
    }
    
    function getStLength() constant returns (uint length) {
        return stablesCities.length;
    }
    
    function getFmLength() constant returns (uint length) {
        return farmCities.length;
    }
    
    function getQrLength() constant returns (uint length) {
        return quarryCities.length;
    }
    
    
    function setMsg(address sender, uint s) onlyutils {
        playerMsgs[playerIDs[sender]-1] = s;
    }
    
    function setNumCities(uint nc) onlyutils {
        numCities = nc;
    }
    
    function setUnit(uint cityID, uint i, uint unitType) onlyutils {
        cities[cityID].units[i] = unitType;
    }
    
    function setOwner(uint cityID, uint owner) onlyutils {
        cities[cityID].owner = owner;
    }
    
    function setName(uint cityID, string name) onlyutils {
        cities[cityID].name = name;
    }
    
    function setPreviousID(uint cityID, int previousID) onlyutils {
        cities[cityID].previousID = previousID;
    }
    
    function setNextID(uint cityID, int nextID) onlyutils {
        cities[cityID].nextID = nextID;
    }
    
    function setRowcol(uint cityID, uint[2] rowcol) onlyutils {
        cities[cityID].rowcol = rowcol;
    }
    
    function setMap(uint row, uint col, uint ind) onlyutils {
        map[row][col] = ind;
    }
    
    function setCapitol(uint playerID, uint capitol) onlyutils {
        players[playerID].capitol = capitol;
    }

    function setNumUnits(uint playerID, uint numUnits) onlyutils {
        players[playerID].numUnits = numUnits;
    }
    
    function setNumCities(uint playerID, uint numCities) onlyutils {
        players[playerID].numCities = numCities;
    }
    
    function setTreasury(uint playerID, uint treasury) onlyutils {
        players[playerID].treasury = treasury;
    }
    
    function setLastTimestamp(uint playerID, uint timestamp) onlyutils {
        players[playerID].lastTimestamp = timestamp;
    }
    
    function setBuilding(uint cityID, uint buildingType) onlyutils {
        cities[cityID].buildings[buildingType] = true;
        if(buildingType == 0) {
            quarryCities.push(cityID);
        } else if(buildingType == 1) {
            farmCities.push(cityID);
        } else if(buildingType == 2) {
            woodworksCities.push(cityID);
        } else if(buildingType == 3) {
            metalworksCities.push(cityID);
        } else if(buildingType == 4) {
            stablesCities.push(cityID);
        }
    }
    
    function pushCity() onlyutils {
        city.buildings[0] = false;
        city.buildings[1] = false;
        cities.push(city);
    }

}