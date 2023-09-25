// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TicketBooking {
    mapping(uint => bool) seats;
    mapping(address => uint[]) seatsOfAddress;
    
    //To book seats
    function bookSeats(uint[] memory seatNumbers) public{
        require(seatNumbers.length > 0);
        require(seatsOfAddress[msg.sender].length + seatNumbers.length <= 4);
        
        uint[] memory seatNums = new uint[](seatNumbers.length);
        for(uint i = 0; i<seatNumbers.length; i++){
            require(seatNumbers[i] <= 20 && seatNumbers[i] > 0);
            require(!seats[seatNumbers[i]]);
            for (uint j=0; j<seatNumbers.length; j++){
                require(seatNumbers[i] != seatNums[j]);
            }
            seatNums[i] = seatNumbers[i];
        }

        for (uint i = 0; i<seatNumbers.length; i++){
            seats[seatNumbers[i]] = true;
            seatsOfAddress[msg.sender].push(seatNumbers[i]);
        }
    }
    //To get available seats
    function showAvailableSeats() public view returns (uint[] memory) {
        uint[20] memory available;
        uint availableCount;
        for(uint i = 0; i < 20; i++){
            if(!seats[i+1]){
                available[availableCount] = i+1;
                availableCount++;
            }
        }
        uint[] memory availableSeats = new uint[](availableCount);
        for(uint i = 0; i<availableCount; i++){
            availableSeats[i] = available[i];
        }
        return availableSeats;
    }
    //To check availability of a seat
    function checkAvailability(uint seatNumber) public view returns (bool) {
        require(seatNumber >= 1);
        require(seatNumber <= 20);
        return !seats[seatNumber];
    }
    
    //To check tickets booked by the user
    function myTickets() public view returns (uint[] memory) {
        uint[] memory tickets = seatsOfAddress[msg.sender];
        return tickets;
    }
}