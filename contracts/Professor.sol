// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Professor {
    struct ProfessorInfo {
        uint256 id;
        address professorAddress;
        string name;
        string department;
        bool active;
    }

    mapping(uint256 => ProfessorInfo) public professors;
    mapping(uint256 => bool) public isActive;
    uint256[] public allProfessors;
    mapping(address => uint256) public addressToId;
    uint256 public nextId = 1;

    event ProfessorAdded(uint256 indexed professorId, address indexed account);
    event ProfessorRemoved(uint256 indexed professorId);
    event ProfessorUpdated(uint256 indexed professorId);

    function addProfessor(
        string memory _name,
        string memory _department
    ) external returns (uint256) {
        uint256 id = nextId++;
        professors[id] = ProfessorInfo({
            id: id,
            professorAddress: msg.sender,
            name: _name,
            department: _department,
            active: true
        });
        isActive[id] = true;
        allProfessors.push(id);
        addressToId[msg.sender] = id;
        emit ProfessorAdded(id, msg.sender);
        return id;
    }

    function removeProfessor(uint256 _id) external {
        require(isActive[_id], "Professor not found");
        ProfessorInfo storage prof = professors[_id];

        delete addressToId[prof.professorAddress];

        uint256 lastIndex = allProfessors.length - 1;
        uint256 index = _findIndex(_id);

        if(index != lastIndex) {
            uint256 lastId = allProfessors[lastIndex];
            allProfessors[index] = lastId;
        }

        allProfessors.pop();
        isActive[_id] = false;
        prof.active = false;
        emit ProfessorRemoved(_id);
    }

    function updateProfessor(
        uint256 _id,
        string memory _name,
        string memory _department
    ) external {
        require(isActive[_id], "Professor not found");

        if (bytes(_name).length > 0) {
            professors[_id].name = _name;
        }

        if (bytes(_department).length > 0) {
            professors[_id].department = _department;
        }

        emit ProfessorUpdated(_id);
    }

    function getActiveProfessors() external view returns (uint256[] memory) {
        return allProfessors;
    }

    function getProfessor(uint256 _id) external view returns (ProfessorInfo memory) {
        require(isActive[_id], "Professor not found");
        return professors[_id];
    }

    function getProfessorIdByAddress(address _addr) external view returns (uint256) {
        uint256 id = addressToId[_addr];
        require(id != 0 && isActive[id], "Professor not found");
        return id;
    }

    function _findIndex(uint256 _id) private view returns (uint256) {
        for(uint256 i = 0; i < allProfessors.length; i++) {
            if(allProfessors[i] == _id) return i;
        }
        revert("Professor not found");
    }
}