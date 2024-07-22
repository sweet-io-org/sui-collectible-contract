// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_register {

    use sui::test_scenario;
    use collectible::register::{
        delete_dummy_register,
        dummy_register,
        EDuplicateMinter,
        EDuplicateUri,
        EFrozen,
        ENotAuthorized,
        Register,
    };
    use collectible::test_common::{
        admin_can_mint,
        admin_freeze_contract,
        admin_publish_contract,
        admin_register_new_minter,
        admin_revoke_minter_access,
    };

    // Minter whitelist tests

    #[test]
    fun test_minter_whitelist() {
        let admin_addr = @0xCCCC;
        let minter_addr = @0xDDDD;
        let unregistered_minter_addr = @0xEEEE;
        let user1 = @0xFFFF;
        // Admin publishes the contract
        let mut scenario = test_scenario::begin(@0x0);
        // Contract publisher can mint
        admin_publish_contract(&mut scenario, admin_addr);
        assert!(admin_can_mint(&mut scenario, admin_addr));
        // A newly registered minter can mint
        assert!(!admin_can_mint(&mut scenario, minter_addr));
        admin_register_new_minter(&mut scenario, admin_addr, minter_addr);
        assert!(admin_can_mint(&mut scenario, minter_addr));
        // Unregistered minters cannot mint
        assert!(!admin_can_mint(&mut scenario, unregistered_minter_addr));
        assert!(!admin_can_mint(&mut scenario, user1));
        // Clean up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EDuplicateMinter)]
    fun test_duplicate_minter_aborts() {
        let admin_addr = @0xCCCC;
        // Admin publishes the contract
        let mut scenario = test_scenario::begin(@0x0);
        // Contract publisher can mint
        admin_publish_contract(&mut scenario, admin_addr);
        assert!(admin_can_mint(&mut scenario, admin_addr));
        // Attempt to re-register outselves as a minter
        admin_register_new_minter(&mut scenario, admin_addr, admin_addr);
        // Clean up
        scenario.end();
    }

    // Contract freeze tests

    #[test]
    fun test_contract_can_be_frozen() {
        let admin_addr = @0xAAAA;
        // Freeze the contract and check it's frozen
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_freeze_contract(&mut scenario, admin_addr);
        // Clean-up
        scenario.end();
    }

    #[test]
    fun test_check_frozen_is_safe_to_call() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        // Verify that check_frozen is safe to call
        assert!(!register.is_contract_frozen());
        register.check_frozen(&mut ctx);
        register.check_frozen(&mut ctx);
        register.check_frozen(&mut ctx);
        assert!(!register.is_contract_frozen());
        // Clean-up
        delete_dummy_register(register);
    }

    #[test]
    #[expected_failure(abort_code = EFrozen)]
    fun test_check_frozen_will_abort_when_frozen() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        assert!(!register.is_contract_frozen());
        register.set_frozen_state_for_testing(true);
        assert!(register.is_contract_frozen());
        // Check cannot freeze if already frozen
        register.freeze_contract(&mut ctx); // should fail
        // Clean-up
        delete_dummy_register(register);
    }

    #[test]
    fun test_frozen_contract_can_still_modify_whitelist() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        // Freeze the contract and check it's frozen
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_freeze_contract(&mut scenario, admin_addr);
        // Add and revoke a new minter
        admin_register_new_minter(&mut scenario, admin_addr, minter_addr);
        admin_revoke_minter_access(&mut scenario, admin_addr, minter_addr);
        // Clean-up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EFrozen)]
    fun test_frozen_contract_cannot_register_token_uri() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        assert!(!register.is_contract_frozen());
        register.set_frozen_state_for_testing(true);
        assert!(register.is_contract_frozen());
        // Check cannot register new token URI when frozen
        register.register_token_uri(b"New token URI", &mut ctx);
        // Clean-up
        delete_dummy_register(register);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_only_minter_can_freeze_contract() {
        let admin_addr = @0xAAAA;
        let unauthorized_minter_addr = @0xBBBB;
        // Freeze the contract and check it's frozen
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_freeze_contract(&mut scenario, unauthorized_minter_addr); // Should fail
        // Clean-up
        scenario.end();
    }


    // Token URI registration tests

    #[test]
    fun test_register_token_uris() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        assert!(register.get_mut_token_uris().length() == 0);
        let token_uris = vector[
            b"https://nfts.collectible.io/series/aAa/1",
            b"https://nfts.collectible.io/series/aAa/2",
            b"https://nfts.collectible.io/series/aAa/3",
            b"https://nfts.collectible.io/series/bBb/1",
            b"https://nfts.collectible.io/series/bBb/2",
            b"https://nfts.collectible.io/series/bBb/3",
        ];
        // Register multiple token URIs
        let mut i = token_uris.length();
        while (i > 0) {
            register.register_token_uri(token_uris[i - 1], &mut ctx);
            i = i - 1;
        };
        assert!(register.get_mut_token_uris().length() == token_uris.length());
        // Check that all of our registered URLs are present in the data structure
        i = token_uris.length();
        let registered_token_uris = register.get_mut_token_uris();
        while (i > 0) {
            assert!(registered_token_uris.contains(&sui::url::new_unsafe_from_bytes(token_uris[i - 1])));
            i = i - 1;
        };
        // Clean-up
        delete_dummy_register(register);
    }

    #[test]
    #[expected_failure(abort_code = EDuplicateUri)]
    fun test_duplicate_token_uris_detected() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        assert!(register.get_mut_token_uris().length() == 0);
        let token_uris = vector[
            b"https://nfts.collectible.io/series/aAa/1",
            b"https://nfts.collectible.io/series/aAa/2",
            b"https://nfts.collectible.io/series/aAa/1", // Duplicate!!
        ];
        // Register multiple token URIs
        let mut i = token_uris.length();
        while (i > 0) {
            register.register_token_uri(token_uris[i - 1], &mut ctx);
            i = i - 1;
        };
        // Clean-up
        delete_dummy_register(register);
    }

    #[test]
    fun test_token_uri_with_multiple_minters() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        // Publish the contract
        let mut scenario = test_scenario::begin(admin_addr);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_register_new_minter(&mut scenario, admin_addr, minter_addr);
        scenario.next_tx(minter_addr);
        {
            let mut register = scenario.take_shared<Register>();
            assert!(register.get_mut_token_uris().length() == 0);
            register.register_token_uri(b"Minter 2", scenario.ctx());
            test_scenario::return_shared(register);
        };
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<Register>();
            assert!(register.get_mut_token_uris().length() == 1);
            register.register_token_uri(b"Minter 1", scenario.ctx());
            test_scenario::return_shared(register);
        };
        // Clean-up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_token_uri_block_non_minters() {
        let admin_addr = @0xAAAA;
        let unregistered_minter_addr = @0xBBBB;
        // Publish the contract
        let mut scenario = test_scenario::begin(admin_addr);
        admin_publish_contract(&mut scenario, admin_addr);
        scenario.next_tx(unregistered_minter_addr);
        {
            let mut register = scenario.take_shared<Register>();
            assert!(register.get_mut_token_uris().length() == 0);
            register.register_token_uri(b"Bad caller", scenario.ctx());
            test_scenario::return_shared(register);
        };
        // Clean-up
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EDuplicateUri)]
    fun test_register_blocks_duplicates() {
        let admin_addr = @0xAAAA;
        // Publish the contract
        let mut scenario = test_scenario::begin(admin_addr);
        admin_publish_contract(&mut scenario, admin_addr);
        let duplicate_token_uri = b"https://nfts.collectible.io/series/aAa/1";
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<Register>();
            assert!(register.get_mut_token_uris().length() == 0);
            register.register_token_uri(duplicate_token_uri, scenario.ctx());
            test_scenario::return_shared(register);
        };
        scenario.next_tx(admin_addr);
        {
            let mut register = scenario.take_shared<Register>();
            assert!(register.get_mut_token_uris().length() == 1);
            register.register_token_uri(duplicate_token_uri, scenario.ctx());
            test_scenario::return_shared(register);
        };
        // Clean-up
        scenario.end();
    }

}
