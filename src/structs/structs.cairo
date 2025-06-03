#[derive(Clone, Debug, Drop, PartialEq, Serde, starknet::Store)]
pub struct Tournament {
    pub id: u64,
    pub title: ByteArray,
    pub description: ByteArray,
    pub start_date: felt252,
    pub end_date: felt252,
    pub entry_fee: u256,
    pub prize_pool: u256,
    pub image_url: ByteArray,
}

