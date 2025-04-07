from utils.contract_deployer import deploy_contract
from utils.contract_type import ContractType
from utils.project_components import get_config

contracts = get_config().get("contracts")

if contracts:
    for contract_name, contract_address in contracts.items():
        if contract_address == "":
            if contract_name == ContractType.STUDENT.value:
                deploy_contract(ContractType.STUDENT)
            elif contract_name == ContractType.PROFESSOR.value:
                deploy_contract(ContractType.PROFESSOR)
            elif contract_name == ContractType.UNIVERSITY.value:
                deploy_contract(
                    contract_type = ContractType.UNIVERSITY,
                    constructor_args = (
                        get_config()["contracts"][ContractType.STUDENT.value],
                        get_config()["contracts"][ContractType.PROFESSOR.value],
                    )
                )
else:
    raise ValueError(f"No contracts found in config.")