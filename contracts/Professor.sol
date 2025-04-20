// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Professor Management Contract
 * @dev Manages professor records and active status tracking
 * @author Enhanced by Claude
 */
contract Professor {
    /// @notice Professor information structure
    struct ProfessorInfo {
        uint256 id;
        address professorAddress;
        string name;
        string department;
        bool active;  // Integrated active status into struct
    }

    /// @dev Mapping of professor IDs to their information
    mapping(uint256 => ProfessorInfo) public professors;

    /// @dev Tracks active professor status (maintained for backward compatibility)
    mapping(uint256 => bool) public isActive;

    /// @dev Array of all professor IDs for enumeration
    uint256[] public allProfessors;

    /// @dev Mapping from professor address to ID for quick lookup
    mapping(address => uint256) public addressToId;

    /// @dev Auto-incrementing ID counter
    uint256 public nextId = 1;

    event ProfessorAdded(uint256 indexed professorId, address indexed account);
    event ProfessorRemoved(uint256 indexed professorId);
    event ProfessorUpdated(uint256 indexed professorId);

    /**
     * @notice Add a new professor
     * @param _name Professor's name
     * @param _department Department affiliation
     * @return id The ID of the newly created professor
     */
    function addProfessor(
        string memory _name,
        string memory _department
    ) external returns (uint256) {
        uint256 id = nextId++;

        professors[id] = ProfessorInfo({
            id: id,
            professorAddress: msg.sender,
            name: _name,
            department: _department,
            active: true
        });

        isActive[id] = true;
        allProfessors.push(id);
        addressToId[msg.sender] = id;

        emit ProfessorAdded(id, msg.sender);
        return id;
    }

    /**
     * @notice Remove a professor
     * @param _id ID of professor to remove
     * @dev Uses swap-and-pop pattern for efficient deletion
     */
    function removeProfessor(uint256 _id) external {
        require(isActive[_id], "Professor not found");
        ProfessorInfo storage prof = professors[_id];

        // Remove from address mapping
        delete addressToId[prof.professorAddress];

        // Update indexes - use swap and pop for gas efficiency
        uint256 lastIndex = allProfessors.length - 1;
        uint256 index = _findIndex(_id);

        if(index != lastIndex) {
            uint256 lastId = allProfessors[lastIndex];
            allProfessors[index] = lastId;
        }

        allProfessors.pop();
        isActive[_id] = false;
        prof.active = false;

        emit ProfessorRemoved(_id);
    }

    /**
     * @notice Update professor details
     * @param _id Professor ID
     * @param _name New name (empty string to keep current)
     * @param _department New department (empty string to keep current)
     */
    function updateProfessor(
        uint256 _id,
        string memory _name,
        string memory _department
    ) external {
        require(isActive[_id], "Professor not found");

        if (bytes(_name).length > 0) {
            professors[_id].name = _name;
        }

        if (bytes(_department).length > 0) {
            professors[_id].department = _department;
        }

        emit ProfessorUpdated(_id);
    }

    /**
     * @notice Get all active professor IDs
     * @return Array of active professor IDs
     */
    function getActiveProfessors() external view returns (uint256[] memory) {
        return allProfessors;
    }

    /**
     * @notice Get professor information by ID
     * @param _id Professor ID
     * @return Professor information
     */
    function getProfessor(uint256 _id) external view returns (ProfessorInfo memory) {
        require(isActive[_id], "Professor not found");
        return professors[_id];
    }

    /**
     * @notice Look up professor ID from address
     * @param _addr Professor's address
     * @return Professor ID
     */
    function getProfessorIdByAddress(address _addr) external view returns (uint256) {
        uint256 id = addressToId[_addr];
        require(id != 0 && isActive[id], "Professor not found");
        return id;
    }

    /// @dev Helper to find professor index in array
    function _findIndex(uint256 _id) private view returns (uint256) {
        for(uint256 i = 0; i < allProfessors.length; i++) {
            if(allProfessors[i] == _id) return i;
        }
        revert("Professor not found");
    }
}