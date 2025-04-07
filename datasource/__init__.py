from utils.contract_deployer import deploy_contract
from utils.contract_type import ContractType
from utils.project_components import get_config


contracts = get_config().get("contracts")

if contracts:
    # Deploy dependencies first
    for contract_type in [ContractType.PROFESSOR, ContractType.STUDENT]:
        if contracts.get(contract_type.value) == "":
            deploy_contract(contract_type)

    for contract_type in [ContractType.COURSE, ContractType.UNIVERSITY]:
        # Deploy Course contract
        if contracts.get(ContractType.COURSE.value) == "":
            deploy_contract(
                contract_type=ContractType.COURSE,
                constructor_args=(
                    contracts[ContractType.PROFESSOR.value],
                    contracts[ContractType.STUDENT.value]
                )
            )

        # Deploy University contract with all dependencies
        elif contracts.get(ContractType.UNIVERSITY.value) == "":
            deploy_contract(
                contract_type=ContractType.UNIVERSITY,
                constructor_args=(
                    contracts[ContractType.STUDENT.value],
                    contracts[ContractType.PROFESSOR.value],
                    contracts[ContractType.COURSE.value]
                )
            )
else:
    raise ValueError("No contracts found in config.")