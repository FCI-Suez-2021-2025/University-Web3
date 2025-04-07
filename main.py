from datasource.university_datasource import UniversityDataSource


university_datasource = UniversityDataSource()

def print_student(student_id):
    try:
        student = university_datasource.get_student(student_id)
        print(f"\nStudent ID: {student[0]}")
        print(f"Name: {student[1]}")
        print(f"Major: {student[2]}")
        print(f"Year: {student[3]}")
        print(f"Supervisor Address: {student[4]}")
    except Exception as e:
        print(f"Error retrieving student: {str(e)}")

def print_professor(professor_id):
    try:
        prof = university_datasource.get_professor(professor_id)
        print(f"\nProfessor ID: {prof[0]}")
        print(f"Name: {prof[1]}")
        print(f"Department: {prof[2]}")
        print(f"Address: {prof[3]}")
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
        print(f"   Taught by: {enrollment['professor_name']} ({enrollment['department']})")


# Example 1: Add Professors
# print("\n=== Adding Professors ===")
# university_datasource.add_professor("Dr. Smith", "Computer Science")
# university_datasource.add_professor("Dr. Johnson", "Mathematics")
# print("Professors added!")

# Example 2: Add a Student
# print("\n=== Adding a Student ===")
# university_datasource.add_student("Alice", "Computer Science", 2025, 1)
# print("Student Alice added!")
# print_student(1)

# Example 3: Create Courses
# print("\n=== Creating Courses ===")
# university_datasource.create_course("CS101", "Introduction to Programming", 1)
# university_datasource.create_course("MATH201", "Linear Algebra", 2)
# print("Courses created: CS101, MATH201")

# Example 4: Enroll Student in Courses
# print("\n=== Enrolling Student ===")
# university_datasource.enroll_student_in_course(1, "CS101")
# university_datasource.enroll_student_in_course(1, "MATH201")
# print_enrollments(1)

# Example 5: Update Student Information
# print("\n=== Updating Student ===")
# university_datasource.update_student(
#     student_id=1,
#     name="Alice Updated",
#     major="Data Science",
#     year=2026,
#     professor_id=2
# )
# print("Student information updated!")
# print_student(1)

# Example 6: Reassign Course
# print("\n=== Reassigning Course ===")
# university_datasource.reassign_course("CS101", 2)
# print("CS101 reassigned to Professor 2")

# Example 7: Remove Course from Student (Updated)
# print("\n=== Removing Course Enrollment ===")
# try:
#     university_datasource.remove_course_from_student(1, "MATH201")
#     print("Student removed from MATH201")
# except Exception as e:
#     print(f"Error removing course: {str(e)}")

# Example 8: Delete Course (Now Safe)
# print("\n=== Deleting Course ===")
# try:
#     university_datasource.delete_course("MATH201")
#     print("Course MATH201 deleted")
# except Exception as e:
#     print(f"Error deleting course: {str(e)}")

# Example 9: Clear All Courses for Student
# print("\n=== Clearing All Courses ===")
# university_datasource.clear_all_courses_for_student(1)
# print("All courses cleared for student")

# Example 10: Delete Professor
# print("\n=== Deleting Professor ===")
# try:
#     university_datasource.delete_professor(1)
#     print("Professor 1 deleted")
# except Exception as e:
#     print(f"Error deleting professor: {str(e)}")