// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Professor.sol";

contract Course {
    struct CourseInfo {
        string id;
        string name;
        uint256 professorId;
        bool active;
    }

    mapping(string => CourseInfo) public courses;
    mapping(uint256 => string[]) public professorCourses;
    mapping(string => bool) public exists;
    string[] public allCourses;

    Professor public professorContract;

    event CourseCreated(string indexed courseId, uint256 professorId);
    event CourseUpdated(string indexed courseId);
    event CourseDeleted(string indexed courseId);
    event CourseReassigned(string indexed courseId, uint256 oldProfessorId, uint256 newProfessorId);

    constructor(address _professorContract) {
        professorContract = Professor(_professorContract);
    }

    function createCourse(string memory _courseId, string memory _name, uint256 _professorId) external {
        require(!exists[_courseId], "Course exists");
        require(professorContract.isActive(_professorId), "Invalid professor");

        courses[_courseId] = CourseInfo({
            id: _courseId,
            name: _name,
            professorId: _professorId,
            active: true
        });

        professorCourses[_professorId].push(_courseId);
        exists[_courseId] = true;
        allCourses.push(_courseId);

        emit CourseCreated(_courseId, _professorId);
    }

    function updateCourse(string memory _courseId, string memory _name) external {
        require(exists[_courseId], "Course doesn't exist");
        if (bytes(_name).length > 0) {
            courses[_courseId].name = _name;
        }
        emit CourseUpdated(_courseId);
    }

    function reassignCourse(string memory _courseId, uint256 _newProfessorId) external {
        require(exists[_courseId], "Course doesn't exist");
        require(professorContract.isActive(_newProfessorId), "Invalid professor");

        uint256 oldProfessorId = courses[_courseId].professorId;
        if (oldProfessorId == _newProfessorId) return;

        // Remove from old professor's list
        string[] storage oldList = professorCourses[oldProfessorId];
        for (uint256 i = 0; i < oldList.length; i++) {
            if (keccak256(bytes(oldList[i])) == keccak256(bytes(_courseId))) {
                oldList[i] = oldList[oldList.length - 1];
                oldList.pop();
                break;
            }
        }

        // Add to new professor's list
        courses[_courseId].professorId = _newProfessorId;
        professorCourses[_newProfessorId].push(_courseId);

        emit CourseReassigned(_courseId, oldProfessorId, _newProfessorId);
    }

    function deleteCourse(string memory _courseId) external {
        require(exists[_courseId], "Course doesn't exist");

        uint256 professorId = courses[_courseId].professorId;

        // Remove from professor's list
        string[] storage profCourses = professorCourses[professorId];
        for (uint256 i = 0; i < profCourses.length; i++) {
            if (keccak256(bytes(profCourses[i])) == keccak256(bytes(_courseId))) {
                profCourses[i] = profCourses[profCourses.length - 1];
                profCourses.pop();
                break;
            }
        }

        // Remove from allCourses
        for (uint256 i = 0; i < allCourses.length; i++) {
            if (keccak256(bytes(allCourses[i])) == keccak256(bytes(_courseId))) {
                allCourses[i] = allCourses[allCourses.length - 1];
                allCourses.pop();
                break;
            }
        }

        delete exists[_courseId];
        courses[_courseId].active = false;
        emit CourseDeleted(_courseId);
    }

    function getCoursesByProfessor(uint256 _professorId) external view returns (CourseInfo[] memory) {
        string[] storage courseIds = professorCourses[_professorId];
        CourseInfo[] memory result = new CourseInfo[](courseIds.length);

        for (uint256 i = 0; i < courseIds.length; i++) {
            result[i] = courses[courseIds[i]];
        }
        return result;
    }

    function getCourse(string memory _courseId) external view returns (CourseInfo memory) {
        require(exists[_courseId], "Course doesn't exist");
        return courses[_courseId];
    }

    function getAllCourses() external view returns (string[] memory) {
        return allCourses;
    }
}