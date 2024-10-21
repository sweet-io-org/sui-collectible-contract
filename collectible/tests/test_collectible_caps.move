// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_caps {

    use sui::test_scenario;
    use collectible::caps::{
        delete_dummy_admin_cap,
        dummy_admin_cap,
        delete_dummy_minter_cap,
        dummy_minter_cap,
        MinterCap,
        burn_minter,
    };
    use collectible::test_common::{
        admin_publish_contract,
        admin_has_admin_cap_access,
        admin_has_minter_cap_access,
        owner_cannot_get_caps,
    };


    #[test]
    fun test_caps() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xCCCC;
        // Admin publishes the caps
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        // Verify that only the admin has admin cap access
        admin_has_admin_cap_access(&mut scenario, admin_addr);
        admin_has_minter_cap_access(&mut scenario, admin_addr);
        owner_cannot_get_caps(&mut scenario, minter_addr);
        scenario.end();
    }

    #[test]
    fun test_burn_cap() {
        let admin_addr = @0xAAAA;
        // Admin publishes the caps
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        scenario.next_tx(admin_addr);
        {
            let mut minterCap = scenario.take_from_sender<MinterCap>();
            burn_minter(minterCap);
        };
        scenario.end();
    }

}
