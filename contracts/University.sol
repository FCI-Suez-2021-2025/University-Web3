// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Student.sol";
import "./Professor.sol";
import "./Course.sol";
import "./Enrollment.sol";

contract University {
    address public immutable admin;
    Student public studentContract;
    Professor public professorContract;
    Course public courseContract;
    Enrollment public enrollmentContract;

    mapping(address => bool) public authorizedInstructors;

    event BatchEnrollment(uint256[] studentIds, string courseId);
    event InstructorAuthorized(address indexed account);
    event InstructorDeauthorized(address indexed account);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin only");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedInstructors[msg.sender] || msg.sender == admin, "Unauthorized");
        _;
    }

    constructor(
        address _studentContract,
        address _professorContract,
        address _courseContract,
        address _enrollmentContract
    ) {
        admin = msg.sender;
        studentContract = Student(_studentContract);
        professorContract = Professor(_professorContract);
        courseContract = Course(_courseContract);
        enrollmentContract = Enrollment(_enrollmentContract);
        authorizedInstructors[admin] = true;
    }

    function authorizeInstructor(address _instructorAddress) external onlyAdmin {
        authorizedInstructors[_instructorAddress] = true;
        emit InstructorAuthorized(_instructorAddress);
    }

    function deauthorizeInstructor(address _instructorAddress) external onlyAdmin {
        require(_instructorAddress != admin, "Cannot deauthorize admin");
        authorizedInstructors[_instructorAddress] = false;
        emit InstructorDeauthorized(_instructorAddress);
    }

    function batchEnroll(uint256[] calldata _studentIds, string calldata _courseId) external onlyAuthorized {
        for(uint256 i = 0; i < _studentIds.length; i++) {
            uint256 studentId = _studentIds[i];
            if(studentContract.isActive(studentId)) {
                enrollmentContract.enrollStudent(studentId, _courseId);
            }
        }
        emit BatchEnrollment(_studentIds, _courseId);
    }

    function getStudentEnrollments(uint256 _studentId) external view returns (Enrollment.EnrollmentRecord[] memory) {
        return enrollmentContract.getStudentEnrollments(_studentId);
    }

    function getCourseEnrollments(string memory _courseId) external view returns (Enrollment.EnrollmentRecord[] memory) {
        return enrollmentContract.getCourseEnrollments(_courseId);
    }

    function reassignCourse(string memory _courseId, uint256 _newProfessorId) external onlyAuthorized {
        courseContract.reassignCourse(_courseId, _newProfessorId);
    }

    function createCourse(
        string memory _courseId,
        string memory _name,
        uint256 _professorId
    ) external onlyAuthorized {
        courseContract.createCourse(_courseId, _name, _professorId);
    }

    function getCourse(string memory _courseId) external view returns (Course.CourseInfo memory) {
        return courseContract.getCourse(_courseId);
    }

    function deleteCourse(string memory _courseId) external onlyAuthorized {
        // First get all enrolled students from Enrollment contract
        Enrollment.EnrollmentRecord[] memory enrollments = enrollmentContract.getCourseEnrollments(_courseId);

        // Unenroll all students
        for (uint256 i = 0; i < enrollments.length; i++) {
            if (enrollments[i].active) {
                enrollmentContract.unenrollStudent(enrollments[i].studentId, _courseId);
            }
        }

        // Then delete the course
        courseContract.deleteCourse(_courseId);
    }

    function addStudent(
        string memory _name,
        string memory _major,
        uint256 _year,
        uint256 _professorId
    ) external onlyAuthorized returns (uint256) {
        require(professorContract.isActive(_professorId), "Invalid professor ID");
        Professor.ProfessorInfo memory prof = professorContract.getProfessor(_professorId);
        return studentContract.addStudent(_name, _major, _year, prof.professorAddress);
    }

    function updateStudent(
        uint256 _studentId,
        string memory _name,
        string memory _major,
        uint256 _year,
        uint256 _professorId
    ) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Student does not exist");

        address supervisorAddress;

        if (_professorId > 0) {
            require(professorContract.isActive(_professorId), "Invalid professor ID");
            Professor.ProfessorInfo memory prof = professorContract.getProfessor(_professorId);
            supervisorAddress = prof.professorAddress;
        } else {
            Student.StudentInfo memory student = studentContract.getStudent(_studentId);
            supervisorAddress = student.academicSupervisor;
        }

        studentContract.updateStudent(
            _studentId,
            _name,
            _major,
            _year,
            supervisorAddress
        );
    }

    function deleteStudent(uint256 _studentId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Student does not exist");

        // Get all enrollments from Enrollment contract
        Enrollment.EnrollmentRecord[] memory enrollments = enrollmentContract.getStudentEnrollments(_studentId);

        // Unenroll from all courses
        for (uint256 i = 0; i < enrollments.length; i++) {
            if (enrollments[i].active) {
                enrollmentContract.unenrollStudent(_studentId, enrollments[i].courseId);
            }
        }

        // Delete the student
        studentContract.deleteStudent(_studentId);
    }

    function getStudent(uint256 _studentId) external view returns (Student.StudentInfo memory) {
        return studentContract.getStudent(_studentId);
    }

    function enrollStudentInCourse(uint256 _studentId, string memory _courseId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Invalid student");
        require(courseContract.exists(_courseId), "Invalid course");

        // Check if already enrolled through Enrollment contract
        bytes32 key = enrollmentContract.getEnrollmentKey(_studentId, _courseId);
        require(!enrollmentContract.getEnrollment(key).active, "Already enrolled");

        enrollmentContract.enrollStudent(_studentId, _courseId);
    }

    function removeCourseFromStudent(uint256 _studentId, string memory _courseId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Invalid student");
        require(courseContract.exists(_courseId), "Invalid course");

        // Check if enrolled through Enrollment contract
        bytes32 key = enrollmentContract.getEnrollmentKey(_studentId, _courseId);
        if (enrollmentContract.getEnrollment(key).active) {
            enrollmentContract.unenrollStudent(_studentId, _courseId);
        }
    }

    function clearAllCoursesForStudent(uint256 _studentId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Student does not exist");

        // Get all enrollments from Enrollment contract
        Enrollment.EnrollmentRecord[] memory enrollments = enrollmentContract.getStudentEnrollments(_studentId);

        // Unenroll from all courses
        for (uint256 i = 0; i < enrollments.length; i++) {
            if (enrollments[i].active) {
                enrollmentContract.unenrollStudent(_studentId, enrollments[i].courseId);
            }
        }
    }

    function addProfessor(string memory _name, string memory _department) external onlyAuthorized returns (uint256) {
        return professorContract.addProfessor(_name, _department);
    }

    function getProfessor(uint256 _professorId) external view returns (Professor.ProfessorInfo memory) {
        return professorContract.getProfessor(_professorId);
    }

    function deleteProfessor(uint256 _professorId) external onlyAuthorized {
        require(professorContract.isActive(_professorId), "Professor does not exist");

        Course.CourseInfo[] memory professorCourses = courseContract.getCoursesByProfessor(_professorId);

        for (uint256 i = 0; i < professorCourses.length; i++) {
            courseContract.deleteCourse(professorCourses[i].id);
        }

        professorContract.removeProfessor(_professorId);
    }

    function getAllStudents() external view returns (uint256[] memory) {
        return studentContract.getAllStudents();
    }

    function getAllProfessors() external view returns (uint256[] memory) {
        return professorContract.getActiveProfessors();
    }

    function getAllCourses() external view returns (string[] memory) {
        return courseContract.getAllCourses();
    }

    function updateProfessor(
        uint256 _professorId,
        string memory _name,
        string memory _department
    ) external onlyAuthorized {
        professorContract.updateProfessor(_professorId, _name, _department);
    }

    function updateCourse(
        string memory _courseId,
        string memory _name
    ) external onlyAuthorized {
        courseContract.updateCourse(_courseId, _name);
    }
}