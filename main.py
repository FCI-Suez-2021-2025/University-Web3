from datasource.university_datasource import UniversityDataSource
from utils.project_components import get_web3, get_config

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
    enrollments = university_datasource.get_student_enrollments(student_id)
    if not enrollments:
        print("No enrollments found")
        return

    print(f"\nEnrollments for Student {student_id}:")
    for idx, enrollment in enumerate(enrollments, 1):
        print(f"{idx}. Course: {enrollment['course_id']} ({enrollment['course_name']})")
        print(f"   Taught by: {enrollment['professor']} ({enrollment['department']})")


def print_course(course_id):
    try:
        course = university_datasource.get_course(course_id)
        print(f"\nCourse ID: {course['id']}")
        print(f"Name: {course['name']}")
        print(f"Professor ID: {course['professorId']}")
        print(f"Student Count: {course['studentCount']}")
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

    # Example 1: Authorize an instructor (admin operation)
    print("\n=== Authorizing Instructor ===")
    try:
        tx_hash = university_datasource.authorize_instructor(deployer_address)
        wait_for_tx(tx_hash)
        is_authorized = university_datasource.is_authorized_instructor(deployer_address)
        print(f"Authorization status: {is_authorized}")
    except Exception as e:
        print(f"Error authorizing instructor: {str(e)}")

    # Example 2: Add Professors
    print("\n=== Adding Professors ===")
    try:
        tx_hash = university_datasource.add_professor("Dr. Smith", "Computer Science")
        wait_for_tx(tx_hash)
        print("Professor 1 added: Dr. Smith (Computer Science)")

        tx_hash = university_datasource.add_professor("Dr. Johnson", "Mathematics")
        wait_for_tx(tx_hash)
        print("Professor 2 added: Dr. Johnson (Mathematics)")

        # Display added professors
        print_professor(1)
        print_professor(2)
    except Exception as e:
        print(f"Error adding professors: {str(e)}")

    # Example 3: Add Students
    print("\n=== Adding Students ===")
    try:
        tx_hash = university_datasource.add_student("Alice", "Computer Science", 2025, 1)
        wait_for_tx(tx_hash)
        print("Student 1 added: Alice (Computer Science)")

        tx_hash = university_datasource.add_student("Bob", "Mathematics", 2026, 2)
        wait_for_tx(tx_hash)
        print("Student 2 added: Bob (Mathematics)")

        # Display added students
        print_student(1)
        print_student(2)
    except Exception as e:
        print(f"Error adding students: {str(e)}")

    # Example 4: Create Courses
    print("\n=== Creating Courses ===")
    try:
        tx_hash = university_datasource.create_course("CS101", "Introduction to Programming", 1)
        wait_for_tx(tx_hash)
        print("Course created: CS101 (Introduction to Programming)")

        tx_hash = university_datasource.create_course("MATH201", "Linear Algebra", 2)
        wait_for_tx(tx_hash)
        print("Course created: MATH201 (Linear Algebra)")

        # Display created courses
        print_course("CS101")
        print_course("MATH201")
    except Exception as e:
        print(f"Error creating courses: {str(e)}")

    # Example 5: Enroll Students in Courses
    print("\n=== Enrolling Students in Courses ===")
    try:
        # Enroll Alice in both courses
        tx_hash = university_datasource.enroll_student_in_course(1, "CS101")
        wait_for_tx(tx_hash)
        print("Alice enrolled in CS101")

        tx_hash = university_datasource.enroll_student_in_course(1, "MATH201")
        wait_for_tx(tx_hash)
        print("Alice enrolled in MATH201")

        # Enroll Bob in Math only
        tx_hash = university_datasource.enroll_student_in_course(2, "MATH201")
        wait_for_tx(tx_hash)
        print("Bob enrolled in MATH201")

        # Display enrollments
        print_enrollments(1)
        print_enrollments(2)

        # Display updated course info (student count should have increased)
        print_course("CS101")
        print_course("MATH201")
    except Exception as e:
        print(f"Error enrolling students: {str(e)}")

    # Example 6: Update Student Information
    print("\n=== Updating Student Information ===")
    try:
        tx_hash = university_datasource.update_student(
            student_id=1,
            name="Alice Smith",
            major="Data Science",
            year=2026,
            professor_id=2  # Change supervisor to Dr. Johnson
        )
        wait_for_tx(tx_hash)
        print("Student information updated!")
        print_student(1)
    except Exception as e:
        print(f"Error updating student: {str(e)}")

    # Example 7: Reassign Course to Different Professor
    print("\n=== Reassigning Course ===")
    try:
        tx_hash = university_datasource.reassign_course("CS101", 2)
        wait_for_tx(tx_hash)
        print("CS101 reassigned to Professor 2 (Dr. Johnson)")
        print_course("CS101")

        # Check enrollments to see professor change
        print_enrollments(1)
    except Exception as e:
        print(f"Error reassigning course: {str(e)}")

    # Example 8: Remove Course from Student
    print("\n=== Removing Course Enrollment ===")
    try:
        tx_hash = university_datasource.remove_course_from_student(1, "MATH201")
        wait_for_tx(tx_hash)
        print("Alice removed from MATH201")
        print_enrollments(1)

        # Check course student count
        print_course("MATH201")
    except Exception as e:
        print(f"Error removing course enrollment: {str(e)}")

    # Example 9: Batch Enrollment
    print("\n=== Batch Enrolling Students ===")
    try:
        tx_hash = university_datasource.batch_enroll_students([1, 2], "CS101")
        wait_for_tx(tx_hash)
        print("Alice and Bob enrolled in CS101")
        print_enrollments(1)
        print_enrollments(2)
    except Exception as e:
        print(f"Error in batch enrollment: {str(e)}")

    # Example 10: Get All Professors and Students
    print("\n=== List All Professors ===")
    try:
        professor_ids = university_datasource.get_all_professors()
        print(f"Found {len(professor_ids)} professors:")
        for prof_id in professor_ids:
            prof = university_datasource.get_professor(prof_id)
            print(f"- {prof['id']}: {prof['name']} ({prof['department']})")
    except Exception as e:
        print(f"Error listing professors: {str(e)}")

    print("\n=== List All Students ===")
    try:
        student_ids = university_datasource.get_all_students()
        print(f"Found {len(student_ids)} students:")
        for student_id in student_ids:
            student = university_datasource.get_student(student_id)
            print(f"- {student['id']}: {student['name']} ({student['major']})")
    except Exception as e:
        print(f"Error listing students: {str(e)}")

    # Example 11: Get Courses by Professor
    print("\n=== List Courses by Professor ===")
    try:
        courses = university_datasource.get_courses_by_professor(2)
        print(f"Professor 2 (Dr. Johnson) teaches {len(courses)} courses:")
        for course in courses:
            print(f"- {course['id']}: {course['name']} (Students: {course['studentCount']})")
    except Exception as e:
        print(f"Error listing courses by professor: {str(e)}")

    # Example 12: Get Enrolled Students in Course
    print("\n=== List Students in Course ===")
    try:
        student_ids = university_datasource.get_enrolled_students("CS101")
        print(f"Course CS101 has {len(student_ids)} enrolled students:")
        for student_id in student_ids:
            student = university_datasource.get_student(student_id)
            print(f"- {student['id']}: {student['name']}")
    except Exception as e:
        print(f"Error listing students in course: {str(e)}")

    # Example 13: Clear All Courses for Student
    print("\n=== Clearing All Courses for Student ===")
    try:
        tx_hash = university_datasource.clear_all_courses_for_student(1)
        wait_for_tx(tx_hash)
        print("All courses cleared for Alice")
        print_enrollments(1)
    except Exception as e:
        print(f"Error clearing courses: {str(e)}")

    # Example 14: Update Professor
    print("\n=== Updating Professor Information ===")
    try:
        tx_hash = university_datasource.update_professor(
            professor_id=1,
            name="Dr. Jane Smith",
            department="Computer Science & AI"
        )
        wait_for_tx(tx_hash)
        print("Professor information updated!")
        print_professor(1)
    except Exception as e:
        print(f"Error updating professor: {str(e)}")

    # Example 15: Events Subscription (uncomment to use)
    """
    print("\n=== Setting Up Event Listener ===")
    def enrollment_event_handler(event):
        print(f"Enrollment Event: Student {event['args']['studentId']} enrolled in {event['args']['courseId']}")

    # Subscribe to enrollment events
    university_datasource.subscribe_to_events("StudentEnrolled", callback=enrollment_event_handler)
    print("Event listener set up for StudentEnrolled events")

    # Make an enrollment to trigger the event
    tx_hash = university_datasource.enroll_student_in_course(2, "CS101")
    wait_for_tx(tx_hash)

    # Keep the script running to receive events
    print("Waiting for events... (Ctrl+C to stop)")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("Stopped event listening")
    """

    print("\n=== Demo Complete ===")