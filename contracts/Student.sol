// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Student Management Contract
 * @dev Manages student records and course enrollments
 * @author Enhanced by Claude
 */
contract Student {
    /// @notice Student information structure
    struct StudentInfo {
        uint256 id;
        string name;
        string major;
        uint256 year;
        address academicSupervisor;
        bool active;  // Integrated active status
    }

    /// @dev Mapping of student IDs to their information
    mapping(uint256 => StudentInfo) public students;

    /// @dev Tracks active student status (maintained for backward compatibility)
    mapping(uint256 => bool) public isActive;

    /// @dev Mapping of enrolled courses per student
    mapping(uint256 => string[]) public enrolledCourses;

    /// @dev Enrollment status tracking
    mapping(uint256 => mapping(string => bool)) public isEnrolled;

    /// @dev Course index mapping for efficient removal
    mapping(uint256 => mapping(string => uint256)) private _courseIndices;

    /// @dev Auto-incrementing ID counter
    uint256 public nextId = 1;

    /// @dev List of all student IDs for enumeration
    uint256[] public allStudents;

    event StudentAdded(uint256 indexed studentId);
    event StudentUpdated(uint256 indexed studentId);
    event StudentDeleted(uint256 indexed studentId);
    event StudentEnrolled(uint256 indexed studentId, string courseId);
    event CourseRemoved(uint256 indexed studentId, string courseId);
    event AllCoursesRemoved(uint256 indexed studentId);

    /**
     * @notice Add a new student
     * @param _name Student's name
     * @param _major Field of study
     * @param _year Enrollment year
     * @param _supervisor Academic supervisor address
     * @return id The ID of the newly created student
     */
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

    /**
     * @notice Update student information
     * @param _id Student ID
     * @param _name New name (empty string to keep current)
     * @param _major New major (empty string to keep current)
     * @param _year New year (0 to keep current)
     * @param _academicSupervisorAddress New supervisor address (address(0) to keep current)
     */
    function updateStudent(
        uint256 _id,
        string memory _name,
        string memory _major,
        uint256 _year,
        address _academicSupervisorAddress
    ) external {
        require(isActive[_id], "Student does not exist");
        StudentInfo storage student = students[_id];

        if (bytes(_name).length > 0) {
            student.name = _name;
        }
        if (bytes(_major).length > 0) {
            student.major = _major;
        }
        if (_year > 0) {
            student.year = _year;
        }
        if (_academicSupervisorAddress != address(0)) {
            student.academicSupervisor = _academicSupervisorAddress;
        }

        emit StudentUpdated(_id);
    }

    /**
     * @notice Delete a student
     * @param _id Student ID to delete
     */
    function deleteStudent(uint256 _id) external {
        require(isActive[_id], "Student does not exist");

        // Use swap and pop for gas efficiency
        uint256 index = _findStudentIndex(_id);
        uint256 lastIndex = allStudents.length - 1;

        if(index != lastIndex) {
            allStudents[index] = allStudents[lastIndex];
        }

        allStudents.pop();
        isActive[_id] = false;
        students[_id].active = false;

        emit StudentDeleted(_id);
    }

    /**
     * @notice Get student information
     * @param _id Student ID
     * @return Student information
     */
    function getStudent(uint256 _id) external view returns (StudentInfo memory) {
        require(isActive[_id], "Student does not exist");
        return students[_id];
    }

    /**
     * @notice Get all active students
     * @return Array of student IDs
     */
    function getAllStudents() external view returns (uint256[] memory) {
        return allStudents;
    }

    /**
     * @notice Enroll student in a course
     * @param _studentId Student ID
     * @param _courseId Course ID to enroll in
     */
    function enrollInCourse(
        uint256 _studentId,
        string memory _courseId
    ) external {
        require(isActive[_studentId], "Invalid student");
        require(!isEnrolled[_studentId][_courseId], "Already enrolled");

        enrolledCourses[_studentId].push(_courseId);
        isEnrolled[_studentId][_courseId] = true;
        _courseIndices[_studentId][_courseId] = enrolledCourses[_studentId].length - 1;

        emit StudentEnrolled(_studentId, _courseId);
    }

    /**
     * @notice Remove course from student's enrollment
     * @param _studentId Student ID
     * @param _courseId Course ID to remove
     */
    function removeCourse(
        uint256 _studentId,
        string memory _courseId
    ) external {
        require(isEnrolled[_studentId][_courseId], "Not enrolled in this course");

        uint256 index = _courseIndices[_studentId][_courseId];
        uint256 lastIndex = enrolledCourses[_studentId].length - 1;

        if(index != lastIndex) {
            string memory lastCourse = enrolledCourses[_studentId][lastIndex];
            enrolledCourses[_studentId][index] = lastCourse;
            _courseIndices[_studentId][lastCourse] = index;
        }

        enrolledCourses[_studentId].pop();
        delete isEnrolled[_studentId][_courseId];
        delete _courseIndices[_studentId][_courseId];

        emit CourseRemoved(_studentId, _courseId);
    }

    /**
     * @notice Delete all course enrollments for a student
     * @param _studentId Student ID
     */
    function deleteAllCoursesForStudent(uint256 _studentId) external {
        require(isActive[_studentId], "Student does not exist");

        string[] memory courses = enrolledCourses[_studentId];
        for (uint256 i = 0; i < courses.length; i++) {
            delete isEnrolled[_studentId][courses[i]];
            delete _courseIndices[_studentId][courses[i]];
        }

        delete enrolledCourses[_studentId];

        emit AllCoursesRemoved(_studentId);
    }

    /**
     * @notice Get all courses for a student
     * @param _studentId Student ID
     * @return Array of course IDs
     */
    function getEnrolledCourses(uint256 _studentId) external view returns (string[] memory) {
        require(isActive[_studentId], "Student does not exist");
        return enrolledCourses[_studentId];
    }

    /**
     * @dev Helper function to find student index in allStudents array
     * @param _id Student ID
     * @return Index position
     */
    function _findStudentIndex(uint256 _id) private view returns (uint256) {
        for (uint256 i = 0; i < allStudents.length; i++) {
            if (allStudents[i] == _id) {
                return i;
            }
        }
        revert("Student not found in index");
    }
}