// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IGamingEcosystemNFT {
    function mintNFT(address to) external;
    function burnNFT(uint256 tokenId) external;
    function transferNFT(uint256 tokenId, address from, address to) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract BlockchainGamingEcosystem {
    address immutable owner;
    IGamingEcosystemNFT immutable nftContract;
    uint public TOKENID;
    struct Player{
        uint credits;
        uint nftCount;
        string username;
        bool isRegistered;
    }
    struct Game {
        string gameName;
        uint gameID;
        uint price;
        uint[] participantsTokenIds;
    }
    struct Token{
        string tokenOwner;
        uint gameID;
        uint value;
    }
    mapping (address => Player) public players;
    mapping (string => bool) public userNameExists;
    mapping(uint gameID => Game) public games;
    mapping (string => bool) public gameNameExists;
    mapping (uint _tokenID => Token ) public tokenOwnership;
    constructor(address _nftAddress)  {
        owner = msg.sender;
        nftContract = IGamingEcosystemNFT(_nftAddress);
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    modifier onlyPlayer(){
        require(players[msg.sender].isRegistered);
        _;
    }

    // Function to register as a player
    function registerPlayer(string memory userName) public {
        require(msg.sender != owner);
        require(!players[msg.sender].isRegistered);
        require(bytes(userName).length >= 3);
        require(!userNameExists[userName]);
        players[msg.sender] = Player(1000, 0, userName, true);
        userNameExists[userName] = true;
    }

    // Function to create a new game
    function createGame(string memory gameName, uint256 gameID) public onlyOwner {
        require(bytes(gameName).length > 0);
        require(gameID > 0);
        require(games[gameID].gameID == 0);
        require(!gameNameExists[gameName]);
        // Add the game to the mapping 
        games[gameID] = Game(gameName, gameID, 250, new uint[](0));
        gameNameExists[gameName] = true;
    }
    
    // Function to remove a game from the ecosystem
    function removeGame(uint256 gameID) public onlyOwner{
        require(gameID > 0);
        require(games[gameID].gameID != 0);
        uint[] memory participants = games[gameID].participantsTokenIds;
        uint _tokenID;
        uint _assetPrice;
        address _tokenOwner;
        // sending assets to their owners before removing game

        for (uint i = 0; i < participants.length; i++){
            _tokenID = participants[i];
            _assetPrice = tokenOwnership[_tokenID].value;
            _tokenOwner = nftContract.ownerOf(_tokenID);
            players[_tokenOwner].credits += _assetPrice;

            // transfering asset
            nftContract.transferNFT(_tokenID, _tokenOwner, owner);
            // destroy token/asset
            nftContract.burnNFT(_tokenID);
            // decrement NFT count of player
            players[_tokenOwner].nftCount -= 1;

            // remove tokenID in tokenOwnership mapping
            delete tokenOwnership[_tokenID];
        }

        // deleteing game in games and gameNameExists
        delete gameNameExists[games[gameID].gameName];
        delete games[gameID];
    }

    // Function to allow players to buy an NFT asset
    function buyAsset(uint256 gameID) public onlyPlayer {
        require(gameID > 0);
        require(games[gameID].gameID == gameID);
        //get current asset price
        uint assetPrice = games[gameID].price;
        require(players[msg.sender].credits >= assetPrice);
        nftContract.mintNFT(msg.sender);
        //updating player attr.
        players[msg.sender].credits -= assetPrice;
        players[msg.sender].nftCount += 1;
        // updating token ownership
        tokenOwnership[TOKENID].tokenOwner = players[msg.sender].username; 
        tokenOwnership[TOKENID].gameID = gameID;
        tokenOwnership[TOKENID].value = assetPrice;
        //increment asset price after every mint
        uint newAssetPrice = (assetPrice * 11)/10;
        games[gameID].price = newAssetPrice;
        // add sender tokenID to list of participants of game 
        games[gameID].participantsTokenIds.push(TOKENID);

        //incrementing tOkenID
        TOKENID++;
    }

	// // Function to allow players to sell owned assets
    function sellAsset(uint256 _tokenID) public onlyPlayer{
        // require(tokenOwnership[_tokenID].value != 0);
        require(nftContract.ownerOf(_tokenID) == msg.sender);
        //get current asset price
        uint assetPrice = games[tokenOwnership[_tokenID].gameID].price;
        // destroy asset
        nftContract.burnNFT(_tokenID);
        //updating player attr.
        players[msg.sender].nftCount -= 1;
        players[msg.sender].credits += assetPrice;
        uint gameID = tokenOwnership[_tokenID].gameID;
        uint[] memory participants = games[gameID].participantsTokenIds;
        uint _tmpTokenID;
        for (uint i = 0; i < participants.length; i++){
            _tmpTokenID = participants[i];
            if(_tmpTokenID == _tokenID){
                games[gameID].participantsTokenIds[i] = participants[participants.length-1];
                games[gameID].participantsTokenIds.pop();
                break;
            }
        }

        // updating tokenOwnership
        delete tokenOwnership[_tokenID];
    }

    // Function to transfer asset to a different player
    function transferAsset(uint256 _tokenID, address to) public onlyPlayer {
        // require(tokenOwnership[_tokenID].value != 0);
        require(nftContract.ownerOf(_tokenID) == msg.sender);
        require(players[to].isRegistered);
        require(to != msg.sender);
        // transfering asset
        nftContract.transferNFT(_tokenID, msg.sender, to);
        // updating player attr.
        players[msg.sender].nftCount -= 1;
        players[to].nftCount += 1;
        //updating tokenOwnership
        tokenOwnership[_tokenID].tokenOwner = players[to].username; 
    }

    // Function to view a player's profile
    function viewProfile(address playerAddress) public view returns (string memory userName, uint256 balance, uint256 numberOfNFTs) {
        require(players[msg.sender].isRegistered || msg.sender == owner);
        require(players[playerAddress].isRegistered);
        return (players[playerAddress].username, players[playerAddress].credits, players[playerAddress].nftCount);
    }
    // Function to view Asset owner and the associated game
    function viewAsset(uint256 _tokenID) public view returns (address _owner, string memory gameName, uint price) {
        require(players[msg.sender].isRegistered || msg.sender == owner);
        require(tokenOwnership[_tokenID].value != 0);
        _owner = nftContract.ownerOf(_tokenID);
        gameName = games[tokenOwnership[_tokenID].gameID].gameName;
        price = tokenOwnership[_tokenID].value;   
    }
}