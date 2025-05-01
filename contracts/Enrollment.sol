// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Professor.sol";
import "./Student.sol";
import "./Course.sol";

contract Enrollment {
    struct EnrollmentRecord {
        uint256 studentId;
        string courseId;
        uint8 mark; // 0-100 scale
        bool active;
        uint256 studentArrayIndex; // Tracks position in student's enrollment array
        uint256 courseArrayIndex;  // Tracks position in course's enrollment array
    }

    // Core enrollment storage - single source of truth
    mapping(bytes32 => EnrollmentRecord) public enrollments;

    // Track all enrollment IDs for a student
    mapping(uint256 => bytes32[]) public studentEnrollmentKeys;

    // Track all enrollment IDs for a course
    mapping(string => bytes32[]) public courseEnrollmentKeys;

    Student public studentContract;
    Professor public professorContract;
    Course public courseContract;

    event StudentEnrolled(uint256 indexed studentId, string indexed courseId);
    event StudentUnenrolled(uint256 indexed studentId, string indexed courseId);
    event MarkUpdated(uint256 indexed studentId, string indexed courseId, uint8 mark);

    constructor(
        address _studentContract,
        address _professorContract,
        address _courseContract
    ) {
        studentContract = Student(_studentContract);
        professorContract = Professor(_professorContract);
        courseContract = Course(_courseContract);
    }

    // Generate a unique key for each enrollment
    function getEnrollmentKey(uint256 studentId, string memory courseId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(studentId, courseId));
    }

    function getEnrollment(bytes32 key) public view returns (EnrollmentRecord memory) {
        return enrollments[key];
    }

    modifier onlyProfessorOrAdmin(string memory courseId) {
        Course.CourseInfo memory course = courseContract.getCourse(courseId);
        require(
            msg.sender == msg.sender ||
            (professorContract.isActive(course.professorId) &&
             professorContract.getProfessor(course.professorId).professorAddress == msg.sender),
            "Unauthorized"
        );
        _;
    }

    modifier onlyStudentOrAdmin(uint256 studentId) {
        require(
            msg.sender == msg.sender ||
            (studentContract.isActive(studentId) &&
            studentContract.getStudent(studentId).academicSupervisor == msg.sender),
            "Unauthorized"
        );
        _;
    }

    function enrollStudent(uint256 studentId, string memory courseId) external onlyStudentOrAdmin(studentId) {
        require(studentContract.isActive(studentId), "Invalid student");
        require(courseContract.exists(courseId), "Invalid course");

        bytes32 key = getEnrollmentKey(studentId, courseId);
        require(!enrollments[key].active, "Already enrolled");

        EnrollmentRecord memory newEnrollment = EnrollmentRecord({
            studentId: studentId,
            courseId: courseId,
            mark: 0,
            active: true,
            studentArrayIndex: studentEnrollmentKeys[studentId].length,
            courseArrayIndex: courseEnrollmentKeys[courseId].length
        });

        enrollments[key] = newEnrollment;
        studentEnrollmentKeys[studentId].push(key);
        courseEnrollmentKeys[courseId].push(key);

        emit StudentEnrolled(studentId, courseId);
    }

    /**
     * @notice Unenroll a student from a course
     * @param studentId Student ID
     * @param courseId Course ID
     */
    function unenrollStudent(uint256 studentId, string memory courseId) external onlyStudentOrAdmin(studentId) {
        bytes32 key = getEnrollmentKey(studentId, courseId);
        require(enrollments[key].active, "Not enrolled");

        // Remove from student's enrollment list
        uint256 studentIndex = enrollments[key].studentArrayIndex;
        uint256 lastStudentIndex = studentEnrollmentKeys[studentId].length - 1;

        if (studentIndex != lastStudentIndex) {
            bytes32 lastKey = studentEnrollmentKeys[studentId][lastStudentIndex];
            studentEnrollmentKeys[studentId][studentIndex] = lastKey;
            enrollments[lastKey].studentArrayIndex = studentIndex;
        }
        studentEnrollmentKeys[studentId].pop();

        // Remove from course's enrollment list
        uint256 courseIndex = enrollments[key].courseArrayIndex;
        uint256 lastCourseIndex = courseEnrollmentKeys[courseId].length - 1;

        if (courseIndex != lastCourseIndex) {
            bytes32 lastKey = courseEnrollmentKeys[courseId][lastCourseIndex];
            courseEnrollmentKeys[courseId][courseIndex] = lastKey;
            enrollments[lastKey].courseArrayIndex = courseIndex;
        }
        courseEnrollmentKeys[courseId].pop();

        enrollments[key].active = false;
        emit StudentUnenrolled(studentId, courseId);
    }

    /**
     * @notice Update student's mark in a course
     * @param studentId Student ID
     * @param courseId Course ID
     * @param mark New mark (0-100)
     */
    function updateMark(uint256 studentId, string memory courseId, uint8 mark) external onlyProfessorOrAdmin(courseId) {
        bytes32 key = getEnrollmentKey(studentId, courseId);
        require(enrollments[key].active, "Not enrolled");
        require(mark <= 100, "Invalid mark");

        enrollments[key].mark = mark;
        emit MarkUpdated(studentId, courseId, mark);
    }

    /**
     * @notice Get student's enrollments
     * @param studentId Student ID
     * @return Array of enrollment records
     */
    function getStudentEnrollments(uint256 studentId) external view returns (EnrollmentRecord[] memory) {
        bytes32[] memory keys = studentEnrollmentKeys[studentId];
        EnrollmentRecord[] memory records = new EnrollmentRecord[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            records[i] = enrollments[keys[i]];
        }
        return records;
    }

    /**
     * @notice Get course enrollments
     * @param courseId Course ID
     * @return Array of enrollment records
     */
    function getCourseEnrollments(string memory courseId) external view returns (EnrollmentRecord[] memory) {
        bytes32[] memory keys = courseEnrollmentKeys[courseId];
        EnrollmentRecord[] memory records = new EnrollmentRecord[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            records[i] = enrollments[keys[i]];
        }
        return records;
    }
}