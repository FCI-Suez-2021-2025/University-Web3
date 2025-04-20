// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Professor.sol";
import "./Student.sol";

/**
 * @title Course Management Contract
 * @dev Handles course creation, enrollment, and professor assignments
 * @author Enhanced by Claude
 */
contract Course {
    /// @notice Course information structure
    struct CourseInfo {
        string id;
        string name;
        uint256 professorId;
        uint256 studentCount;
        bool active;  // Track if course is active
    }

    /// @dev Core course storage
    mapping(string => CourseInfo) public courses;

    /// @dev Professor course assignments
    mapping(uint256 => string[]) public professorCourses;

    /// @dev Course existence tracking
    mapping(string => bool) public exists;

    /// @dev Enrollment tracking
    mapping(string => mapping(uint256 => bool)) public isEnrolled;

    /// @dev Store enrolled students per course
    mapping(string => uint256[]) public enrolledStudents;

    /// @dev Student index mapping for efficient removal
    mapping(string => mapping(uint256 => uint256)) private _studentIndices;

    /// @dev Mapping course to index in professor's course list for efficient removal
    mapping(string => mapping(uint256 => uint256)) private _professorCourseIndices;

    /// @dev List of all course IDs
    string[] public allCourses;

    Professor public professorContract;
    Student public studentContract;

    event CourseCreated(string indexed courseId, uint256 professorId);
    event CourseUpdated(string indexed courseId);
    event CourseDeleted(string indexed courseId);
    event StudentEnrolled(string indexed courseId, uint256 studentId);
    event StudentUnenrolled(string indexed courseId, uint256 studentId);
    event CourseReassigned(string indexed courseId, uint256 oldProfessorId, uint256 newProfessorId);

    constructor(address _professorContract, address _studentContract) {
        professorContract = Professor(_professorContract);
        studentContract = Student(_studentContract);
    }

    /**
     * @notice Create a new course
     * @param _courseId Unique course identifier
     * @param _name Course name
     * @param _professorId Assigning professor ID
     */
    function createCourse(
        string memory _courseId,
        string memory _name,
        uint256 _professorId
    ) external {
        require(!exists[_courseId], "Course already exists");
        require(professorContract.isActive(_professorId), "Invalid professor");

        courses[_courseId] = CourseInfo({
            id: _courseId,
            name: _name,
            professorId: _professorId,
            studentCount: 0,
            active: true
        });

        professorCourses[_professorId].push(_courseId);
        _professorCourseIndices[_courseId][_professorId] = professorCourses[_professorId].length - 1;
        exists[_courseId] = true;
        allCourses.push(_courseId);

        emit CourseCreated(_courseId, _professorId);
    }

    /**
     * @notice Update course details
     * @param _courseId Course identifier
     * @param _name New course name (empty string to keep current)
     */
    function updateCourse(
        string memory _courseId,
        string memory _name
    ) external {
        require(exists[_courseId], "Course does not exist");

        if (bytes(_name).length > 0) {
            courses[_courseId].name = _name;
        }

        emit CourseUpdated(_courseId);
    }

    /**
     * @notice Reassign a course to a new professor
     * @param _courseId Course identifier
     * @param _newProfessorId New professor ID
     */
    function reassignCourse(string memory _courseId, uint256 _newProfessorId) external {
        require(exists[_courseId], "Course does not exist");
        require(professorContract.isActive(_newProfessorId), "Invalid professor");

        uint256 oldProfessorId = courses[_courseId].professorId;

        // Don't do anything if it's the same professor
        if (oldProfessorId == _newProfessorId) {
            return;
        }

        // Remove from old professor's list using the stored index
        uint256 index = _professorCourseIndices[_courseId][oldProfessorId];
        uint256 lastIndex = professorCourses[oldProfessorId].length - 1;

        if (index != lastIndex) {
            string memory lastCourse = professorCourses[oldProfessorId][lastIndex];
            professorCourses[oldProfessorId][index] = lastCourse;
            _professorCourseIndices[lastCourse][oldProfessorId] = index;
        }

        professorCourses[oldProfessorId].pop();
        delete _professorCourseIndices[_courseId][oldProfessorId];

        // Update professor ID and add to new list
        courses[_courseId].professorId = _newProfessorId;
        professorCourses[_newProfessorId].push(_courseId);
        _professorCourseIndices[_courseId][_newProfessorId] = professorCourses[_newProfessorId].length - 1;

        emit CourseReassigned(_courseId, oldProfessorId, _newProfessorId);
    }

    /**
     * @notice Get all courses taught by a professor
     * @param _professorId Professor ID
     * @return Array of course information
     */
    function getCoursesByProfessor(uint256 _professorId) external view returns (CourseInfo[] memory) {
        require(professorContract.isActive(_professorId), "Invalid professor");

        string[] storage courseIds = professorCourses[_professorId];
        CourseInfo[] memory result = new CourseInfo[](courseIds.length);

        for (uint256 i = 0; i < courseIds.length; i++) {
            result[i] = courses[courseIds[i]];
        }
        return result;
    }

    /**
     * @notice Get course by string ID
     * @param _courseId Course identifier
     * @return Course information
     */
    function getCourse(string memory _courseId) external view returns (CourseInfo memory) {
        require(exists[_courseId], "Course does not exist");
        return courses[_courseId];
    }

    /**
     * @notice Get all courses
     * @return Array of course IDs
     */
    function getAllCourses() external view returns (string[] memory) {
        return allCourses;
    }

    /**
     * @notice Delete a course
     * @param _courseId Course identifier
     */
    function deleteCourse(string memory _courseId) external {
        require(exists[_courseId], "Course does not exist");
        uint256 professorId = courses[_courseId].professorId;

        // Remove course from professor's list
        uint256 profIndex = _professorCourseIndices[_courseId][professorId];
        uint256 profLastIndex = professorCourses[professorId].length - 1;

        if (profIndex != profLastIndex) {
            string memory lastCourse = professorCourses[professorId][profLastIndex];
            professorCourses[professorId][profIndex] = lastCourse;
            _professorCourseIndices[lastCourse][professorId] = profIndex;
        }

        professorCourses[professorId].pop();
        delete _professorCourseIndices[_courseId][professorId];

        // Remove course from all enrolled students
        uint256[] storage studentsInCourse = enrolledStudents[_courseId];
        for (uint256 i = 0; i < studentsInCourse.length; i++) {
            uint256 studentId = studentsInCourse[i];
            // Only attempt to remove if student is active
            if (studentContract.isActive(studentId)) {
                // Skip internal transaction if they're not enrolled
                if (studentContract.isEnrolled(studentId, _courseId)) {
                    studentContract.removeCourse(studentId, _courseId);
                }
            }
            delete isEnrolled[_courseId][studentId];
        }

        // Remove from allCourses array
        uint256 courseIndex = _findCourseIndex(_courseId);
        uint256 courseLastIndex = allCourses.length - 1;

        if (courseIndex != courseLastIndex) {
            string memory lastCourseId = allCourses[courseLastIndex];
            allCourses[courseIndex] = lastCourseId;
        }

        allCourses.pop();

        // Delete course data
        delete enrolledStudents[_courseId];
        delete exists[_courseId];
        courses[_courseId].active = false;

        emit CourseDeleted(_courseId);
    }

    /**
     * @notice Enroll student in course
     * @param _courseId Target course ID
     * @param _studentId Student ID to enroll
     */
    function enrollStudent(
        string memory _courseId,
        uint256 _studentId
    ) external {
        require(exists[_courseId], "Invalid course");
        require(studentContract.isActive(_studentId), "Invalid student");
        require(!isEnrolled[_courseId][_studentId], "Already enrolled");

        courses[_courseId].studentCount++;
        isEnrolled[_courseId][_studentId] = true;

        // Add to enrolled students array
        enrolledStudents[_courseId].push(_studentId);
        _studentIndices[_courseId][_studentId] = enrolledStudents[_courseId].length - 1;

        emit StudentEnrolled(_courseId, _studentId);
    }

    /**
     * @notice Get all students enrolled in a course
     * @param _courseId Course identifier
     * @return Array of student IDs
     */
    function getEnrolledStudents(string memory _courseId) external view returns (uint256[] memory) {
        require(exists[_courseId], "Course does not exist");
        return enrolledStudents[_courseId];
    }

    /**
     * @notice Remove student from course enrollment
     * @param _studentId Student ID
     * @param _courseId Course ID
     */
    function unEnrollStudent(uint256 _studentId, string memory _courseId) external {
        require(exists[_courseId], "Course does not exist");
        require(isEnrolled[_courseId][_studentId], "Student not enrolled in this course");

        // Remove from enrolled students using efficient swap and pop
        uint256 index = _studentIndices[_courseId][_studentId];
        uint256 lastIndex = enrolledStudents[_courseId].length - 1;

        if (index != lastIndex) {
            uint256 lastStudentId = enrolledStudents[_courseId][lastIndex];
            enrolledStudents[_courseId][index] = lastStudentId;
            _studentIndices[_courseId][lastStudentId] = index;
        }

        enrolledStudents[_courseId].pop();
        delete _studentIndices[_courseId][_studentId];
        delete isEnrolled[_courseId][_studentId];

        // Update course student count
        if (courses[_courseId].studentCount > 0) {
            courses[_courseId].studentCount--;
        }

        emit StudentUnenrolled(_courseId, _studentId);
    }

    /**
     * @dev Find index of a course in allCourses array
     * @param _courseId Course identifier
     * @return Index position
     */
    function _findCourseIndex(string memory _courseId) private view returns (uint256) {
        for (uint256 i = 0; i < allCourses.length; i++) {
            if (keccak256(bytes(allCourses[i])) == keccak256(bytes(_courseId))) {
                return i;
            }
        }
        revert("Course not found in index");
    }
}