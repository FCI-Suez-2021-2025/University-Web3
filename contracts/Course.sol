// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Professor.sol";
import "./Student.sol";

contract Course {
    Professor public professorContract;
    Student public studentContract;

    struct CourseInfo {
        string id;
        string name;
        uint256 professorId;
    }

    mapping(string => CourseInfo) public courses;
    mapping(uint256 => string[]) public coursesByProfessor;
    mapping(string => bool) public courseIdExists;

    // Track enrolled students per course
    mapping(string => uint256[]) public enrolledStudents; // courseId => studentIds[]

    constructor(address _professorContractAddress, address _studentContractAddress) {
        professorContract = Professor(_professorContractAddress);
        studentContract = Student(_studentContractAddress);
    }

    // Create a course
    function createCourse(
        string memory _courseId,
        string memory _name,
        uint256 _professorId
    ) external {
        require(!courseIdExists[_courseId], "Course ID already exists");
        Professor.ProfessorInfo memory prof = professorContract.getProfessor(_professorId);

        courses[_courseId] = CourseInfo(_courseId, _name, _professorId);
        coursesByProfessor[_professorId].push(_courseId);
        courseIdExists[_courseId] = true;
    }

    // Reassign a course to a new professor
    function reassignCourse(string memory _courseId, uint256 _newProfessorId) external {
        require(courseIdExists[_courseId], "Course does not exist");
        Professor.ProfessorInfo memory newProf = professorContract.getProfessor(_newProfessorId);

        // Remove from old professor's list
        uint256 oldProfessorId = courses[_courseId].professorId;
        string[] storage oldCourses = coursesByProfessor[oldProfessorId];
        for (uint256 i = 0; i < oldCourses.length; i++) {
            if (keccak256(bytes(oldCourses[i])) == keccak256(bytes(_courseId))) {
                oldCourses[i] = oldCourses[oldCourses.length - 1];
                oldCourses.pop();
                break;
            }
        }

        // Update professor ID and add to new list
        courses[_courseId].professorId = _newProfessorId;
        coursesByProfessor[_newProfessorId].push(_courseId);
    }

    // Get all courses taught by a professor
    function getCoursesByProfessor(uint256 _professorId) external view returns (CourseInfo[] memory) {
        string[] storage courseIds = coursesByProfessor[_professorId];
        CourseInfo[] memory result = new CourseInfo[](courseIds.length);

        for (uint256 i = 0; i < courseIds.length; i++) {
            result[i] = courses[courseIds[i]];
        }
        return result;
    }

    // Get course by string ID
    function getCourse(string memory _courseId) external view returns (CourseInfo memory) {
        require(courseIdExists[_courseId], "Course does not exist");
        return courses[_courseId];
    }

    function deleteCourse(string memory _courseId) external {
        require(courseIdExists[_courseId], "Course does not exist");
        uint256 professorId = courses[_courseId].professorId;

        // Remove course from professor's list
        string[] storage professorCourses = coursesByProfessor[professorId];
        for (uint256 i = 0; i < professorCourses.length; i++) {
            if (keccak256(bytes(professorCourses[i])) == keccak256(bytes(_courseId))) {
                professorCourses[i] = professorCourses[professorCourses.length - 1];
                professorCourses.pop();
                break;
            }
        }

        // Remove course from all enrolled students
        uint256[] storage studentsInCourse = enrolledStudents[_courseId];
        for (uint256 i = 0; i < studentsInCourse.length; i++) {
            uint256 studentId = studentsInCourse[i];
            studentContract.deleteCourseFromStudent(studentId, _courseId);
        }

        // Delete course data
        delete courses[_courseId];
        delete courseIdExists[_courseId];
        delete enrolledStudents[_courseId];
    }

    // Enroll a student (called by University contract)
    function enrollStudent(uint256 _studentId, string memory _courseId) external {
        require(courseIdExists[_courseId], "Course does not exist");
        enrolledStudents[_courseId].push(_studentId);
    }

    // Function to safely remove students from course enrollment
    function unEnrollStudent(uint256 _studentId, string memory _courseId) external {
        require(courseIdExists[_courseId], "Course does not exist");
        uint256[] storage students = enrolledStudents[_courseId];
        for (uint256 i = 0; i < students.length; i++) {
            if (students[i] == _studentId) {
                students[i] = students[students.length - 1];
                students.pop();
                break;
            }
        }
    }
}