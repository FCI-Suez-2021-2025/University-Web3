// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Professor {
    struct ProfessorInfo {
        uint256 id;
        address professorAddress;
        string name;
        string department;
    }

    mapping(uint256 => ProfessorInfo) public professors;
    uint256 public nextId;

    constructor() {
        nextId = 1;
    }

    function addProfessor(string memory _name, string memory _department) public {
        professors[nextId] = ProfessorInfo(nextId, msg.sender, _name, _department);
        nextId++;
    }

    function getProfessor(uint256 _id) public view returns (ProfessorInfo memory) {
        require(professors[_id].id > 0, "Professor does not exist");
        return professors[_id];
    }

    function deleteProfessor(uint256 _id) public {
        require(professors[_id].id > 0, "Professor does not exist");
        delete professors[_id];
    }
}