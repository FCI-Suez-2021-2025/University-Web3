pragma solidity ^0.8.0;

contract Student {
    struct StudentInfo {
        uint256 id;
        string name;
        string major;
        uint256 year;
        address professor;
    }

    mapping(uint256 => StudentInfo) public students;
    uint256 public nextId;

    constructor() {
        nextId = 1;
    }

    function addStudent(string memory _name, string memory _major, uint256 _year, address _professor) public {
        students[nextId] = StudentInfo(nextId, _name, _major, _year, _professor);
        nextId++;
    }

    function updateStudent(uint256 _id, string memory _name, string memory _major, uint256 _year, address _professor) public {
        require(students[_id].id > 0, "Student does not exist");
        students[_id] = StudentInfo(_id, _name, _major, _year, _professor);
    }

    function deleteStudent(uint256 _id) public {
        require(students[_id].id > 0, "Student does not exist");
        delete students[_id];
    }

    function getStudent(uint256 _id) public view returns (StudentInfo memory) {
        require(students[_id].id > 0, "Student does not exist");
        return students[_id];
    }
}