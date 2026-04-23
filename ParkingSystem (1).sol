// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ParkingSystem {

    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Slot {
        uint id;
        bool isOccupied;
        address currentUser;
        uint startTime;
        uint endTime;
    }

    struct Reservation {
        uint slotId;
        address user;
        uint startTime;
        uint endTime;
    }

    mapping(uint => Slot) public slots;
    uint public totalSlots;

    Reservation[] public reservationHistory;
    mapping(address => uint) public userReservationsCount;

    event SlotAdded(uint slotId);
    event SlotReserved(uint slotId, address user, uint startTime, uint endTime);
    event SlotReleased(uint slotId, address user);

    modifier validSlot(uint _slotId) {
        require(_slotId > 0 && _slotId <= totalSlots, "Invalid slot ID");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function addSlot() public onlyOwner {
        totalSlots++;
        slots[totalSlots] = Slot(totalSlots, false, address(0), 0, 0);
        emit SlotAdded(totalSlots);
    }

    function reserveSlot(uint _slotId, uint _durationInMinutes) 
        public validSlot(_slotId) 
    {
        Slot storage s = slots[_slotId];

        if (s.isOccupied && block.timestamp > s.endTime) {
            s.isOccupied = false;
            s.currentUser = address(0);
            s.startTime = 0;
            s.endTime = 0;
        }

        require(!s.isOccupied, "Slot already occupied");

        s.isOccupied = true;
        s.currentUser = msg.sender;
        s.startTime = block.timestamp;
        s.endTime = block.timestamp + (_durationInMinutes * 1 minutes);

        reservationHistory.push(Reservation(
            _slotId,
            msg.sender,
            s.startTime,
            s.endTime
        ));

        userReservationsCount[msg.sender]++;

        emit SlotReserved(_slotId, msg.sender, s.startTime, s.endTime);
    }

    function releaseSlot(uint _slotId) public validSlot(_slotId) {
        Slot storage s = slots[_slotId];

        require(s.currentUser == msg.sender, "Not your slot");

        s.isOccupied = false;
        s.currentUser = address(0);
        s.startTime = 0;
        s.endTime = 0;

        emit SlotReleased(_slotId, msg.sender);
    }

    function getSlot(uint _slotId) 
        public view validSlot(_slotId) 
        returns (uint, bool, address, uint, uint) 
    {
        Slot memory s = slots[_slotId];

        if (s.isOccupied && block.timestamp > s.endTime) {
            return (s.id, false, address(0), 0, 0);
        }

        return (s.id, s.isOccupied, s.currentUser, s.startTime, s.endTime);
    }

    function getAllSlots() public view returns (Slot[] memory) {
        Slot[] memory all = new Slot[](totalSlots);

        for (uint i = 1; i <= totalSlots; i++) {
            Slot memory s = slots[i];

            if (s.isOccupied && block.timestamp > s.endTime) {
                all[i - 1] = Slot(s.id, false, address(0), 0, 0);
            } else {
                all[i - 1] = s;
            }
        }

        return all;
    }

    function getAvailableSlots() public view returns (uint[] memory) {
        uint count = 0;

        for (uint i = 1; i <= totalSlots; i++) {
            if (
                !slots[i].isOccupied || 
                (slots[i].isOccupied && block.timestamp > slots[i].endTime)
            ) {
                count++;
            }
        }

        uint[] memory available = new uint[](count);
        uint index = 0;

        for (uint i = 1; i <= totalSlots; i++) {
            if (
                !slots[i].isOccupied || 
                (slots[i].isOccupied && block.timestamp > slots[i].endTime)
            ) {
                available[index] = i;
                index++;
            }
        }

        return available;
    }

    function getReservationHistoryCount() public view returns (uint) {
        return reservationHistory.length;
    }

    function getAllReservations() public view returns (Reservation[] memory) {
        return reservationHistory;
    }
}
