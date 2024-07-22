// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

module collectible::caps {

    // Admin capabilities
    public struct AdminCap has key, store { id: UID }


    #[test_only]
    /// Create a dummy `AdminCap` for testing
    public fun dummy_admin_cap(ctx: &mut TxContext): AdminCap {
        AdminCap {
            id: object::new(ctx),
        }
    }

    #[test_only]
    /// Allow delete of dummy admin cap
    public fun delete_dummy_admin_cap(admin: AdminCap) {
        let AdminCap { id: admin_cap_uid, .. } = admin;
        object::delete(admin_cap_uid);
    }

    // === Module init ===

    fun init(ctx: &mut TxContext) {
        // Give the contract deployer admin capabilities
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }

}
