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

