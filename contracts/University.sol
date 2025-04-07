// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Student.sol";
import "./Professor.sol";
import "./Course.sol";

contract University {
    address payable public owner;
    Student public studentContract;
    Professor public professorContract;
    Course public courseContract;

    struct EnrollmentInfo {
        string courseId;
        string courseName;
        string professorName;
        string department;
    }

    constructor(
        address _studentContractAddress,
        address _professorContractAddress,
        address _courseContractAddress
    ) {
        owner = payable(msg.sender);
        studentContract = Student(_studentContractAddress);
        professorContract = Professor(_professorContractAddress);
        courseContract = Course(_courseContractAddress);
    }

    // Course Management
    function createCourse(
        string memory _courseId,
        string memory _name,
        uint256 _professorId
    ) public {
        courseContract.createCourse(_courseId, _name, _professorId);
    }

    function getStudentEnrollments(uint256 _studentId) public view returns (
        string[] memory courseIds,
        string[] memory courseNames,
        string[] memory professorNames,
        string[] memory departments
    ) {
        // Get course IDs from Student contract
        string[] memory enrolled = studentContract.getEnrolledCourses(_studentId);

        // Initialize arrays
        courseIds = new string[](enrolled.length);
        courseNames = new string[](enrolled.length);
        professorNames = new string[](enrolled.length);
        departments = new string[](enrolled.length);

        // Populate data
        for (uint256 i = 0; i < enrolled.length; i++) {
            Course.CourseInfo memory course = courseContract.getCourse(enrolled[i]);
            Professor.ProfessorInfo memory professor = professorContract.getProfessor(course.professorId);

            courseIds[i] = course.id;
            courseNames[i] = course.name;
            professorNames[i] = professor.name;
            departments[i] = professor.department;
        }
    }

    // Reassign a course using its string ID
    function reassignCourse(string memory _courseId, uint256 _newProfessorId) public {
        courseContract.reassignCourse(_courseId, _newProfessorId);
    }

    function deleteCourse(string memory _courseId) public {
        courseContract.deleteCourse(_courseId);
    }

    function addStudent(
        string memory _name,
        string memory _major,
        uint256 _year,
        uint256 _professorId
    ) public {
        Professor.ProfessorInfo memory prof = professorContract.getProfessor(_professorId);
        studentContract.addStudent(_name, _major, _year, prof.professorAddress);
    }

    function updateStudent(
        uint256 _studentId,
        string memory _name,
        string memory _major,
        uint256 _year,
        uint256 _professorId // Use 0 to keep the current professor
    ) public {
        address supervisorAddress;

        if (_professorId > 0) {
            Professor.ProfessorInfo memory prof = professorContract.getProfessor(_professorId);
            supervisorAddress = prof.professorAddress;
        } else {
            // Keep the existing supervisor address if no new professor ID is provided
            supervisorAddress = studentContract.getStudent(_studentId).academicSupervisorAddress;
        }

        studentContract.updateStudent(
            _studentId,
            _name,      // Pass empty string to keep the current name
            _major,     // Pass empty string to keep the current major
            _year,      // Pass 0 to keep the current year
            supervisorAddress
        );
    }

    function deleteStudent(uint256 _studentId) public {
        studentContract.deleteStudent(_studentId);
    }

    function getStudent(uint256 _studentId) public view returns (Student.StudentInfo memory) {
        return studentContract.getStudent(_studentId);
    }

    // Enroll a student in a course
    function enrollStudentInCourse(uint256 _studentId, string memory _courseId) public {
        // Verify the course exists
        courseContract.getCourse(_courseId);

        // Enroll in Student and Course contracts
        studentContract.enrollInCourse(_studentId, _courseId);
        courseContract.enrollStudent(_studentId, _courseId);
    }

    // Remove a course from a student's list
    function removeCourseFromStudent(uint256 _studentId, string memory _courseId) public {
        // Remove from Student contract
        studentContract.deleteCourseFromStudent(_studentId, _courseId);
        // Remove from Course contract enrollment list
        courseContract.unEnrollStudent(_studentId, _courseId);
    }

    // Remove all courses for a student
    function clearAllCoursesForStudent(uint256 _studentId) public {
        studentContract.deleteAllCoursesForStudent(_studentId);
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