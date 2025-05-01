// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Student {
    struct StudentInfo {
        uint256 id;
        string name;
        string major;
        uint256 year;
        address academicSupervisor;
        bool active;
    }

    mapping(uint256 => StudentInfo) public students;
    mapping(uint256 => bool) public isActive;
    uint256[] public allStudents;
    uint256 public nextId = 1;

    event StudentAdded(uint256 indexed studentId);
    event StudentUpdated(uint256 indexed studentId);
    event StudentDeleted(uint256 indexed studentId);

    function addStudent(
        string memory _name,
        string memory _major,
        uint256 _year,
        address _supervisor
    ) external returns (uint256) {
        uint256 id = nextId++;
        students[id] = StudentInfo({
            id: id,
            name: _name,
            major: _major,
            year: _year,
            academicSupervisor: _supervisor,
            active: true
        });
        isActive[id] = true;
        allStudents.push(id);
        emit StudentAdded(id);
        return id;
    }

    function updateStudent(
        uint256 _id,
        string memory _name,
        string memory _major,
        uint256 _year,
        address _academicSupervisorAddress
    ) external {
        require(isActive[_id], "Student doesn't exist");
        StudentInfo storage student = students[_id];

        if (bytes(_name).length > 0) student.name = _name;
        if (bytes(_major).length > 0) student.major = _major;
        if (_year > 0) student.year = _year;
        if (_academicSupervisorAddress != address(0)) {
            student.academicSupervisor = _academicSupervisorAddress;
        }

        emit StudentUpdated(_id);
    }

    function deleteStudent(uint256 _id) external {
        require(isActive[_id], "Student doesn't exist");

        // Remove from allStudents array
        for (uint256 i = 0; i < allStudents.length; i++) {
            if (allStudents[i] == _id) {
                allStudents[i] = allStudents[allStudents.length - 1];
                allStudents.pop();
                break;
            }
        }

        isActive[_id] = false;
        students[_id].active = false;
        emit StudentDeleted(_id);
    }

    function getStudent(uint256 _id) external view returns (StudentInfo memory) {
        require(isActive[_id], "Student doesn't exist");
        return students[_id];
    }

    function getAllStudents() external view returns (uint256[] memory) {
        return allStudents;
    }
}