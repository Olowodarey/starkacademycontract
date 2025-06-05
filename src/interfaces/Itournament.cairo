use starkacademycontract::structs::structs::Tournament;

#[starknet::interface]
pub trait Itournament<TContractState> {
    /// create a tournament
    fn create_tournament(
        ref self: TContractState,
        title: ByteArray,
        description: ByteArray,
        start_date: felt252,
        end_date: felt252,
        entry_fee: u256,
        prize_pool: u256,
        image_url: ByteArray,
    ) -> u64;

    fn activate_tournament(ref self: TContractState, tournament_id: u64);
    fn is_tournament_active(self: @TContractState, tournament_id: u64) -> bool;

    /// get tournament by id
    fn get_tournament(self: @TContractState, id: u64) -> Tournament;

    /// get all tournaments
    fn get_tournaments(self: @TContractState) -> Array<Tournament>;

    fn get_tournament_id(self: @TContractState) -> u64;
}
