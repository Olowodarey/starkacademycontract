// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^1.0.0

const PAUSER_ROLE: felt252 = selector!("PAUSER_ROLE");
const UPGRADER_ROLE: felt252 = selector!("UPGRADER_ROLE");

#[starknet::contract]
pub mod Tournament {
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
    use starkacademycontract::interfaces::Itournament::Itournament;
    use starkacademycontract::structs::structs::Tournament;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ClassHash, ContractAddress, get_caller_address};
    use super::{PAUSER_ROLE, UPGRADER_ROLE};

    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // External
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;

    // Internal
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        // Internal storage
        owner: ContractAddress,
        next_id: u64,
        tournaments: Map<u64, Tournament>,
        contract_balance: u256,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, default_admin: ContractAddress) {
        self.accesscontrol.initializer();

        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(PAUSER_ROLE, default_admin);
        self.accesscontrol._grant_role(UPGRADER_ROLE, default_admin);

        self.owner.write(default_admin);
        self.next_id.write(0);
        self.contract_balance.write(0);
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(PAUSER_ROLE);
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(PAUSER_ROLE);
            self.pausable.unpause();
        }
    }

    //
    // Upgradeable
    //

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.accesscontrol.assert_only_role(UPGRADER_ROLE);
            self.upgradeable.upgrade(new_class_hash);
        }
    }


    #[abi(embed_v0)]
    impl TournamentImpl of Itournament<ContractState> {
        // Create a tournament
        fn create_tournament(
            ref self: ContractState,
            title: ByteArray,
            description: ByteArray,
            start_date: felt252,
            end_date: felt252,
            entry_fee: u256,
            prize_pool: u256,
            image_url: ByteArray,
        ) -> u64 {
            // Check if contract is paused
            self.pausable.assert_not_paused();

            // Check if caller has ADMIN_ROLE or DEFAULT_ADMIN_ROLE
            let caller = get_caller_address();
            let has_admin_role = self.accesscontrol.has_role(DEFAULT_ADMIN_ROLE, caller);

            assert(has_admin_role, 'Caller not Admin');

            let id = self.next_id.read();
            let new_id = id + 1;

            let tournament = Tournament {
                id: new_id,
                title,
                description,
                start_date,
                end_date,
                entry_fee,
                prize_pool,
                image_url,
            };

            self.next_id.write(new_id);

            self.tournaments.write(new_id, tournament);

            return new_id;
        }

        // Get tournament by id
        fn get_tournament(self: @ContractState, id: u64) -> Tournament {
            self.tournaments.read(id)
        }

        // Get all tournaments
        fn get_tournaments(self: @ContractState) -> Array<Tournament> {
            let count = self.next_id.read();
            let mut tournaments: Array<Tournament> = ArrayTrait::new();

            let mut i = 1;
            while i != count + 1 {
                let tournament = self.tournaments.read(i);
                if tournament.id != 0 {
                    tournaments.append(tournament);
                }
                i = i + 1;
            }
            return tournaments;
        }

        // Get next tournament id
        fn get_tournament_id(self: @ContractState) -> u64 {
            self.next_id.read()
        }
    }
}
