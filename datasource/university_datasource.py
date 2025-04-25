from web3 import Web3
from typing import Optional, List, Dict, Union, Any, Tuple
from utils.contract_finder import get_contract
from utils.contract_type import ContractType
import asyncio


class UniversityDataSource:
    """
    Enhanced wrapper for interacting with the University smart contract.
    Provides comprehensive access to University contract functions with
    improved error handling, transaction management, and additional features.
    """

    def __init__(self, account_address: Optional[str] = None, admin_address: Optional[str] = None, web3_provider=None):
        """
        Initialize the University data source.

        Args:
            account_address: The address to use for transactions (optional)
            admin_address: The admin address for admin-only functions (optional)
            web3_provider: Custom Web3 provider instance (optional)
        """
        self.web3 = web3_provider or Web3()
        self.university_contract = get_contract(ContractType.UNIVERSITY)
        self.account_address = account_address
        self.admin_address = admin_address

        # Store contract references for direct access if needed
        self.student_contract_address = self.university_contract.functions.studentContract().call()
        self.professor_contract_address = self.university_contract.functions.professorContract().call()
        self.course_contract_address = self.university_contract.functions.courseContract().call()

        # Cache contract ABI for event listeners
        self.contract_events = self.university_contract.events

    def set_account(self, account_address: str) -> None:
        """Set the account address to use for transactions"""
        self.account_address = account_address

    def set_admin(self, admin_address: str) -> None:
        """Set the admin address for admin-only functions"""
        self.admin_address = admin_address

    def _get_transaction_params(self, gas: Optional[int] = None,
                                gas_price: Optional[int] = None,
                                use_admin: bool = False) -> Dict[str, Any]:
        """
        Build transaction parameters dictionary

        Args:
            gas: Custom gas limit
            gas_price: Custom gas price
            use_admin: Use admin address instead of account address

        Returns:
            Dictionary with transaction parameters
        """
        transaction_params = {}

        # Use the appropriate address
        address = self.admin_address if use_admin else self.account_address
        if address:
            transaction_params['from'] = address

        # Add gas configuration if provided
        if gas:
            transaction_params['gas'] = gas
        if gas_price:
            transaction_params['gasPrice'] = gas_price

        return transaction_params

    def _handle_transaction(self, function_call, transaction_params: Dict[str, Any],
                            wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Execute a transaction and handle results/errors consistently

        Args:
            function_call: Contract function call object
            transaction_params: Transaction parameters
            wait_for_receipt: Whether to wait for transaction receipt

        Returns:
            Transaction hash or receipt
        """
        try:
            tx_hash = function_call.transact(transaction_params)

            if wait_for_receipt:
                receipt = self.web3.eth.wait_for_transaction_receipt(tx_hash)
                if receipt['status'] == 0:  # Transaction failed
                    raise Exception(f"Transaction failed: {receipt}")
                return receipt
            return tx_hash

        except Exception as e:
            error_msg = f"Transaction failed: {str(e)}"
            print(error_msg)
            raise type(e)(error_msg) from e

    # ==================== STUDENT OPERATIONS ====================

    def add_student(self, name: str, major: str, year: int, professor_id: int,
                    gas: Optional[int] = None, gas_price: Optional[int] = None,
                    wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Add a new student to the university

        Returns:
            Transaction hash or receipt
        """
        if not name or not major or year <= 0 or professor_id <= 0:
            raise ValueError("Invalid student data")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.addStudent(name, major, year, professor_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def get_student(self, student_id: int) -> Dict[str, Any]:
        """
        Get student information by ID

        Returns:
            Student information dictionary
        """
        if student_id <= 0:
            raise ValueError("Student ID must be positive")

        try:
            student_data = self.university_contract.functions.getStudent(student_id).call()
            # Convert tuple to dictionary for easier use
            return {
                "id": student_data[0],
                "name": student_data[1],
                "major": student_data[2],
                "year": student_data[3],
                "academicSupervisor": student_data[4],
                "active": student_data[5]
            }
        except Exception as e:
            print(f"Error getting student {student_id}: {str(e)}")
            raise

    def get_student_enrollments(self, student_id: int) -> List[Dict[str, str]]:
        """
        Get all courses a student is enrolled in

        Returns:
            List of enrollment information dictionaries
        """
        try:
            course_ids, course_names, prof_names, departments = self.university_contract.functions.getStudentEnrollments(
                student_id).call()
            return [
                {
                    "course_id": cid,
                    "course_name": cname,
                    "professor": pname,
                    "department": dept
                }
                for cid, cname, pname, dept in zip(course_ids, course_names, prof_names, departments)
            ]
        except Exception as e:
            print(f"Error getting enrollments for student {student_id}: {str(e)}")
            return []

    def update_student(self, student_id: int, name: Optional[str] = None,
                       major: Optional[str] = None, year: Optional[int] = None,
                       professor_id: Optional[int] = None, gas: Optional[int] = None,
                       gas_price: Optional[int] = None,
                       wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Update student information

        Returns:
            Transaction hash or receipt
        """
        if student_id <= 0:
            raise ValueError("Student ID must be positive")

        # Sanitize inputs
        name = name or ""
        major = major or ""
        year = max(0, int(year or 0))
        professor_id = max(0, int(professor_id or 0))

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.updateStudent(
            student_id, name, major, year, professor_id
        )
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def delete_student(self, student_id: int, gas: Optional[int] = None,
                       gas_price: Optional[int] = None,
                       wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Delete a student

        Returns:
            Transaction hash or receipt
        """
        if student_id <= 0:
            raise ValueError("Student ID must be positive")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.deleteStudent(student_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    async def async_get_student(self, student_id: int) -> Dict[str, Any]:
        """Asynchronous version of get_student"""
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, self.get_student, student_id)

    def get_all_students(self, offset: int = 0, limit: int = 100) -> List[int]:
        """
        Get all student IDs with pagination

        Args:
            offset: Starting position in the list
            limit: Maximum number of results to return

        Returns:
            List of student IDs
        """
        try:
            all_students = self.university_contract.functions.getAllStudents().call()
            # Apply pagination
            return all_students[offset:offset + limit]
        except Exception as e:
            print(f"Error getting all students: {str(e)}")
            return []

    # ==================== PROFESSOR OPERATIONS ====================

    def add_professor(self, name: str, department: str, gas: Optional[int] = None,
                      gas_price: Optional[int] = None,
                      wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Add a new professor

        Returns:
            Transaction hash or receipt
        """
        if not name or not department:
            raise ValueError("Name and department are required")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.addProfessor(name, department)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def get_professor(self, professor_id: int) -> Dict[str, Any]:
        """
        Get professor information by ID

        Returns:
            Professor information dictionary
        """
        if professor_id <= 0:
            raise ValueError("Professor ID must be positive")

        try:
            prof_data = self.university_contract.functions.getProfessor(professor_id).call()
            # Convert tuple to dictionary
            return {
                "id": prof_data[0],
                "professorAddress": prof_data[1],
                "name": prof_data[2],
                "department": prof_data[3],
                "active": prof_data[4]
            }
        except Exception as e:
            print(f"Error getting professor {professor_id}: {str(e)}")
            raise

    def update_professor(self, professor_id: int, name: Optional[str] = None,
                         department: Optional[str] = None, gas: Optional[int] = None,
                         gas_price: Optional[int] = None,
                         wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Update professor information

        Returns:
            Transaction hash or receipt
        """
        if professor_id <= 0:
            raise ValueError("Professor ID must be positive")

        # Sanitize inputs
        name = name or ""
        department = department or ""

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.updateProfessor(
            professor_id, name, department
        )
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def delete_professor(self, professor_id: int, gas: Optional[int] = None,
                         gas_price: Optional[int] = None,
                         wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Delete a professor

        Returns:
            Transaction hash or receipt
        """
        if professor_id <= 0:
            raise ValueError("Professor ID must be positive")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.deleteProfessor(professor_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def get_all_professors(self, offset: int = 0, limit: int = 100) -> List[int]:
        """
        Get all professor IDs with pagination

        Returns:
            List of professor IDs
        """
        try:
            all_professors = self.university_contract.functions.getAllProfessors().call()
            # Apply pagination
            return all_professors[offset:offset + limit]
        except Exception as e:
            print(f"Error getting all professors: {str(e)}")
            return []

    # ==================== COURSE OPERATIONS ====================

    def create_course(self, course_id: str, name: str, professor_id: int,
                      gas: Optional[int] = None, gas_price: Optional[int] = None,
                      wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Create a new course

        Returns:
            Transaction hash or receipt
        """
        if not course_id or not name or professor_id <= 0 or course_id <= 0:
            raise ValueError("Invalid course data")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.createCourse(course_id, name, professor_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def update_course(self, course_id: str, name: str, gas: Optional[int] = None,
                      gas_price: Optional[int] = None,
                      wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Update course information

        Returns:
            Transaction hash or receipt
        """
        if not course_id or course_id <= 0:
            raise ValueError("Course ID is required")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.updateCourse(course_id, name)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def reassign_course(self, course_id: str, new_professor_id: int,
                        gas: Optional[int] = None, gas_price: Optional[int] = None,
                        wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Reassign a course to a new professor

        Returns:
            Transaction hash or receipt
        """
        if not course_id or new_professor_id <= 0 or course_id <= 0:
            raise ValueError("Invalid course or professor data")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.reassignCourse(course_id, new_professor_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def delete_course(self, course_id: str, gas: Optional[int] = None,
                      gas_price: Optional[int] = None,
                      wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Delete a course

        Returns:
            Transaction hash or receipt
        """
        if not course_id or course_id <= 0:
            raise ValueError("Invalid Course ID")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.deleteCourse(course_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def get_course(self, course_id: str) -> Dict[str, Any]:
        """
        Get course information by ID

        Returns:
            Course information dictionary
        """
        if not course_id or course_id <= 0:
            raise ValueError("Invalid Course ID")

        try:
            # This requires direct access to the Course contract
            course_contract = get_contract(ContractType.COURSE)
            course_data = course_contract.functions.getCourse(course_id).call()

            # Convert tuple to dictionary
            return {
                "id": course_data[0],
                "name": course_data[1],
                "professorId": course_data[2],
                "studentCount": course_data[3],
                "active": course_data[4]
            }
        except Exception as e:
            print(f"Error getting course {course_id}: {str(e)}")
            raise

    def get_all_courses(self, offset: int = 0, limit: int = 100) -> List[str]:
        """
        Get all course IDs with pagination

        Returns:
            List of course IDs
        """
        try:
            all_courses = self.university_contract.functions.getAllCourses().call()
            # Apply pagination
            return all_courses[offset:offset + limit]
        except Exception as e:
            print(f"Error getting all courses: {str(e)}")
            return []

    def get_courses_by_professor(self, professor_id: int) -> List[Dict[str, Any]]:
        """
        Get all courses taught by a professor

        Returns:
            List of course information dictionaries
        """
        try:
            # This requires direct access to the Course contract
            course_contract = get_contract(ContractType.COURSE)
            courses_data = course_contract.functions.getCoursesByProfessor(professor_id).call()

            # Convert tuples to dictionaries
            return [
                {
                    "id": course[0],
                    "name": course[1],
                    "professorId": course[2],
                    "studentCount": course[3],
                    "active": course[4]
                }
                for course in courses_data
            ]
        except Exception as e:
            print(f"Error getting courses for professor {professor_id}: {str(e)}")
            return []

    # ==================== ENROLLMENT OPERATIONS ====================

    def enroll_student_in_course(self, student_id: int, course_id: str,
                                 gas: Optional[int] = None, gas_price: Optional[int] = None,
                                 wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Enroll a student in a course

        Returns:
            Transaction hash or receipt
        """
        if student_id <= 0 or not course_id or course_id <= 0 or not student_id:
            raise ValueError("Valid student ID and course ID are required")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.enrollStudentInCourse(student_id, course_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def batch_enroll_students(self, student_ids: List[int], course_id: str,
                              gas: Optional[int] = None, gas_price: Optional[int] = None,
                              wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Enroll multiple students in a course at once

        Returns:
            Transaction hash or receipt
        """
        if not student_ids or not course_id or course_id <= 0 or student_ids <= 0:
            raise ValueError("Student IDs list and course ID are required")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.batchEnroll(student_ids, course_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def remove_course_from_student(self, student_id: int, course_id: str,
                                   gas: Optional[int] = None, gas_price: Optional[int] = None,
                                   wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Remove a student from a course

        Returns:
            Transaction hash or receipt
        """
        if student_id <= 0 or not course_id or not student_id or course_id <= 0:
            raise ValueError("Valid student ID and course ID are required")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.removeCourseFromStudent(student_id, course_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def clear_all_courses_for_student(self, student_id: int, gas: Optional[int] = None,
                                      gas_price: Optional[int] = None,
                                      wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Unenroll a student from all courses

        Returns:
            Transaction hash or receipt
        """
        if student_id <= 0 or not student_id:
            raise ValueError("Invalid student ID")

        tx_params = self._get_transaction_params(gas, gas_price)
        function_call = self.university_contract.functions.clearAllCoursesForStudent(student_id)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def get_enrolled_students(self, course_id: str) -> List[int]:
        """
        Get all students enrolled in a course

        Returns:
            List of student IDs
        """
        try:
            # This requires direct access to the Course contract
            course_contract = get_contract(ContractType.COURSE)
            return course_contract.functions.getEnrolledStudents(course_id).call()
        except Exception as e:
            print(f"Error getting enrolled students for course {course_id}: {str(e)}")
            return []

    # ==================== ADMIN OPERATIONS ====================

    def authorize_instructor(self, instructor_address: str, gas: Optional[int] = None,
                             gas_price: Optional[int] = None,
                             wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Authorize an instructor to manage courses (admin only)

        Returns:
            Transaction hash or receipt
        """
        if not instructor_address:
            raise ValueError("Instructor address is required")

        tx_params = self._get_transaction_params(gas, gas_price, use_admin=True)
        function_call = self.university_contract.functions.authorizeInstructor(instructor_address)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def deauthorize_instructor(self, instructor_address: str, gas: Optional[int] = None,
                               gas_price: Optional[int] = None,
                               wait_for_receipt: bool = False) -> Union[str, Dict[str, Any]]:
        """
        Remove instructor authorization (admin only)

        Returns:
            Transaction hash or receipt
        """
        if not instructor_address:
            raise ValueError("Instructor address is required")

        tx_params = self._get_transaction_params(gas, gas_price, use_admin=True)
        function_call = self.university_contract.functions.deauthorizeInstructor(instructor_address)
        return self._handle_transaction(function_call, tx_params, wait_for_receipt)

    def is_authorized_instructor(self, address: str) -> bool:
        """
        Check if an address is an authorized instructor

        Returns:
            Boolean indicating authorization status
        """
        try:
            return self.university_contract.functions.authorizedInstructors(address).call()
        except Exception as e:
            print(f"Error checking instructor authorization: {str(e)}")
            return False

    # ==================== EVENT MANAGEMENT ====================

    def subscribe_to_events(self, event_name: str, from_block='latest',
                            callback=None, filter_params=None) -> Any:
        """
        Subscribe to contract events

        Args:
            event_name: Name of the event to subscribe to
            from_block: Starting block (default is 'latest')
            callback: Function to call when event is triggered
            filter_params: Parameters to filter events

        Returns:
            Event filter object
        """
        try:
            if not hasattr(self.contract_events, event_name):
                raise ValueError(f"Event {event_name} does not exist")

            event = getattr(self.contract_events, event_name)
            filter_params = filter_params or {}
            event_filter = event.createFilter(fromBlock=from_block, **filter_params)

            if callback:
                # Start a thread to listen for events
                import threading

                def event_loop():
                    try:
                        while True:
                            for event in event_filter.get_new_entries():
                                callback(event)
                            # Sleep to avoid hammering the node
                            import time
                            time.sleep(2)
                    except Exception as e:
                        print(f"Event listener error: {str(e)}")

                thread = threading.Thread(target=event_loop, daemon=True)
                thread.start()
                return thread

            return event_filter

        except Exception as e:
            print(f"Error subscribing to events: {str(e)}")
            raise

    def get_past_events(self, event_name: str, from_block=0, to_block='latest',
                        filter_params=None) -> List[Dict[str, Any]]:
        """
        Get past events from the contract

        Args:
            event_name: Name of the event
            from_block: Starting block
            to_block: Ending block
            filter_params: Parameters to filter events

        Returns:
            List of events
        """
        try:
            if not hasattr(self.contract_events, event_name):
                raise ValueError(f"Event {event_name} does not exist")

            event = getattr(self.contract_events, event_name)
            filter_params = filter_params or {}
            return event.getLogs(fromBlock=from_block, toBlock=to_block, **filter_params)

        except Exception as e:
            print(f"Error getting past events: {str(e)}")
            return []