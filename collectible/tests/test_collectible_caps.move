// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_caps {

    use sui::test_scenario;
    use collectible::caps::{
        delete_dummy_admin_cap,
        dummy_admin_cap,
    };
    use collectible::register::{
        ENotAuthorized,
        ENotFound,
        delete_dummy_register,
        dummy_register,
    };
    use collectible::test_common::{
        admin_has_admin_cap_access,
        admin_has_full_register_access,
        admin_publish_contract,
        admin_register_new_minter,
        owner_cannot_get_admin_cap,
        owner_has_limited_register_access,
    };


    #[test]
    fun test_publisher_of_register_can_mint_and_freeze() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xCCCC;
        // Admin publishes the caps
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        // Verify that only the admin has admin cap access
        admin_has_admin_cap_access(&mut scenario, admin_addr);
        owner_cannot_get_admin_cap(&mut scenario, minter_addr);
        owner_cannot_get_admin_cap(&mut scenario, user1);
        // Verify that admin can access the register and has full rights
        admin_has_full_register_access(&mut scenario, admin_addr);
        owner_has_limited_register_access(&mut scenario, minter_addr);
        owner_has_limited_register_access(&mut scenario, user1);
        // Register a new minter
        admin_register_new_minter(&mut scenario, admin_addr, minter_addr);
        // Verify that the minter now has admin access rights
        admin_has_full_register_access(&mut scenario, minter_addr);
        // Confirm that the minter still does not have admin cap access
        owner_cannot_get_admin_cap(&mut scenario, minter_addr);
        scenario.end();
    }

    #[test]
    fun test_whitelist_and_revoke_minter() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        let mut admin = dummy_admin_cap(&mut ctx);
        // Check that we are good to mint
        register.check_minter(&mut ctx);
        register.remove_minter_whitelist(tx_context::sender(&ctx), &mut admin, &mut ctx);
        assert!(register.whitelist(&mut admin, &mut ctx).length() == 0);
        assert!(!register.is_minter_valid_for_testing(&mut ctx));
        // Revoke the blacklist, and verify that things are back to normal
        register.add_minter_whitelist(tx_context::sender(&ctx), &mut admin, &mut ctx);
        assert!(register.whitelist(&mut admin, &mut ctx).length() == 1);
        register.check_minter(&mut ctx);
        // Clean-up
        delete_dummy_admin_cap(admin);
        delete_dummy_register(register);
    }

    #[test]
    #[expected_failure(abort_code = ENotFound)]
    fun test_address_not_found() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        let mut admin = dummy_admin_cap(&mut ctx);
        let unknown_addr = @0xDEAD;
        register.check_minter(&mut ctx);
        // Attempt to remove an unknown address
        register.remove_minter_whitelist(copy unknown_addr, &mut admin, &mut ctx);
        // Clean-up
        delete_dummy_admin_cap(admin);
        delete_dummy_register(register);
    }

    #[test]
    #[expected_failure(abort_code = ENotAuthorized)]
    fun test_unauthorized_minter() {
        let mut ctx = tx_context::dummy();
        let mut register = dummy_register(&mut ctx);
        let mut admin = dummy_admin_cap(&mut ctx);
        register.check_minter(&mut ctx);
        // add compromised minter to the blacklist
        register.remove_minter_whitelist(tx_context::sender(&ctx), &mut admin, &mut ctx);
        register.check_minter(&mut ctx);
        // Clean-up
        delete_dummy_admin_cap(admin);
        delete_dummy_register(register);
    }

}
