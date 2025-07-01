use starkacademycontract::interfaces::Itournament::{ItournamentDispatcher, ItournamentDispatcherTrait};
use starknet::ContractAddress;
use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};

#[test]
fn test_set_reward_pool_admin() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };
    let tournament_id = create_test_tournament(contract_instance, owner);

    // Set new prize pool as admin
    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.set_reward_pool(tournament_id, 5555);
    stop_cheat_caller_address(contract_instance.contract_address);

    let tournament = contract_instance.get_tournament(tournament_id);
    assert(tournament.prize_pool == 5555, 'Prize pool should be updated');
}

#[test]
#[should_panic(expected: 'Caller not Admin')]
fn test_set_reward_pool_non_admin() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };
    let tournament_id = create_test_tournament(contract_instance, owner);

    // Try to set prize pool as non-admin
    start_cheat_caller_address(contract_instance.contract_address, random_user());
    contract_instance.set_reward_pool(tournament_id, 7777);
    stop_cheat_caller_address(contract_instance.contract_address);
}

#[test]
#[should_panic(expected: 'Prize pool must be greater than zero')]
fn test_set_reward_pool_zero() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };
    let tournament_id = create_test_tournament(contract_instance, owner);

    // Try to set prize pool to zero
    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.set_reward_pool(tournament_id, 0);
    stop_cheat_caller_address(contract_instance.contract_address);
}
