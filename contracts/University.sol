// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Student.sol";
import "./Professor.sol";
import "./Course.sol";

/**
 * @title University Main Contract
 * @dev Orchestrates university operations with batch capabilities
 * @author Enhanced by Claude
 */
contract University {
    address public immutable admin;
    Student public studentContract;
    Professor public professorContract;
    Course public courseContract;

    /// @dev Course management permissions
    mapping(address => bool) public authorizedInstructors;

    event BatchEnrollment(uint256[] studentIds, string courseId);
    event InstructorAuthorized(address indexed account);
    event InstructorDeauthorized(address indexed account);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized: admin only");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedInstructors[msg.sender] || msg.sender == admin, "Unauthorized: not an authorized instructor");
        _;
    }

    constructor(
        address _studentContract,
        address _professorContract,
        address _courseContract
    ) {
        admin = msg.sender;
        studentContract = Student(_studentContract);
        professorContract = Professor(_professorContract);
        courseContract = Course(_courseContract);

        // Admin is automatically authorized
        authorizedInstructors[admin] = true;
    }

    /**
     * @notice Authorize course instructor
     * @param _instructorAddress Account to authorize
     */
    function authorizeInstructor(address _instructorAddress) external onlyAdmin {
        authorizedInstructors[_instructorAddress] = true;
        emit InstructorAuthorized(_instructorAddress);
    }

    /**
     * @notice Remove instructor authorization
     * @param _instructorAddress Account to deauthorize
     */
    function deauthorizeInstructor(address _instructorAddress) external onlyAdmin {
        require(_instructorAddress != admin, "Cannot deauthorize admin");
        authorizedInstructors[_instructorAddress] = false;
        emit InstructorDeauthorized(_instructorAddress);
    }

    /**
     * @notice Batch enroll students in course
     * @param _studentIds Array of student IDs
     * @param _courseId Target course ID
     */
    function batchEnroll(
        uint256[] calldata _studentIds,
        string calldata _courseId
    ) external onlyAuthorized {
        require(courseContract.exists(_courseId), "Invalid course");

        for(uint256 i = 0; i < _studentIds.length; i++) {
            uint256 studentId = _studentIds[i];
            if(studentContract.isActive(studentId) && !courseContract.isEnrolled(_courseId, studentId)) {
                // Only enroll if not already enrolled
                studentContract.enrollInCourse(studentId, _courseId);
                courseContract.enrollStudent(_courseId, studentId);
            }
        }

        emit BatchEnrollment(_studentIds, _courseId);
    }

    /**
     * @notice Create new course with instructor
     * @param _courseId Course unique identifier
     * @param _name Course name
     * @param _professorId Professor ID
     */
    function createCourse(
        string memory _courseId,
        string memory _name,
        uint256 _professorId
    ) external onlyAuthorized {
        courseContract.createCourse(_courseId, _name, _professorId);
    }

    /**
     * @notice Get student enrollment details
     * @param _studentId Student ID
     * @return courseIds Array of course IDs
     * @return courseNames Array of course names
     * @return professorNames Array of professor names
     * @return departments Array of departments
     */
    function getStudentEnrollments(uint256 _studentId) external view returns (
        string[] memory courseIds,
        string[] memory courseNames,
        string[] memory professorNames,
        string[] memory departments
    ) {
        require(studentContract.isActive(_studentId), "Student does not exist");

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

    /**
     * @notice Reassign a course to a new professor
     * @param _courseId Course identifier
     * @param _newProfessorId New professor ID
     */
    function reassignCourse(string memory _courseId, uint256 _newProfessorId) external onlyAuthorized {
        courseContract.reassignCourse(_courseId, _newProfessorId);
    }

    /**
     * @notice Delete a course
     * @param _courseId Course identifier
     */
    function deleteCourse(string memory _courseId) external onlyAuthorized {
        courseContract.deleteCourse(_courseId);
    }


    /**
     * @notice Add a new student
     * @param _name Student name
     * @param _major Field of study
     * @param _year Enrollment year
     * @param _professorId Academic supervisor professor ID
     * @return New student ID
     */
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

    /**
     * @notice Update student information
     * @param _studentId Student ID
     * @param _name New name (empty string to keep current)
     * @param _major New major (empty string to keep current)
     * @param _year New year (0 to keep current)
     * @param _professorId New professor ID (0 to keep current)
     */
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
            // Keep the existing supervisor address if no new professor ID is provided
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

    /**
     * @notice Delete a student
     * @param _studentId Student ID to delete
     */
    function deleteStudent(uint256 _studentId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Student does not exist");

        // First remove all course enrollments
        string[] memory courses = studentContract.getEnrolledCourses(_studentId);
        for (uint256 i = 0; i < courses.length; i++) {
            // Only unenroll if course exists
            if (courseContract.exists(courses[i])) {
                courseContract.unEnrollStudent(_studentId, courses[i]);
            }
        }

        // Clear all courses internally
        studentContract.deleteAllCoursesForStudent(_studentId);

        // Delete the student
        studentContract.deleteStudent(_studentId);
    }

    /**
     * @notice Get student information
     * @param _studentId Student ID
     * @return Student information
     */
    function getStudent(uint256 _studentId) external view returns (Student.StudentInfo memory) {
        return studentContract.getStudent(_studentId);
    }

    /**
     * @notice Enroll a student in a course
     * @param _studentId Student ID
     * @param _courseId Course ID
     */
    function enrollStudentInCourse(uint256 _studentId, string memory _courseId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Invalid student");
        require(courseContract.exists(_courseId), "Invalid course");
        require(!studentContract.isEnrolled(_studentId, _courseId), "Already enrolled");
        require(!courseContract.isEnrolled(_courseId, _studentId), "Already enrolled in course");

        // Enroll in both Student and Course contracts
        studentContract.enrollInCourse(_studentId, _courseId);
        courseContract.enrollStudent(_courseId, _studentId);
    }

    /**
     * @notice Remove a student from a course
     * @param _studentId Student ID
     * @param _courseId Course ID
     */
    function removeCourseFromStudent(uint256 _studentId, string memory _courseId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Invalid student");
        require(courseContract.exists(_courseId), "Invalid course");

        // Only execute if actually enrolled
        if (studentContract.isEnrolled(_studentId, _courseId)) {
            studentContract.removeCourse(_studentId, _courseId);
        }

        if (courseContract.isEnrolled(_courseId, _studentId)) {
            courseContract.unEnrollStudent(_studentId, _courseId);
        }
    }

    /**
     * @notice Clear all course enrollments for a student
     * @param _studentId Student ID
     */
    function clearAllCoursesForStudent(uint256 _studentId) external onlyAuthorized {
        require(studentContract.isActive(_studentId), "Student does not exist");

        // Get all courses first
        string[] memory courses = studentContract.getEnrolledCourses(_studentId);

        // Unenroll from each course
        for (uint256 i = 0; i < courses.length; i++) {
            if (courseContract.exists(courses[i]) && courseContract.isEnrolled(courses[i], _studentId)) {
                courseContract.unEnrollStudent(_studentId, courses[i]);
            }
        }

        // Clear all courses in the student contract
        studentContract.deleteAllCoursesForStudent(_studentId);
    }

    /**
     * @notice Add a new professor
     * @param _name Professor name
     * @param _department Department
     * @return New professor ID
     */
    function addProfessor(string memory _name, string memory _department) external onlyAuthorized returns (uint256) {
        return professorContract.addProfessor(_name, _department);
    }

    /**
     * @notice Get professor information
     * @param _professorId Professor ID
     * @return Professor information
     */
    function getProfessor(uint256 _professorId) external view returns (Professor.ProfessorInfo memory) {
        return professorContract.getProfessor(_professorId);
    }

    /**
     * @notice Delete a professor
     * @param _professorId Professor ID
     */
    function deleteProfessor(uint256 _professorId) external onlyAuthorized {
        require(professorContract.isActive(_professorId), "Professor does not exist");

        // Get all courses for this professor
        Course.CourseInfo[] memory professorCourses = courseContract.getCoursesByProfessor(_professorId);

        // Either reassign or delete all courses
        for (uint256 i = 0; i < professorCourses.length; i++) {
            // For this example, we'll delete the courses
            // In a real implementation, you might want to reassign them
            courseContract.deleteCourse(professorCourses[i].id);
        }

        // Now delete the professor
        professorContract.removeProfessor(_professorId);
    }

    /**
     * @notice Get all students
     * @return Array of student IDs
     */
    function getAllStudents() external view returns (uint256[] memory) {
        return studentContract.getAllStudents();
    }

    /**
     * @notice Get all professors
     * @return Array of professor IDs
     */
    function getAllProfessors() external view returns (uint256[] memory) {
        return professorContract.getActiveProfessors();
    }

    /**
     * @notice Get all courses
     * @return Array of course IDs
     */
    function getAllCourses() external view returns (string[] memory) {
        return courseContract.getAllCourses();
    }

    /**
     * @notice Update professor information
     * @param _professorId Professor ID
     * @param _name New name (empty string to keep current)
     * @param _department New department (empty string to keep current)
     */
    function updateProfessor(
        uint256 _professorId,
        string memory _name,
        string memory _department
    ) external onlyAuthorized {
        professorContract.updateProfessor(_professorId, _name, _department);
    }

    /**
     * @notice Update course information
     * @param _courseId Course ID
     * @param _name New name (empty string to keep current)
     */
    function updateCourse(
        string memory _courseId,
        string memory _name
    ) external onlyAuthorized {
        courseContract.updateCourse(_courseId, _name);
    }
}