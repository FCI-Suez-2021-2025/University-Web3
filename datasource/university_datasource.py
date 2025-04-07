from utils.contract_finder import get_contract
from utils.contract_type import ContractType


class UniversityDataSource:
    def __init__(self):
        self.university_contract = get_contract(ContractType.UNIVERSITY)

    def add_student(self, name, major, year, professor_id):
        self.university_contract.functions.addStudent(name, major, year, professor_id).transact()

    def get_student(self, student_id):
        return self.university_contract.functions.getStudent(student_id).call()

    def update_student(self, student_id, name, major, year, professor_id):
        self.university_contract.functions.updateStudent(student_id, name, major, year, professor_id).transact()

    def delete_student(self, student_id):
        self.university_contract.functions.deleteStudent(student_id).transact()

    def add_professor(self, name, department):
        self.university_contract.functions.addProfessor(name, department).transact()

    def get_professor(self, professor_id):
        return self.university_contract.functions.getProfessor(professor_id).call()

    def delete_professor(self, professor_id):
        self.university_contract.functions.deleteProfessor(professor_id).transact()
