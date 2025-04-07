from utils.contract_finder import get_contract
from utils.contract_type import ContractType


class UniversityDataSource:
    def __init__(self):
        self.university_contract = get_contract(ContractType.UNIVERSITY)

    # Student operations
    def add_student(self, name, major, year, professor_id):
        self.university_contract.functions.addStudent(name, major, year, professor_id).transact()

    def get_student(self, student_id):
        return self.university_contract.functions.getStudent(student_id).call()

    def update_student(self, student_id, name, major, year, professor_id):
        self.university_contract.functions.updateStudent(
            student_id, 
            name or "", 
            major or "", 
            year or 0, 
            professor_id or 0
        ).transact()

    def delete_student(self, student_id):
        self.university_contract.functions.deleteStudent(student_id).transact()

    # Professor operations
    def add_professor(self, name, department):
        self.university_contract.functions.addProfessor(name, department).transact()

    def get_professor(self, professor_id):
        return self.university_contract.functions.getProfessor(professor_id).call()

    def delete_professor(self, professor_id):
        self.university_contract.functions.deleteProfessor(professor_id).transact()

    # Course operations
    def create_course(self, course_id, name, professor_id):
        self.university_contract.functions.createCourse(course_id, name, professor_id).transact()

    def reassign_course(self, course_id, new_professor_id):
        self.university_contract.functions.reassignCourse(course_id, new_professor_id).transact()

    def delete_course(self, course_id):
        self.university_contract.functions.deleteCourse(course_id).transact()

    # Enrollment operations
    def enroll_student_in_course(self, student_id, course_id):
        self.university_contract.functions.enrollStudentInCourse(student_id, course_id).transact()

    def remove_course_from_student(self, student_id, course_id):
        self.university_contract.functions.removeCourseFromStudent(
            student_id,
            course_id
        ).transact()

    def clear_all_courses_for_student(self, student_id):
        self.university_contract.functions.clearAllCoursesForStudent(student_id).transact()