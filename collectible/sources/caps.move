// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

module collectible::caps {

    // Admin capabilities
    public struct AdminCap has key, store { id: UID }
    // Minter capabilities
    public struct MinterCap has key, store { id: UID }

    #[test_only]
    /// Create a dummy `AdminCap` for testing
    public fun dummy_admin_cap(ctx: &mut TxContext): AdminCap {
        AdminCap {
            id: object::new(ctx),
        }
    }

    #[test_only]
    /// Create a dummy `MinterCap` for testing
    public fun dummy_minter_cap(ctx: &mut TxContext): MinterCap {
        MinterCap {
            id: object::new(ctx),
        }  
    }

    #[test_only]
    /// Allow delete of dummy admin cap
    public fun delete_dummy_admin_cap(admin: AdminCap) {
        let AdminCap { id: admin_cap_uid, .. } = admin;
        object::delete(admin_cap_uid);
    }

    #[test_only]
    /// Allow delete of dummy minter cap
    public fun delete_dummy_minter_cap(minter: MinterCap) {
        let MinterCap { id: minter_cap_uid, .. } = minter;
        object::delete(minter_cap_uid);
    }

    public fun burn_minter(minter: MinterCap) {
        // only the minter can be deleted, prevents creation of new tokens only
        let MinterCap { id: minter_cap_uid, .. } = minter;
        object::delete(minter_cap_uid);        
    }


    // === Module init ===

    fun init(ctx: &mut TxContext) {
        // Give the contract deployer admin and minter capabilities
        // Admin will be moved out after deployment
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::transfer(MinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }

}
