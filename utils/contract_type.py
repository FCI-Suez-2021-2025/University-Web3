from enum import Enum


class ContractType(Enum):
    PROFESSOR = "Professor"
    STUDENT = "Student"
    COURSE = "Course"
    UNIVERSITY = "University"
    ENROLLMENT = "Enrollment"

    @property
    def abi_filename(self):
        return f"{self.value}.abi"

    @property
    def bin_filename(self):
        return f"{self.value}.bin"