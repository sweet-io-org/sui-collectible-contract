// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

module collectible::register {

    use sui::url;
    use collectible::caps::AdminCap;

    // Error constants offset 0x100
    const ENotAuthorized: u64    = 0x101;
    const ENotFound: u64         = 0x102;
    const EFrozen: u64           = 0x103;
    const EDuplicateUri: u64     = 0x104;
    const EDuplicateMinter: u64  = 0x105;

    // Cap register
    public struct Register has key {
        id: UID,
        minter_whitelist: vector<address>, // List of valid minters
        token_uris: vector<url::Url>, // List of token URIs
        is_frozen: bool, // True whe the contract is frozen
    }

    #[test_only]
    /// Create a dummy register for testing and whitelist the sender
    public fun dummy_register(ctx: &mut TxContext): Register {
        Register {
            id: object::new(ctx),
            minter_whitelist: vector[tx_context::sender(ctx)],
            token_uris: vector::empty(),
            is_frozen: false,
        }
    }

    #[test_only]
    /// Allow delete of dummy admin cap
    public fun delete_dummy_register(register: Register) {
        let Register { id: register_uid, .. } = register;
        object::delete(register_uid);
    }

    // === Module init ===

    fun init(ctx: &mut TxContext) {
        // Create a shared register to manage capabilities
        transfer::share_object(Register {
            id: object::new(ctx),
            minter_whitelist: vector[tx_context::sender(ctx)],
            token_uris: vector::empty(),
            is_frozen: false,
        });
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }

    // === freeze functions ===

    // Allow contract to be frozen by minter
    public fun freeze_contract(self: &mut Register, ctx: &mut TxContext)
    {
        self.check_minter(ctx);
        assert!(!self.is_frozen, EFrozen);
        self.is_frozen = true
    }

    // Assert that the moment is not frozen
    public fun check_frozen(self: &mut Register, _ctx: &mut TxContext)
    {
        assert!(!self.is_frozen, EFrozen);
    }

    public fun is_contract_frozen(self: &mut Register): bool
    {
        self.is_frozen
    }

    public fun register_token_uri(self: &mut Register, uri: vector<u8>, ctx: &mut TxContext)
    {
        self.check_minter(ctx);
        self.check_frozen(ctx);
        // Check that this is a unique URI and register it
        let token_uri = sui::url::new_unsafe_from_bytes(uri);
        assert!(!self.token_uris.contains(&token_uri), EDuplicateUri);
        self.token_uris.push_back(token_uri);
    }

    #[test_only]
    public fun get_mut_token_uris(self: &mut Register): &mut vector<url::Url>
    {
        &mut self.token_uris
    }

    #[test_only]
    public fun contains_token_uri(self: &mut Register, uri: vector<u8>): bool
    {
        let token_uri = sui::url::new_unsafe_from_bytes(uri);
        self.token_uris.contains(&token_uri)
    }


    #[test_only]
    public fun set_frozen_state_for_testing(self: &mut Register, new_state: bool)
    {
        self.is_frozen = new_state;
    }

    // === blacklist functions ===

    // Will fail if minter is marked as blacklisted
    public fun check_minter(self: &mut Register, ctx: &mut TxContext) {
        assert!(self.is_minter_valid(ctx), ENotAuthorized);
    }

    // Will return false if minter is blacklisted
    fun is_minter_valid(self: &Register, ctx: &TxContext): bool {
        self.minter_whitelist.contains(&tx_context::sender(ctx))
    }

    #[test_only]
    public fun is_minter_valid_for_testing(self: &mut Register, ctx: &mut TxContext): bool {
        self.is_minter_valid(ctx)
    }

    public fun add_minter_whitelist(self: &mut Register, minter: address, _admin: &mut AdminCap, _ctx: &mut TxContext) {
        assert!(!self.minter_whitelist.contains(&minter), EDuplicateMinter);
        self.minter_whitelist.push_back(minter);
    }

    public fun remove_minter_whitelist(self: &mut Register, minter: address, _admin: &mut AdminCap, _ctx: &mut TxContext) {
        let (is_whitelisted, idx) = self.minter_whitelist.index_of(&minter);
        assert!(is_whitelisted, ENotFound);
        self.minter_whitelist.remove(idx);
    }

    // Return a list of blacklisted minter IDs
    public fun whitelist(self: &mut Register, _admin: &mut AdminCap, _ctx: &mut TxContext): vector<address> {
        self.minter_whitelist
    }

}
