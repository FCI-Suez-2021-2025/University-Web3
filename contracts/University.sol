pragma solidity ^0.8.0;

import "./Student.sol";
import "./Professor.sol";

contract University {
    address payable public owner;
    Student public studentContract;
    Professor public professorContract;

    constructor(address _studentContractAddress, address _professorContractAddress) {
        owner = payable(msg.sender);
        studentContract = Student(_studentContractAddress);
        professorContract = Professor(_professorContractAddress);
    }

    function addStudent(string memory _name, string memory _major, uint256 _year, uint256 _professorId) public {
        professorContract.getProfessor(_professorId);
        studentContract.addStudent(_name, _major, _year, address(professorContract));
    }

    function updateStudent(uint256 _studentId, string memory _name, string memory _major, uint256 _year, uint256 _professorId) public {
        professorContract.getProfessor(_professorId);
        studentContract.updateStudent(_studentId, _name, _major, _year, address(professorContract));
    }

    function deleteStudent(uint256 _studentId) public {
        studentContract.deleteStudent(_studentId);
    }

    function getStudent(uint256 _studentId) public view returns (Student.StudentInfo memory) {
        return studentContract.getStudent(_studentId);
    }

    function addProfessor(string memory _name, string memory _department) public {
        professorContract.addProfessor(_name, _department);
    }

    function getProfessor(uint256 _professorId) public view returns (Professor.ProfessorInfo memory) {
        return professorContract.getProfessor(_professorId);
    }

    function deleteProfessor(uint256 _professorId) public {
        professorContract.deleteProfessor(_professorId);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
}