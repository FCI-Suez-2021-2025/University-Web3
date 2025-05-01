from datasource.university_datasource import UniversityDataSource
from utils.project_components import get_web3, get_config
from web3.exceptions import ContractLogicError

w3 = get_web3()
deployer_address = get_config()["deployer_address"]

university_datasource = UniversityDataSource(
    account_address=deployer_address,
    admin_address=deployer_address,
    web3_provider=w3
)

def print_student(student_id):
    try:
        student = university_datasource.get_student(student_id)
        print(f"\nStudent ID: {student['id']}")
        print(f"Name: {student['name']}")
        print(f"Major: {student['major']}")
        print(f"Year: {student['year']}")
        print(f"Academic Supervisor: {student['academicSupervisor']}")
        print(f"Active: {'Yes' if student['active'] else 'No'}")
    except Exception as e:
        print(f"Error retrieving student: {str(e)}")

def print_professor(professor_id):
    try:
        prof = university_datasource.get_professor(professor_id)
        print(f"\nProfessor ID: {prof['id']}")
        print(f"Name: {prof['name']}")
        print(f"Department: {prof['department']}")
        print(f"Address: {prof['professorAddress']}")
        print(f"Active: {'Yes' if prof['active'] else 'No'}")
    except Exception as e:
        print(f"Error retrieving professor: {str(e)}")

def print_enrollments(student_id):
    try:
        enrollments = university_datasource.get_student_enrollments(student_id)
        if not enrollments:
            print("No enrollments found")
            return

        print(f"\nEnrollments for Student {student_id}:")
        for idx, enrollment in enumerate(enrollments, 1):
            print(f"{idx}. Course: {enrollment['course_id']}")
            print(f"   Mark: {enrollment['mark']}")
            print(f"   Status: {'Active' if enrollment['active'] else 'Inactive'}")
    except Exception as e:
        print(f"Error retrieving enrollments: {str(e)}")

def print_course_enrollments(course_id):
    try:
        enrollments = university_datasource.get_course_enrollments(course_id)
        if not enrollments:
            print("No enrollments found")
            return

        print(f"\nEnrollments for Course {course_id}:")
        for idx, enrollment in enumerate(enrollments, 1):
            print(f"{idx}. Student: {enrollment['student_id']} ({enrollment['student_name']})")
            print(f"   Mark: {enrollment['mark']}")
            print(f"   Status: {'Active' if enrollment['active'] else 'Inactive'}")
    except Exception as e:
        print(f"Error retrieving course enrollments: {str(e)}")

def print_course(course_id):
    try:
        course = university_datasource.get_course(course_id)
        print(f"\nCourse ID: {course['id']}")
        print(f"Name: {course['name']}")
        print(f"Professor ID: {course['professorId']}")
        print(f"Active: {'Yes' if course['active'] else 'No'}")
    except Exception as e:
        print(f"Error retrieving course: {str(e)}")

def wait_for_tx(tx_hash):
    """Wait for transaction to be mined and print result"""
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
    status = "Success" if receipt["status"] == 1 else "Failed"
    print(f"Transaction {status}: {tx_hash.hex()}")
    return receipt

# Main execution
if __name__ == "__main__":
    # First ensure we're connected to the network
    if not w3.is_connected():
        print("Failed to connect to Ethereum provider!")
        exit(1)

    print("\n=== Connected to Ethereum network ===")
    print(f"Current block number: {w3.eth.block_number}")

    # Example 1: Initialize System
    print("\n=== Initializing System ===")
    try:
        # Add initial professors
        tx_hash = university_datasource.add_professor("Dr. Smith", "Computer Science")
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.add_professor("Dr. Johnson", "Mathematics")
        wait_for_tx(tx_hash)

        # Add initial students
        tx_hash = university_datasource.add_student("Alice", "Computer Science", 2025, 1)
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.add_student("Bob", "Mathematics", 2026, 2)
        wait_for_tx(tx_hash)

        # Create courses
        tx_hash = university_datasource.create_course("CS101", "Introduction to Programming", 1)
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.create_course("MATH201", "Linear Algebra", 2)
        wait_for_tx(tx_hash)

        print("System initialized with 2 professors, 2 students, and 2 courses")
    except ContractLogicError as e:
        print(f"Initialization error: {e.message}")
    except Exception as e:
        print(f"Error initializing system: {str(e)}")

    # Example 2: Enrollment Operations
    print("\n=== Enrollment Operations ===")
    try:
        # Enroll students
        tx_hash = university_datasource.enroll_student_in_course(1, "CS101")
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.enroll_student_in_course(1, "MATH201")
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.enroll_student_in_course(2, "MATH201")
        wait_for_tx(tx_hash)

        # Print enrollment details
        print_enrollments(1)
        print_course_enrollments("MATH201")

        # Update marks
        tx_hash = university_datasource.update_student_mark(1, "CS101", 85)
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.update_student_mark(1, "MATH201", 78)
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.update_student_mark(2, "MATH201", 92)
        wait_for_tx(tx_hash)

        print("\nAfter updating marks:")
        print_enrollments(1)
        print_course_enrollments("MATH201")

        # Unenroll a student
        tx_hash = university_datasource.remove_course_from_student(1, "MATH201")
        wait_for_tx(tx_hash)

        print("\nAfter unenrolling Alice from MATH201:")
        print_enrollments(1)
        print_course_enrollments("MATH201")
    except ContractLogicError as e:
        print(f"Enrollment error: {e.message}")
    except Exception as e:
        print(f"Error during enrollment operations: {str(e)}")

    # Example 3: Batch Operations
    print("\n=== Batch Operations ===")
    try:
        # Batch enroll students
        tx_hash = university_datasource.batch_enroll_students([1, 2], "CS101")
        wait_for_tx(tx_hash)

        # Batch update marks
        tx_hash = university_datasource.update_student_mark(1, "CS101", 88)
        wait_for_tx(tx_hash)
        tx_hash = university_datasource.update_student_mark(2, "CS101", 95)
        wait_for_tx(tx_hash)

        print("\nAfter batch operations:")
        print_enrollments(1)
        print_enrollments(2)
        print_course_enrollments("CS101")
    except Exception as e:
        print(f"Error during batch operations: {str(e)}")

    # Example 4: Comprehensive System Check
    print("\n=== System Status ===")
    try:
        print("\nProfessors:")
        for prof_id in university_datasource.get_all_professors():
            print_professor(prof_id)

        print("\nStudents:")
        for student_id in university_datasource.get_all_students():
            print_student(student_id)

        print("\nCourses:")
        for course_id in university_datasource.get_all_courses():
            print_course(course_id)

        print("\nAll Enrollments:")
        for student_id in university_datasource.get_all_students():
            print_enrollments(student_id)
    except Exception as e:
        print(f"Error during system check: {str(e)}")

    print("\n=== Demo Complete ===")