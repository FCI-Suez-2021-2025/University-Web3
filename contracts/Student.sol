// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Student {
    struct StudentInfo {
        uint256 id;
        string name;
        string major;
        uint256 year;
        address academicSupervisorAddress;
    }

    mapping(uint256 => StudentInfo) public students;
    mapping(uint256 => string[]) public enrolledCourses; // studentId => courseIds[]
    mapping(uint256 => mapping(string => bool)) public isEnrolled; // studentId => courseId => enrolled
    uint256 public nextId;

    constructor() {
        nextId = 1;
    }

    // Add a student with academic supervisor address
    function addStudent(
        string memory _name,
        string memory _major,
        uint256 _year,
        address _academicSupervisorAddress
    ) public {
        students[nextId] = StudentInfo(
            nextId,
            _name,
            _major,
            _year,
            _academicSupervisorAddress
        );
        nextId++;
    }

    function updateStudent(
        uint256 _id,
        string memory _name,
        string memory _major,
        uint256 _year,
        address _academicSupervisorAddress
    ) public {
        require(students[_id].id > 0, "Student does not exist");

        if (bytes(_name).length > 0) {
            students[_id].name = _name;
        }
        if (bytes(_major).length > 0) {
            students[_id].major = _major;
        }
        if (_year > 0) {
            students[_id].year = _year;
        }
        if (_academicSupervisorAddress != address(0)) {
            students[_id].academicSupervisorAddress = _academicSupervisorAddress;
        }
    }

    function deleteStudent(uint256 _id) public {
        require(students[_id].id > 0, "Student does not exist");
        delete students[_id];
    }

    function getStudent(uint256 _id) public view returns (StudentInfo memory) {
        require(students[_id].id > 0, "Student does not exist");
        return students[_id];
    }

    // Enroll a student in a course
    function enrollInCourse(uint256 _studentId, string memory _courseId) external {
        require(students[_studentId].id > 0, "Student does not exist");
        require(!isEnrolled[_studentId][_courseId], "Already enrolled in this course");

        enrolledCourses[_studentId].push(_courseId);
        isEnrolled[_studentId][_courseId] = true;
    }

    // Delete a specific course from a student's list
    function deleteCourseFromStudent(uint256 _studentId, string memory _courseId) public {
        require(students[_studentId].id > 0, "Student does not exist");
        require(isEnrolled[_studentId][_courseId], "Course not enrolled");

        string[] storage courses = enrolledCourses[_studentId];
        for (uint256 i = 0; i < courses.length; i++) {
            if (keccak256(bytes(courses[i])) == keccak256(bytes(_courseId))) {
                courses[i] = courses[courses.length - 1];
                courses.pop();
                break;
            }
        }
        delete isEnrolled[_studentId][_courseId];
    }

    // Delete all courses for a student
    function deleteAllCoursesForStudent(uint256 _studentId) external {
        require(students[_studentId].id > 0, "Student does not exist");
        delete enrolledCourses[_studentId];
    }

    // Get all courses for a student
    function getEnrolledCourses(uint256 _studentId) public view returns (string[] memory) {
    return enrolledCourses[_studentId];
}
}