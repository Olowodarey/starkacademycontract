use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starkacademy::interfaces::Itournament::{
    ItournamentDispatcher, ItournamentDispatcherTrait, ItournamentSafeDispatcher,
    ItournamentSafeDispatcherTrait,
};
use starknet::ContractAddress;

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();

    // Create constructor calldata with default_admin parameter
    let mut calldata = ArrayTrait::new();
    // Use a dummy address as the default admin
    calldata.append(0x0000000000000000000000000000000000000000000000000000000000000001);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_increase_balance() {
    let contract_address = deploy_contract("Tournament");

    let dispatcher = ItournamentDispatcher { contract_address };

    let balance_before = dispatcher.get_balance();
    assert(balance_before == 0, 'Invalid balance');

    dispatcher.increase_balance(42);

    let balance_after = dispatcher.get_balance();
    assert(balance_after == 42, 'Invalid balance');
}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_increase_balance_with_zero_value() {
    let contract_address = deploy_contract("Tournament");

    let safe_dispatcher = ItournamentSafeDispatcher { contract_address };

    let balance_before = safe_dispatcher.get_balance().unwrap();
    assert(balance_before == 0, 'Invalid balance');

    match safe_dispatcher.increase_balance(0) {
        Result::Ok(_) => core::panic_with_felt252('Should have panicked'),
        Result::Err(panic_data) => {
            assert(*panic_data.at(0) == 'Amount cannot be 0', *panic_data.at(0));
        },
    };
}
