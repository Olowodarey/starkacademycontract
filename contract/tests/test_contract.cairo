use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starkacademycontract::interfaces::Itournament::{
    ItournamentDispatcher, ItournamentDispatcherTrait,
};
// use starkacademycontract::structs::structs::Tournament;
use starknet::ContractAddress;

// helpers
fn owner() -> ContractAddress {
    // Create owner address using TryInto
    let owner_felt: felt252 = 0001.into();
    let owner: ContractAddress = owner_felt.try_into().unwrap();
    owner
}

fn random_user() -> ContractAddress {
    // Create random user address using TryInto
    let random_user_felt: felt252 = 023433.into();
    let random_user: ContractAddress = random_user_felt.try_into().unwrap();
    random_user
}

fn create_test_tournament(contract_instance: ItournamentDispatcher, owner: ContractAddress) -> u64 {
    let title: ByteArray = "Test Tournament";
    let description: ByteArray = "Test Description";
    let start_date: felt252 = 1672531200;
    let end_date: felt252 = 1672617600;
    let entry_fee: u256 = 10;
    let prize_pool: u256 = 1000;
    let image_url: ByteArray = "https://example.com/test.jpg";

    start_cheat_caller_address(contract_instance.contract_address, owner);

    let tournament_id = contract_instance
        .create_tournament(
            title, description, start_date, end_date, entry_fee, prize_pool, image_url,
        );

    stop_cheat_caller_address(contract_instance.contract_address);
    tournament_id
}

// end of helpers

/// ******** SET-UP ********
fn setup() -> (ContractAddress, ContractAddress) {
    // Deploy mock token first for payment
    let tournament_class = declare("Tournament").unwrap().contract_class();
    let (contract_address, _) = tournament_class.deploy(@array![owner().into()]).unwrap();
    (contract_address, owner())
}

// ******** TESTS SUITE ********
// test create tournament
#[test]
fn test_create_tournament() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address: contract_address };

    // tournament data
    let title: ByteArray = "Tournament 1";
    let description: ByteArray = "Description 1";
    let start_date: felt252 = 1672531200;
    let end_date: felt252 = 1672531200;
    let entry_fee: u256 = 1;
    let prize_pool: u256 = 100;
    let image_url: ByteArray = "https://example.com/image.jpg";

    // create tournament as owner
    start_cheat_caller_address(contract_instance.contract_address, owner);

    // Verify initial state
    assert(contract_instance.get_tournament_id() == 0, 'Initial ID should be 0');

    contract_instance
        .create_tournament(
            title, description, start_date, end_date, entry_fee, prize_pool, image_url,
        );

    // Verify state after tournament creation
    assert(contract_instance.get_tournament_id() == 1, 'ID should be 1 after create');

    stop_cheat_caller_address(contract_instance.contract_address);
}

// test add multiple tournaments
#[test]
fn test_add_multiple_tournaments() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address: contract_address };

    // tournament data1
    let title1: ByteArray = "Tournament 1";
    let description1: ByteArray = "Description 1";
    let start_date1: felt252 = 1672531200;
    let end_date1: felt252 = 1672531200;
    let entry_fee1: u256 = 1;
    let prize_pool1: u256 = 100;
    let image_url1: ByteArray = "https://example.com/image.jpg";

    // tournament data2
    let title2: ByteArray = "Tournament 2";
    let description2: ByteArray = "Description 2";
    let start_date2: felt252 = 1672531200;
    let end_date2: felt252 = 1672531200;
    let entry_fee2: u256 = 2;
    let prize_pool2: u256 = 200;
    let image_url2: ByteArray = "https://example.com/image2.jpg";

    // create tournament as owner
    start_cheat_caller_address(contract_instance.contract_address, owner);

    // Verify initial state
    assert(contract_instance.get_tournament_id() == 0, 'Initial ID should be 0');

    contract_instance
        .create_tournament(
            title1, description1, start_date1, end_date1, entry_fee1, prize_pool1, image_url1,
        );

    // Verify state after tournament creation
    assert(contract_instance.get_tournament_id() == 1, 'ID should be 1 after create');

    contract_instance
        .create_tournament(
            title2, description2, start_date2, end_date2, entry_fee2, prize_pool2, image_url2,
        );

    // Verify state after tournament creation
    assert(contract_instance.get_tournament_id() == 2, 'ID should be 2 after create');

    stop_cheat_caller_address(contract_instance.contract_address);
}

// test create and non owner
#[test]
#[should_panic(expected: 'Caller not Admin')]
fn test_create_tournament_non_owner() {
    let (contract_address, _) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // tournament data
    let title: ByteArray = "Tournament 1";
    let description: ByteArray = "Description 1";
    let start_date: felt252 = 1672531200;
    let end_date: felt252 = 1672531200;
    let entry_fee: u256 = 1;
    let prize_pool: u256 = 100;
    let image_url: ByteArray = "https://example.com/image.jpg";

    // create tournament as non owner
    start_cheat_caller_address(contract_instance.contract_address, random_user());

    // Verify initial state
    assert(contract_instance.get_tournament_id() == 0, 'Initial ID should be 0');

    contract_instance
        .create_tournament(
            title, description, start_date, end_date, entry_fee, prize_pool, image_url,
        );

    // expected panic here
    assert(contract_instance.get_tournament_id() == 1, 'ID should be 1 after create');

    stop_cheat_caller_address(contract_instance.contract_address);
}

// -- test activate tournament
#[test]
fn test_activate_tournament_success() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // create tournament
    let tournament_id = create_test_tournament(contract_instance, owner);

    // tournament should be initially inactive
    assert(!contract_instance.is_tournament_active(tournament_id), 'Tournament should be inactive');

    // activate tournament as admin
    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.activate_tournament(tournament_id);
    stop_cheat_caller_address(contract_instance.contract_address);

    // verify tournament is now active
    assert(contract_instance.is_tournament_active(tournament_id), 'Tournament should be active');

    // verify tournament data is preserved
    let tournament = contract_instance.get_tournament(tournament_id);
    assert(tournament.id == tournament_id, 'Tournament ID should match');
    assert(tournament.is_active, 'Tournament should be active');
}
#[test]
#[should_panic(expected: 'Caller not Admin')]
fn test_activate_tournament_non_admin() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // create tournament
    let tournament_id = create_test_tournament(contract_instance, owner);

    // try to activate tournament as non-admin (should fail)
    start_cheat_caller_address(contract_instance.contract_address, random_user());
    contract_instance.activate_tournament(tournament_id);
    stop_cheat_caller_address(contract_instance.contract_address);
}

#[test]
#[should_panic(expected: 'Tournament does not exist')]
fn test_activate_nonexistent_tournament() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // try to activate a tournament that doesn't exist
    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.activate_tournament(999); // Non-existent tournament ID
    stop_cheat_caller_address(contract_instance.contract_address);
}

#[test]
#[should_panic(expected: 'Tournament already active')]
fn test_activate_already_active_tournament() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // create and activate a tournament
    let tournament_id = create_test_tournament(contract_instance, owner);

    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.activate_tournament(tournament_id);

    // try to activate again (should fail)
    contract_instance.activate_tournament(tournament_id);
    stop_cheat_caller_address(contract_instance.contract_address);
}

#[test]
fn test_multiple_tournaments_activation() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // create multiple tournaments
    let tournament_id_1 = create_test_tournament(contract_instance, owner);
    let tournament_id_2 = create_test_tournament(contract_instance, owner);

    // verify both are initially inactive
    assert(!contract_instance.is_tournament_active(tournament_id_1), 'should be
    inactive');
    assert(!contract_instance.is_tournament_active(tournament_id_2), 'should be
    inactive');

    // activate only the first tournament
    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.activate_tournament(tournament_id_1);
    stop_cheat_caller_address(contract_instance.contract_address);

    // verify states
    assert(contract_instance.is_tournament_active(tournament_id_1), 'should be
    active');
    assert(!contract_instance.is_tournament_active(tournament_id_2), 'should remain
    inactive');

    // activate the second tournament
    start_cheat_caller_address(contract_instance.contract_address, owner);
    contract_instance.activate_tournament(tournament_id_2);
    stop_cheat_caller_address(contract_instance.contract_address);

    // verify both are now active
    assert(contract_instance.is_tournament_active(tournament_id_1), 'should be
    active');
    assert(contract_instance.is_tournament_active(tournament_id_2), 'should be
    active');
}

#[test]
fn test_tournament_creation_default_inactive() {
    let (contract_address, owner) = setup();
    let contract_instance = ItournamentDispatcher { contract_address };

    // create a tournament
    let tournament_id = create_test_tournament(contract_instance, owner);

    // verify tournament is created as inactive by default
    let tournament = contract_instance.get_tournament(tournament_id);
    assert(!tournament.is_active, 'New tour. should be inactive');
    assert(!contract_instance.is_tournament_active(tournament_id), 'is_tournament_active == false');
}

